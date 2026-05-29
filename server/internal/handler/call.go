package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/websocket"
	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// CallHandler handles call-related HTTP requests.
type CallHandler struct {
	db  *gorm.DB
	hub *websocket.Hub
}

func NewCallHandler(db *gorm.DB, hub *websocket.Hub) *CallHandler {
	return &CallHandler{db: db, hub: hub}
}

// Start handles POST /api/call/start
func (h *CallHandler) Start(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		ToID     string `json:"to_user_id" binding:"required"`
		CallType string `json:"call_type" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "missing to_user_id or call_type")
		return
	}

	if body.CallType != model.CallTypeAudio && body.CallType != model.CallTypeVideo {
		response.Error(c, http.StatusBadRequest, "call_type must be 'audio' or 'video'")
		return
	}

	// Look up caller's nickname
	var caller model.User
	callerNickname := ""
	if err := h.db.First(&caller, "id = ?", userID.(string)).Error; err == nil {
		callerNickname = caller.Nickname
	}

	call := &model.Call{
		CallerID:  userID.(string),
		CalleeID:  body.ToID,
		CallType:  body.CallType,
		Status:    model.CallStatusRinging,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	if err := h.db.Create(call).Error; err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to create call")
		return
	}

	// Notify callee via WebSocket (include caller name for incoming call UI)
	payload, _ := json.Marshal(map[string]string{
		"call_type":    body.CallType,
		"caller_name":  callerNickname,
	})
	h.hub.SendToUser(body.ToID, &websocket.WsMessage{
		Type:    "call-start",
		FromID:  userID.(string),
		ToID:    body.ToID,
		Content: string(payload),
		MsgID:   call.ID,
	})

	response.Success(c, gin.H{
		"call_id":   call.ID,
		"status":    call.Status,
		"call_type": call.CallType,
	})
}

// Accept handles POST /api/call/accept
func (h *CallHandler) Accept(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		CallID string `json:"call_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "missing call_id")
		return
	}

	var call model.Call
	if err := h.db.First(&call, "id = ?", body.CallID).Error; err != nil {
		response.Error(c, http.StatusNotFound, "call not found")
		return
	}
	if call.CalleeID != userID.(string) {
		response.Error(c, http.StatusForbidden, "not your call")
		return
	}
	if call.Status != model.CallStatusRinging {
		response.Error(c, http.StatusBadRequest, "call already processed")
		return
	}

	h.db.Model(&call).Updates(map[string]interface{}{
		"status":     model.CallStatusAccepted,
		"updated_at": time.Now(),
	})

	// Notify caller
	h.hub.SendToUser(call.CallerID, &websocket.WsMessage{
		Type:   "call-accept",
		FromID: userID.(string),
		ToID:   call.CallerID,
		MsgID:  call.ID,
	})

	response.Success(c, gin.H{"call_id": call.ID, "status": model.CallStatusAccepted})
}

// Reject handles POST /api/call/reject
func (h *CallHandler) Reject(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		CallID string `json:"call_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "missing call_id")
		return
	}

	var call model.Call
	if err := h.db.First(&call, "id = ?", body.CallID).Error; err != nil {
		response.Error(c, http.StatusNotFound, "call not found")
		return
	}
	if call.CalleeID != userID.(string) {
		response.Error(c, http.StatusForbidden, "not your call")
		return
	}
	if call.Status != model.CallStatusRinging {
		response.Error(c, http.StatusBadRequest, "call already processed")
		return
	}

	h.db.Model(&call).Updates(map[string]interface{}{
		"status":     model.CallStatusRejected,
		"updated_at": time.Now(),
	})

	// Notify caller
	h.hub.SendToUser(call.CallerID, &websocket.WsMessage{
		Type:   "call-reject",
		FromID: userID.(string),
		ToID:   call.CallerID,
		MsgID:  call.ID,
	})

	response.Success(c, gin.H{"call_id": call.ID, "status": model.CallStatusRejected})
}

// End handles POST /api/call/end
func (h *CallHandler) End(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		CallID string `json:"call_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "missing call_id")
		return
	}

	var call model.Call
	if err := h.db.First(&call, "id = ?", body.CallID).Error; err != nil {
		response.Error(c, http.StatusNotFound, "call not found")
		return
	}
	if call.CallerID != userID.(string) && call.CalleeID != userID.(string) {
		response.Error(c, http.StatusForbidden, "not your call")
		return
	}

	h.db.Model(&call).Updates(map[string]interface{}{
		"status":     model.CallStatusEnded,
		"updated_at": time.Now(),
	})

	// Notify the other party
	otherID := call.CalleeID
	if userID.(string) == call.CalleeID {
		otherID = call.CallerID
	}
	h.hub.SendToUser(otherID, &websocket.WsMessage{
		Type:   "call-end",
		FromID: userID.(string),
		ToID:   otherID,
		MsgID:  call.ID,
	})

	response.Success(c, gin.H{"call_id": call.ID, "status": model.CallStatusEnded})
}

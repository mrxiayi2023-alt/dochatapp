package handler

import (
	"net/http"
	"strconv"

	"dochatapp/server/internal/service"
	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
)

// MessageHandler handles message-related HTTP requests.
type MessageHandler struct {
	svc *service.MessageService
}

func NewMessageHandler(svc *service.MessageService) *MessageHandler {
	return &MessageHandler{svc: svc}
}

// Send handles POST /api/messages/send.
func (h *MessageHandler) Send(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.SendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	msg, err := h.svc.SendMessage(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to send message")
		return
	}

	response.Success(c, msg)
}

// Conversations handles GET /api/messages/conversations.
func (h *MessageHandler) Conversations(c *gin.Context) {
	userID, _ := c.Get("userID")

	convs, err := h.svc.GetConversations(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get conversations")
		return
	}

	response.Success(c, convs)
}

// ChatHistory handles GET /api/messages/chat?with=userID&limit=50&offset=0.
func (h *MessageHandler) ChatHistory(c *gin.Context) {
	userID, _ := c.Get("userID")
	otherID := c.Query("with")
	if otherID == "" {
		response.Error(c, http.StatusBadRequest, "missing 'with' query parameter")
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	messages, err := h.svc.GetChatHistory(userID.(string), otherID, limit, offset)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get chat history")
		return
	}

	response.Success(c, messages)
}

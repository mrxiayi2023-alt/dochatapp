package handler

import (
	"net/http"

	"dochatapp/server/internal/service"
	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
)

// FriendHandler handles friend-related HTTP requests.
type FriendHandler struct {
	svc *service.FriendService
}

func NewFriendHandler(svc *service.FriendService) *FriendHandler {
	return &FriendHandler{svc: svc}
}

// SendRequest handles POST /api/friends/request.
func (h *FriendHandler) SendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		ToPhone string `json:"to_phone" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "missing to_phone")
		return
	}

	if err := h.svc.SendRequest(userID.(string), body.ToPhone); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "request sent"})
}

// GetIncomingRequests handles GET /api/friends/requests.
func (h *FriendHandler) GetIncomingRequests(c *gin.Context) {
	userID, _ := c.Get("userID")

	requests, err := h.svc.GetIncomingRequests(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get requests")
		return
	}

	response.Success(c, requests)
}

// AcceptRequest handles POST /api/friends/accept.
func (h *FriendHandler) AcceptRequest(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		RequestID string `json:"request_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "missing request_id")
		return
	}

	if err := h.svc.AcceptRequest(userID.(string), body.RequestID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "request accepted"})
}

// RejectRequest handles POST /api/friends/reject.
func (h *FriendHandler) RejectRequest(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		RequestID string `json:"request_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "missing request_id")
		return
	}

	if err := h.svc.RejectRequest(userID.(string), body.RequestID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "request rejected"})
}

// GetFriends handles GET /api/friends/list.
func (h *FriendHandler) GetFriends(c *gin.Context) {
	userID, _ := c.Get("userID")

	friends, err := h.svc.GetFriends(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get friends")
		return
	}

	response.Success(c, friends)
}

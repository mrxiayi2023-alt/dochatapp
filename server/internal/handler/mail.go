package handler

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：邮件HTTP处理器

import (
	"net/http"
	"strconv"

	"dochatapp/server/internal/service"
	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
)

// MailHandler handles mail-related HTTP requests.
type MailHandler struct {
	svc *service.MailService
}

// NewMailHandler creates a new MailHandler.
func NewMailHandler(svc *service.MailService) *MailHandler {
	return &MailHandler{svc: svc}
}

// Send handles POST /api/mail/send.
func (h *MailHandler) Send(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.SendMailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	// Get sender display name from context or request
	sender := c.GetString("sender")
	if sender == "" {
		sender = req.To
	}

	mail, err := h.svc.Send(userID.(string), sender, &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, mail)
}

// Inbox handles GET /api/mail/inbox.
func (h *MailHandler) Inbox(c *gin.Context) {
	userID, _ := c.Get("userID")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	result, err := h.svc.ListInbox(userID.(string), page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// Sent handles GET /api/mail/sent.
func (h *MailHandler) Sent(c *gin.Context) {
	userID, _ := c.Get("userID")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	result, err := h.svc.ListSent(userID.(string), page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// Drafts handles GET /api/mail/drafts.
func (h *MailHandler) Drafts(c *gin.Context) {
	userID, _ := c.Get("userID")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	result, err := h.svc.ListDrafts(userID.(string), page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// Detail handles GET /api/mail/:id.
func (h *MailHandler) Detail(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	mail, err := h.svc.Detail(userID.(string), id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, mail)
}

// MoveToTrash handles POST /api/mail/:id/trash.
func (h *MailHandler) MoveToTrash(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	if err := h.svc.MoveToTrash(userID.(string), id); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "moved to trash"})
}

// Restore handles POST /api/mail/:id/restore.
func (h *MailHandler) Restore(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	if err := h.svc.Restore(userID.(string), id); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "restored"})
}

// Delete handles DELETE /api/mail/:id.
func (h *MailHandler) Delete(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	if err := h.svc.Delete(userID.(string), id); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "deleted"})
}

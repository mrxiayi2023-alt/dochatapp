package handler

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：担保交易HTTP处理器

import (
	"net/http"
	"strconv"

	"dochatapp/server/internal/service"
	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
)

// EscrowHandler handles escrow-related HTTP requests.
type EscrowHandler struct {
	svc *service.EscrowService
}

// NewEscrowHandler creates a new EscrowHandler.
func NewEscrowHandler(svc *service.EscrowService) *EscrowHandler {
	return &EscrowHandler{svc: svc}
}

// Create handles POST /api/escrow/create.
func (h *EscrowHandler) Create(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.CreateEscrowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	order, err := h.svc.Create(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, order)
}

// List handles GET /api/escrow/list.
func (h *EscrowHandler) List(c *gin.Context) {
	userID, _ := c.Get("userID")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	result, err := h.svc.List(userID.(string), page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// Detail handles GET /api/escrow/:id.
func (h *EscrowHandler) Detail(c *gin.Context) {
	id := c.Param("id")

	order, evidence, err := h.svc.Detail(id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, gin.H{
		"order":    order,
		"evidence": evidence,
	})
}

// Accept handles POST /api/escrow/:id/accept.
func (h *EscrowHandler) Accept(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	if err := h.svc.Accept(userID.(string), id); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "escrow accepted"})
}

// PayDeposit handles POST /api/escrow/:id/deposit.
func (h *EscrowHandler) PayDeposit(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	order, err := h.svc.PayDeposit(userID.(string), id)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, order)
}

// ConfirmPhase handles POST /api/escrow/:id/confirm-phase.
func (h *EscrowHandler) ConfirmPhase(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	var body struct {
		Phase int `json:"phase" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if err := h.svc.ConfirmPhase(userID.(string), id, body.Phase); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "phase confirmed"})
}

// RejectPhase handles POST /api/escrow/:id/reject-phase.
func (h *EscrowHandler) RejectPhase(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	if err := h.svc.RejectPhase(userID.(string), id); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "phase rejected, dispute opened"})
}

// SubmitDispute handles POST /api/escrow/:id/dispute.
func (h *EscrowHandler) SubmitDispute(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	var body struct {
		Note string `json:"note"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if err := h.svc.SubmitDispute(userID.(string), id, body.Note); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "dispute submitted"})
}

// AddEvidence handles POST /api/escrow/:id/evidence.
func (h *EscrowHandler) AddEvidence(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	var body struct {
		FileName string `json:"file_name" binding:"required"`
		FileURL  string `json:"file_url" binding:"required"`
		Note     string `json:"note"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	evidence, err := h.svc.AddEvidence(userID.(string), id, body.FileName, body.FileURL, body.Note)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, evidence)
}

// ResolveArbitration handles POST /api/escrow/:id/arbitrate.
func (h *EscrowHandler) ResolveArbitration(c *gin.Context) {
	id := c.Param("id")

	var body struct {
		Verdict string `json:"verdict" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if err := h.svc.ResolveArbitration(id, body.Verdict); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "arbitration resolved"})
}

// Complete handles POST /api/escrow/:id/complete.
func (h *EscrowHandler) Complete(c *gin.Context) {
	id := c.Param("id")

	if err := h.svc.Complete(id); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "escrow completed"})
}

// Cancel handles POST /api/escrow/:id/cancel.
func (h *EscrowHandler) Cancel(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	if err := h.svc.Cancel(userID.(string), id); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "escrow cancelled"})
}

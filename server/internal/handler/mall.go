package handler

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：商城HTTP处理器

import (
	"net/http"
	"strconv"

	"dochatapp/server/internal/service"
	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
)

// MallHandler handles mall-related HTTP requests.
type MallHandler struct {
	svc *service.MallService
}

// NewMallHandler creates a new MallHandler.
func NewMallHandler(svc *service.MallService) *MallHandler {
	return &MallHandler{svc: svc}
}

// ======================== Product Handlers ========================

// PublishProduct handles POST /api/mall/product/publish.
func (h *MallHandler) PublishProduct(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.PublishProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	product, err := h.svc.PublishProduct(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, product)
}

// ListProducts handles GET /api/mall/product/list.
func (h *MallHandler) ListProducts(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	category := c.Query("category")
	subCategory := c.Query("sub_category")
	keyword := c.Query("keyword")
	sellerID := c.Query("seller_id")

	result, err := h.svc.ListProducts(page, pageSize, category, subCategory, keyword, sellerID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// ProductDetail handles GET /api/mall/product/:id.
func (h *MallHandler) ProductDetail(c *gin.Context) {
	id := c.Param("id")

	product, err := h.svc.GetProductDetail(id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, product)
}

// ======================== Cart Handlers ========================

// AddToCart handles POST /api/mall/cart/add.
func (h *MallHandler) AddToCart(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		ProductID string `json:"product_id" binding:"required"`
		Quantity  int    `json:"quantity"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}
	if body.Quantity < 1 {
		body.Quantity = 1
	}

	if err := h.svc.AddToCart(userID.(string), body.ProductID, body.Quantity); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "added to cart"})
}

// UpdateCartItem handles PUT /api/mall/cart/update.
func (h *MallHandler) UpdateCartItem(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		ProductID string `json:"product_id" binding:"required"`
		Quantity  int    `json:"quantity" binding:"required,min=0"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if err := h.svc.UpdateCartItem(userID.(string), body.ProductID, body.Quantity); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "cart updated"})
}

// RemoveFromCart handles DELETE /api/mall/cart/:productId.
func (h *MallHandler) RemoveFromCart(c *gin.Context) {
	userID, _ := c.Get("userID")
	productID := c.Param("productId")

	if err := h.svc.RemoveFromCart(userID.(string), productID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "removed from cart"})
}

// GetCart handles GET /api/mall/cart.
func (h *MallHandler) GetCart(c *gin.Context) {
	userID, _ := c.Get("userID")

	items, err := h.svc.GetCart(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, items)
}

// ======================== Order Handlers ========================

// CreateOrder handles POST /api/mall/order/create.
func (h *MallHandler) CreateOrder(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	order, err := h.svc.CreateOrder(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, order)
}

// ListOrders handles GET /api/mall/order/list.
func (h *MallHandler) ListOrders(c *gin.Context) {
	userID, _ := c.Get("userID")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	role := c.DefaultQuery("role", "buyer")
	status := c.Query("status")

	result, err := h.svc.ListOrders(userID.(string), role, page, pageSize, status)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// OrderDetail handles GET /api/mall/order/:id.
func (h *MallHandler) OrderDetail(c *gin.Context) {
	id := c.Param("id")

	order, items, err := h.svc.GetOrderDetail(id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, gin.H{
		"order": order,
		"items": items,
	})
}

// ShipOrder handles POST /api/mall/order/:id/ship.
func (h *MallHandler) ShipOrder(c *gin.Context) {
	userID, _ := c.Get("userID")
	orderID := c.Param("id")

	var body struct {
		TrackingNumber string `json:"tracking_number" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if err := h.svc.ShipOrder(userID.(string), orderID, body.TrackingNumber); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "order shipped"})
}

// ReceiveOrder handles POST /api/mall/order/:id/receive.
func (h *MallHandler) ReceiveOrder(c *gin.Context) {
	userID, _ := c.Get("userID")
	orderID := c.Param("id")

	if err := h.svc.ReceiveOrder(userID.(string), orderID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "order received"})
}

// CompleteOrder handles POST /api/mall/order/:id/complete.
func (h *MallHandler) CompleteOrder(c *gin.Context) {
	orderID := c.Param("id")

	if err := h.svc.CompleteOrder(orderID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "order completed"})
}

// RequestRefund handles POST /api/mall/order/:id/refund.
func (h *MallHandler) RequestRefund(c *gin.Context) {
	userID, _ := c.Get("userID")
	orderID := c.Param("id")

	var body struct {
		Reason string `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if err := h.svc.RequestRefund(userID.(string), orderID, body.Reason); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "refund requested"})
}

// ApproveRefund handles POST /api/mall/order/:id/refund/approve.
func (h *MallHandler) ApproveRefund(c *gin.Context) {
	userID, _ := c.Get("userID")
	orderID := c.Param("id")

	if err := h.svc.ApproveRefund(userID.(string), orderID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "refund approved"})
}

// RejectRefund handles POST /api/mall/order/:id/refund/reject.
func (h *MallHandler) RejectRefund(c *gin.Context) {
	userID, _ := c.Get("userID")
	orderID := c.Param("id")

	if err := h.svc.RejectRefund(userID.(string), orderID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "refund rejected"})
}

// RequestReturn handles POST /api/mall/order/:id/return.
func (h *MallHandler) RequestReturn(c *gin.Context) {
	userID, _ := c.Get("userID")
	orderID := c.Param("id")

	var body struct {
		Reason string `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if err := h.svc.RequestReturn(userID.(string), orderID, body.Reason); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "return requested"})
}

// ApproveReturn handles POST /api/mall/order/:id/return/approve.
func (h *MallHandler) ApproveReturn(c *gin.Context) {
	userID, _ := c.Get("userID")
	orderID := c.Param("id")

	if err := h.svc.ApproveReturn(userID.(string), orderID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "return approved"})
}

// RejectReturn handles POST /api/mall/order/:id/return/reject.
func (h *MallHandler) RejectReturn(c *gin.Context) {
	userID, _ := c.Get("userID")
	orderID := c.Param("id")

	if err := h.svc.RejectReturn(userID.(string), orderID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "return rejected"})
}

// ======================== Dispute Handlers ========================

// CreateDispute handles POST /api/mall/dispute.
func (h *MallHandler) CreateDispute(c *gin.Context) {
	userID, _ := c.Get("userID")

	var body struct {
		OrderID     string `json:"order_id" binding:"required"`
		Reason      string `json:"reason" binding:"required"`
		Description string `json:"description"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	dispute, err := h.svc.CreateDispute(userID.(string), body.OrderID, body.Reason, body.Description)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, dispute)
}

// ListDisputes handles GET /api/mall/disputes.
func (h *MallHandler) ListDisputes(c *gin.Context) {
	userID, _ := c.Get("userID")

	disputes, err := h.svc.ListDisputes(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, disputes)
}

package service

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：商城业务逻辑

import (
	"encoding/json"
	"errors"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"

	"gorm.io/gorm"
)

// MallService handles mall business logic.
type MallService struct {
	productRepo *repository.ProductRepo
	cartRepo    *repository.CartRepo
	orderRepo   *repository.OrderRepo
	disputeRepo *repository.DisputeRepo
}

// NewMallService creates a new MallService.
func NewMallService(
	productRepo *repository.ProductRepo,
	cartRepo *repository.CartRepo,
	orderRepo *repository.OrderRepo,
	disputeRepo *repository.DisputeRepo,
) *MallService {
	return &MallService{
		productRepo: productRepo,
		cartRepo:    cartRepo,
		orderRepo:   orderRepo,
		disputeRepo: disputeRepo,
	}
}

// ======================== Request Types ========================

// PublishProductRequest is the payload for publishing a product.
type PublishProductRequest struct {
	Name        string   `json:"name" binding:"required"`
	Price       float64  `json:"price" binding:"required"`
	Unit        string   `json:"unit"`
	Category    string   `json:"category"`
	SubCategory string   `json:"sub_category"`
	Seller      string   `json:"seller"`
	Description string   `json:"description"`
	Images      []string `json:"images"`
	PriceType   string   `json:"price_type"`
}

// CreateOrderRequest is the payload for creating an order.
type CreateOrderRequest struct {
	Items []OrderItemInput `json:"items" binding:"required"`
}

// OrderItemInput is a single item in an order.
type OrderItemInput struct {
	ProductID string `json:"product_id" binding:"required"`
	Quantity  int    `json:"quantity" binding:"required,min=1"`
}

// ======================== Product Methods ========================

// PublishProduct creates a new product listing.
func (s *MallService) PublishProduct(sellerID string, req *PublishProductRequest) (*model.MallProduct, error) {
	imagesJSON, _ := json.Marshal(req.Images)
	priceType := req.PriceType
	if priceType == "" {
		priceType = "fixed"
	}

	product := &model.MallProduct{
		SellerID:    sellerID,
		Name:        req.Name,
		Price:       req.Price,
		Unit:        req.Unit,
		Category:    req.Category,
		SubCategory: req.SubCategory,
		Seller:      req.Seller,
		Description: req.Description,
		Images:      string(imagesJSON),
		PriceType:   priceType,
		Status:      "active",
	}
	if err := s.productRepo.CreateProduct(product); err != nil {
		return nil, errors.New("failed to create product")
	}
	return product, nil
}

// ListProducts returns paginated products with optional filters.
func (s *MallService) ListProducts(page, pageSize int, category, subCategory, keyword, sellerID string) (*model.MallProductListResponse, error) {
	items, total, err := s.productRepo.ListProducts(page, pageSize, category, subCategory, keyword, sellerID)
	if err != nil {
		return nil, errors.New("failed to query products")
	}
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	return &model.MallProductListResponse{
		Items:    items,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// GetProductDetail returns a product by ID.
func (s *MallService) GetProductDetail(id string) (*model.MallProduct, error) {
	product, err := s.productRepo.FindProductByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("product not found")
		}
		return nil, errors.New("database error")
	}
	return product, nil
}

// ======================== Cart Methods ========================

// AddToCart adds a product to the user's cart.
func (s *MallService) AddToCart(userID, productID string, quantity int) error {
	// Check if product exists
	_, err := s.productRepo.FindProductByID(productID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("product not found")
		}
		return errors.New("database error")
	}

	// Check if already in cart
	existing, _ := s.cartRepo.FindCartItem(userID, productID)
	if existing != nil {
		// Update quantity instead
		newQty := existing.Quantity + quantity
		return s.cartRepo.UpdateQuantity(userID, productID, newQty)
	}

	item := &model.MallCartItem{
		UserID:    userID,
		ProductID: productID,
		Quantity:  quantity,
	}
	return s.cartRepo.AddItem(item)
}

// UpdateCartItem updates the quantity of a cart item.
func (s *MallService) UpdateCartItem(userID, productID string, quantity int) error {
	if quantity <= 0 {
		return s.cartRepo.RemoveItem(userID, productID)
	}
	return s.cartRepo.UpdateQuantity(userID, productID, quantity)
}

// RemoveFromCart removes an item from the cart.
func (s *MallService) RemoveFromCart(userID, productID string) error {
	return s.cartRepo.RemoveItem(userID, productID)
}

// GetCart returns the user's cart with product details.
func (s *MallService) GetCart(userID string) ([]model.MallCartItem, error) {
	return s.cartRepo.GetCart(userID)
}

// ======================== Order Methods ========================

// CreateOrder creates a new order from cart items.
func (s *MallService) CreateOrder(buyerID string, req *CreateOrderRequest) (*model.MallOrder, error) {
	if len(req.Items) == 0 {
		return nil, errors.New("order must have at least one item")
	}

	var totalPrice float64
	var orderItems []model.MallOrderItem
	var sellerID string

	for _, input := range req.Items {
		product, err := s.productRepo.FindProductByID(input.ProductID)
		if err != nil {
			return nil, errors.New("product not found: " + input.ProductID)
		}
		if product.Status != "active" {
			return nil, errors.New("product is not available: " + product.Name)
		}
		if sellerID == "" {
			sellerID = product.SellerID
		} else if sellerID != product.SellerID {
			return nil, errors.New("all items must be from the same seller")
		}

		subtotal := product.Price * float64(input.Quantity)
		totalPrice += subtotal

		orderItems = append(orderItems, model.MallOrderItem{
			ProductID: product.ID,
			Name:      product.Name,
			Price:     product.Price,
			Quantity:  input.Quantity,
		})
	}

	order := &model.MallOrder{
		BuyerID:    buyerID,
		SellerID:   sellerID,
		TotalPrice: totalPrice,
		Status:     model.OrderStatusPaid,
		Logistics:  model.LogisticsPickedUp,
	}

	if err := s.orderRepo.CreateOrder(order, orderItems); err != nil {
		return nil, errors.New("failed to create order")
	}

	// Clear cart for these items
	for _, input := range req.Items {
		_ = s.cartRepo.RemoveItem(buyerID, input.ProductID)
	}

	return order, nil
}

// ListOrders returns paginated orders.
func (s *MallService) ListOrders(userID, role string, page, pageSize int, status string) (*model.MallOrderListResponse, error) {
	items, total, err := s.orderRepo.ListOrders(userID, role, page, pageSize, status)
	if err != nil {
		return nil, errors.New("failed to query orders")
	}
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	return &model.MallOrderListResponse{
		Items:    items,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// GetOrderDetail returns an order with its items.
func (s *MallService) GetOrderDetail(orderID string) (*model.MallOrder, []model.MallOrderItem, error) {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil, errors.New("order not found")
		}
		return nil, nil, errors.New("database error")
	}
	items, err := s.orderRepo.GetOrderItems(orderID)
	if err != nil {
		return order, nil, nil
	}
	return order, items, nil
}

// ShipOrder marks an order as shipped.
func (s *MallService) ShipOrder(sellerID, orderID, trackingNumber string) error {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return errors.New("order not found")
	}
	if order.SellerID != sellerID {
		return errors.New("not authorized")
	}
	if order.Status != model.OrderStatusPaid {
		return errors.New("order cannot be shipped in current status")
	}
	return s.orderRepo.UpdateLogistics(orderID, model.LogisticsTransporting, trackingNumber)
}

// ReceiveOrder marks an order as received by buyer.
func (s *MallService) ReceiveOrder(buyerID, orderID string) error {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return errors.New("order not found")
	}
	if order.BuyerID != buyerID {
		return errors.New("not authorized")
	}
	return s.orderRepo.UpdateOrderStatus(orderID, model.OrderStatusReceived)
}

// CompleteOrder marks an order as completed.
func (s *MallService) CompleteOrder(orderID string) error {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return errors.New("order not found")
	}
	if order.Status != model.OrderStatusReceived && order.Status != model.OrderStatusShipped {
		return errors.New("order cannot be completed in current status")
	}
	return s.orderRepo.UpdateOrderStatus(orderID, model.OrderStatusCompleted)
}

// RequestRefund submits a refund request.
func (s *MallService) RequestRefund(buyerID, orderID, reason string) error {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return errors.New("order not found")
	}
	if order.BuyerID != buyerID {
		return errors.New("not authorized")
	}
	if order.RefundStatus == model.RefundSubmitted {
		return errors.New("refund already requested")
	}
	return s.orderRepo.UpdateRefund(orderID, reason, model.RefundSubmitted)
}

// ApproveRefund approves a refund request.
func (s *MallService) ApproveRefund(sellerID, orderID string) error {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return errors.New("order not found")
	}
	if order.SellerID != sellerID {
		return errors.New("not authorized")
	}
	if order.RefundStatus != model.RefundSubmitted {
		return errors.New("no pending refund request")
	}
	return s.orderRepo.UpdateRefund(orderID, order.RefundReason, model.RefundApproved)
}

// RejectRefund rejects a refund request.
func (s *MallService) RejectRefund(sellerID, orderID string) error {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return errors.New("order not found")
	}
	if order.SellerID != sellerID {
		return errors.New("not authorized")
	}
	if order.RefundStatus != model.RefundSubmitted {
		return errors.New("no pending refund request")
	}
	return s.orderRepo.UpdateRefund(orderID, order.RefundReason, model.RefundRejected)
}

// RequestReturn submits a return request.
func (s *MallService) RequestReturn(buyerID, orderID, reason string) error {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return errors.New("order not found")
	}
	if order.BuyerID != buyerID {
		return errors.New("not authorized")
	}
	if order.ReturnStatus == model.RefundSubmitted {
		return errors.New("return already requested")
	}
	return s.orderRepo.UpdateReturn(orderID, reason, model.RefundSubmitted)
}

// ApproveReturn approves a return request.
func (s *MallService) ApproveReturn(sellerID, orderID string) error {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return errors.New("order not found")
	}
	if order.SellerID != sellerID {
		return errors.New("not authorized")
	}
	if order.ReturnStatus != model.RefundSubmitted {
		return errors.New("no pending return request")
	}
	return s.orderRepo.UpdateReturn(orderID, order.ReturnReason, model.RefundApproved)
}

// RejectReturn rejects a return request.
func (s *MallService) RejectReturn(sellerID, orderID string) error {
	order, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return errors.New("order not found")
	}
	if order.SellerID != sellerID {
		return errors.New("not authorized")
	}
	if order.ReturnStatus != model.RefundSubmitted {
		return errors.New("no pending return request")
	}
	return s.orderRepo.UpdateReturn(orderID, order.ReturnReason, model.RefundRejected)
}

// ======================== Dispute Methods ========================

// CreateDispute files a new dispute.
func (s *MallService) CreateDispute(userID, orderID, reason, description string) (*model.MallDispute, error) {
	_, err := s.orderRepo.FindOrderByID(orderID)
	if err != nil {
		return nil, errors.New("order not found")
	}

	dispute := &model.MallDispute{
		OrderID:     orderID,
		ApplicantID: userID,
		Reason:      reason,
		Description: description,
		Status:      "submitted",
	}
	if err := s.disputeRepo.CreateDispute(dispute); err != nil {
		return nil, errors.New("failed to create dispute")
	}
	return dispute, nil
}

// ListDisputes returns disputes for a user.
func (s *MallService) ListDisputes(userID string) ([]model.MallDispute, error) {
	return s.disputeRepo.ListDisputes(userID)
}

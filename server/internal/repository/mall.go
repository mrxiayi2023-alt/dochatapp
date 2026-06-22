package repository

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：商城数据库操作

import (
	"fmt"
	"time"

	"dochatapp/server/internal/model"

	"gorm.io/gorm"
)

// ======================== ProductRepo ========================

// ProductRepo handles database operations for products.
type ProductRepo struct {
	db *gorm.DB
}

// NewProductRepo creates a new ProductRepo.
func NewProductRepo(db *gorm.DB) *ProductRepo {
	return &ProductRepo{db: db}
}

// CreateProduct inserts a new product.
func (r *ProductRepo) CreateProduct(p *model.MallProduct) error {
	return r.db.Create(p).Error
}

// FindProductByID retrieves a product by ID.
func (r *ProductRepo) FindProductByID(id string) (*model.MallProduct, error) {
	var p model.MallProduct
	err := r.db.Where("id = ?", id).First(&p).Error
	if err != nil {
		return nil, err
	}
	return &p, nil
}

// ListProducts returns paginated products with optional filters.
func (r *ProductRepo) ListProducts(page, pageSize int, category, subCategory, keyword, sellerID string) ([]model.MallProduct, int64, error) {
	query := r.db.Model(&model.MallProduct{}).Where("status = ?", "active")

	if category != "" {
		query = query.Where("category = ?", category)
	}
	if subCategory != "" {
		query = query.Where("sub_category = ?", subCategory)
	}
	if keyword != "" {
		kw := "%" + keyword + "%"
		query = query.Where("name ILIKE ? OR description ILIKE ?", kw, kw)
	}
	if sellerID != "" {
		query = query.Where("seller_id = ?", sellerID)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var products []model.MallProduct
	err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&products).Error
	return products, total, err
}

// UpdateProduct modifies an existing product.
func (r *ProductRepo) UpdateProduct(p *model.MallProduct) error {
	return r.db.Save(p).Error
}

// DeleteProduct removes a product by ID and seller.
func (r *ProductRepo) DeleteProduct(id, sellerID string) error {
	return r.db.Where("id = ? AND seller_id = ?", id, sellerID).Delete(&model.MallProduct{}).Error
}

// ======================== CartRepo ========================

// CartRepo handles database operations for shopping carts.
type CartRepo struct {
	db *gorm.DB
}

// NewCartRepo creates a new CartRepo.
func NewCartRepo(db *gorm.DB) *CartRepo {
	return &CartRepo{db: db}
}

// AddItem adds an item to the cart.
func (r *CartRepo) AddItem(item *model.MallCartItem) error {
	return r.db.Create(item).Error
}

// UpdateQuantity updates the quantity of an existing cart item.
func (r *CartRepo) UpdateQuantity(userID, productID string, quantity int) error {
	return r.db.Model(&model.MallCartItem{}).
		Where("user_id = ? AND product_id = ?", userID, productID).
		Update("quantity", quantity).Error
}

// RemoveItem removes an item from the cart.
func (r *CartRepo) RemoveItem(userID, productID string) error {
	return r.db.Where("user_id = ? AND product_id = ?", userID, productID).Delete(&model.MallCartItem{}).Error
}

// GetCart returns all items in a user's cart.
func (r *CartRepo) GetCart(userID string) ([]model.MallCartItem, error) {
	var items []model.MallCartItem
	err := r.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&items).Error
	return items, err
}

// ClearCart removes all items from a user's cart.
func (r *CartRepo) ClearCart(userID string) error {
	return r.db.Where("user_id = ?", userID).Delete(&model.MallCartItem{}).Error
}

// FindCartItem finds a specific cart item.
func (r *CartRepo) FindCartItem(userID, productID string) (*model.MallCartItem, error) {
	var item model.MallCartItem
	err := r.db.Where("user_id = ? AND product_id = ?", userID, productID).First(&item).Error
	if err != nil {
		return nil, err
	}
	return &item, nil
}

// ======================== OrderRepo ========================

// OrderRepo handles database operations for orders.
type OrderRepo struct {
	db *gorm.DB
}

// NewOrderRepo creates a new OrderRepo.
func NewOrderRepo(db *gorm.DB) *OrderRepo {
	return &OrderRepo{db: db}
}

// CreateOrder inserts a new order with its items in a transaction.
func (r *OrderRepo) CreateOrder(order *model.MallOrder, items []model.MallOrderItem) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// Generate order number
		order.OrderNo = fmt.Sprintf("M%d", time.Now().UnixNano())
		if err := tx.Create(order).Error; err != nil {
			return err
		}
		for i := range items {
			items[i].OrderID = order.ID
			if err := tx.Create(&items[i]).Error; err != nil {
				return err
			}
		}
		return nil
	})
}

// FindOrderByID retrieves an order by ID.
func (r *OrderRepo) FindOrderByID(id string) (*model.MallOrder, error) {
	var order model.MallOrder
	err := r.db.Where("id = ?", id).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

// ListOrders returns paginated orders for a user as buyer or seller.
func (r *OrderRepo) ListOrders(userID, role string, page, pageSize int, status string) ([]model.MallOrder, int64, error) {
	query := r.db.Model(&model.MallOrder{})
	switch role {
	case "buyer":
		query = query.Where("buyer_id = ?", userID)
	case "seller":
		query = query.Where("seller_id = ?", userID)
	default:
		query = query.Where("buyer_id = ? OR seller_id = ?", userID, userID)
	}

	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var orders []model.MallOrder
	err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&orders).Error
	return orders, total, err
}

// UpdateOrderStatus updates an order's status field.
func (r *OrderRepo) UpdateOrderStatus(id, status string) error {
	return r.db.Model(&model.MallOrder{}).Where("id = ?", id).Update("status", status).Error
}

// UpdateLogistics updates shipping information.
func (r *OrderRepo) UpdateLogistics(id, logistics, trackingNumber string) error {
	return r.db.Model(&model.MallOrder{}).Where("id = ?", id).Updates(map[string]interface{}{
		"logistics":       logistics,
		"tracking_number": trackingNumber,
		"status":          model.OrderStatusShipped,
	}).Error
}

// UpdateRefund updates refund information.
func (r *OrderRepo) UpdateRefund(id, reason, status string) error {
	return r.db.Model(&model.MallOrder{}).Where("id = ?", id).Updates(map[string]interface{}{
		"refund_reason": reason,
		"refund_status": status,
	}).Error
}

// UpdateReturn updates return information.
func (r *OrderRepo) UpdateReturn(id, reason, status string) error {
	return r.db.Model(&model.MallOrder{}).Where("id = ?", id).Updates(map[string]interface{}{
		"return_reason": reason,
		"return_status": status,
	}).Error
}

// GetOrderItems returns all items for an order.
func (r *OrderRepo) GetOrderItems(orderID string) ([]model.MallOrderItem, error) {
	var items []model.MallOrderItem
	err := r.db.Where("order_id = ?", orderID).Find(&items).Error
	return items, err
}

// ======================== DisputeRepo ========================

// DisputeRepo handles database operations for disputes.
type DisputeRepo struct {
	db *gorm.DB
}

// NewDisputeRepo creates a new DisputeRepo.
func NewDisputeRepo(db *gorm.DB) *DisputeRepo {
	return &DisputeRepo{db: db}
}

// CreateDispute inserts a new dispute.
func (r *DisputeRepo) CreateDispute(d *model.MallDispute) error {
	return r.db.Create(d).Error
}

// ListDisputes returns all disputes for a user.
func (r *DisputeRepo) ListDisputes(userID string) ([]model.MallDispute, error) {
	var disputes []model.MallDispute
	err := r.db.Where("applicant_id = ?", userID).Order("created_at DESC").Find(&disputes).Error
	return disputes, err
}

// UpdateDisputeStatus updates a dispute's status.
func (r *DisputeRepo) UpdateDisputeStatus(id, status string) error {
	return r.db.Model(&model.MallDispute{}).Where("id = ?", id).Update("status", status).Error
}

// FindDisputeByID retrieves a dispute by ID.
func (r *DisputeRepo) FindDisputeByID(id string) (*model.MallDispute, error) {
	var d model.MallDispute
	err := r.db.Where("id = ?", id).First(&d).Error
	if err != nil {
		return nil, err
	}
	return &d, nil
}

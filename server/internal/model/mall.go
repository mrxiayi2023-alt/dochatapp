package model

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：商城数据模型

import "time"

// 订单状态
const (
	OrderStatusPaid      = "paid"
	OrderStatusShipped   = "shipped"
	OrderStatusReceived  = "received"
	OrderStatusCompleted = "completed"
	OrderStatusCancelled = "cancelled"
)

// 物流状态
const (
	LogisticsPickedUp     = "picked_up"
	LogisticsTransporting = "transporting"
	LogisticsDelivering   = "delivering"
	LogisticsSigned       = "signed"
)

// 退款状态
const (
	RefundNone      = ""
	RefundSubmitted = "submitted"
	RefundRejected  = "rejected"
	RefundApproved  = "approved"
)

// MallProduct 商品
type MallProduct struct {
	ID          string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	SellerID    string    `gorm:"type:uuid;not null;index" json:"seller_id"`
	Name        string    `gorm:"type:varchar(100);not null" json:"name"`
	Price       float64   `gorm:"not null" json:"price"`
	Unit        string    `gorm:"type:varchar(20);default:''" json:"unit"`
	Category    string    `gorm:"type:varchar(50);index" json:"category"`
	SubCategory string    `gorm:"type:varchar(50)" json:"sub_category"`
	Seller      string    `gorm:"type:varchar(100)" json:"seller"`
	Description string    `gorm:"type:text" json:"description"`
	Images      string    `gorm:"type:text;default:'[]'" json:"images"`
	PriceType   string    `gorm:"type:varchar(10);default:'fixed'" json:"price_type"`
	Status      string    `gorm:"type:varchar(20);default:'active'" json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// MallCartItem 购物车
type MallCartItem struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    string    `gorm:"type:uuid;not null;index:idx_cart_user" json:"user_id"`
	ProductID string    `gorm:"type:uuid;not null;index" json:"product_id"`
	Quantity  int       `gorm:"default:1" json:"quantity"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// MallOrder 订单
type MallOrder struct {
	ID             string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	OrderNo        string    `gorm:"type:varchar(50);uniqueIndex" json:"order_no"`
	BuyerID        string    `gorm:"type:uuid;not null;index" json:"buyer_id"`
	SellerID       string    `gorm:"type:uuid;not null;index" json:"seller_id"`
	TotalPrice     float64   `gorm:"not null" json:"total_price"`
	Status         string    `gorm:"type:varchar(20);default:'paid'" json:"status"`
	Logistics      string    `gorm:"type:varchar(20);default:'picked_up'" json:"logistics"`
	TrackingNumber string    `gorm:"type:varchar(100);default:''" json:"tracking_number"`
	RefundReason   string    `gorm:"type:text" json:"refund_reason"`
	RefundStatus   string    `gorm:"type:varchar(20);default:''" json:"refund_status"`
	ReturnReason   string    `gorm:"type:text" json:"return_reason"`
	ReturnStatus   string    `gorm:"type:varchar(20);default:''" json:"return_status"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// MallOrderItem 订单商品明细
type MallOrderItem struct {
	ID        string  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	OrderID   string  `gorm:"type:uuid;not null;index" json:"order_id"`
	ProductID string  `gorm:"type:uuid;not null" json:"product_id"`
	Name      string  `gorm:"type:varchar(100)" json:"name"`
	Price     float64 `gorm:"not null" json:"price"`
	Quantity  int     `gorm:"default:1" json:"quantity"`
}

// MallDispute 纠纷
type MallDispute struct {
	ID           string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	OrderID      string    `gorm:"type:uuid;not null;index" json:"order_id"`
	ApplicantID  string    `gorm:"type:uuid;not null" json:"applicant_id"`
	Reason       string    `gorm:"type:varchar(50)" json:"reason"`
	Description  string    `gorm:"type:text" json:"description"`
	Status       string    `gorm:"type:varchar(20);default:'submitted'" json:"status"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// MallProductListResponse wraps paginated product results.
type MallProductListResponse struct {
	Items    []MallProduct `json:"items"`
	Total    int64         `json:"total"`
	Page     int           `json:"page"`
	PageSize int           `json:"page_size"`
}

// MallOrderListResponse wraps paginated order results.
type MallOrderListResponse struct {
	Items    []MallOrder `json:"items"`
	Total    int64       `json:"total"`
	Page     int         `json:"page"`
	PageSize int         `json:"page_size"`
}

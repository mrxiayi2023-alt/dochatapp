package model

import "time"

// 房源认证状态
const (
	HousingVerified = "verified"
	HousingPending  = "pending"
	HousingRejected = "rejected"
)

// 发布身份
const (
	PublisherPersonal = "个人"
	PublisherAgent    = "中介"
)

// 物业类型
const (
	PropertyResidential = "住宅"
	PropertyCommercial  = "商铺"
	PropertyOffice      = "写字楼"
)

// HousingListing 房源信息表 — 与前端 HousingListing 模型完全对齐
type HousingListing struct {
	ID                 string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	PublisherID        string    `gorm:"type:uuid;not null;index" json:"publisher_id"`
	Title              string    `gorm:"type:varchar(200);not null" json:"title"`
	PropertyType       string    `gorm:"type:varchar(20);not null" json:"property_type"`           // 住宅/商铺/写字楼
	Province           string    `gorm:"type:varchar(20);not null" json:"province"`                // 省
	City               string    `gorm:"type:varchar(20);not null" json:"city"`                    // 市（前端字段 district）
	District           string    `gorm:"type:varchar(20);not null" json:"district"`                // 区（前端字段 area）
	Town               string    `gorm:"type:varchar(20);default:''" json:"town"`                  // 镇/街道
	Layout             string    `gorm:"type:varchar(20);not null" json:"layout"`                  // 户型 e.g. "3室2厅"
	Size               float64   `gorm:"not null" json:"size"`                                     // 面积 m²
	Floor              string    `gorm:"type:varchar(20);not null" json:"floor"`                   // e.g. "8/18层"
	Decoration         string    `gorm:"type:varchar(20);not null" json:"decoration"`              // 简装/精装/豪装
	Price              float64   `gorm:"not null" json:"price"`                                    // 月租金
	Description        string    `gorm:"type:text" json:"description"`
	Contact            string    `gorm:"type:varchar(20);not null" json:"contact"`                 // 联系电话
	VerificationStatus string    `gorm:"type:varchar(20);default:pending" json:"verification_status"`
	Photos             string    `gorm:"type:text;default:'[]'" json:"photos"`                     // JSON 数组字符串
	PublisherType      string    `gorm:"type:varchar(20);default:'个人'" json:"publisher_type"`
	CompanyName        string    `gorm:"type:varchar(100);default:''" json:"company_name"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}

// HousingFavorite 收藏记录
type HousingFavorite struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    string    `gorm:"type:uuid;not null;uniqueIndex:idx_hf_user_listing" json:"user_id"`
	ListingID string    `gorm:"type:uuid;not null;uniqueIndex:idx_hf_user_listing" json:"listing_id"`
	CreatedAt time.Time `json:"created_at"`
}

// HousingBrowseHistory 浏览历史
type HousingBrowseHistory struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    string    `gorm:"type:uuid;not null;index" json:"user_id"`
	ListingID string    `gorm:"type:uuid;not null" json:"listing_id"`
	CreatedAt time.Time `json:"created_at"`
}

// HousingListResponse 分页列表返回值
type HousingListResponse struct {
	Items    []HousingListing `json:"items"`
	Total    int64            `json:"total"`
	Page     int              `json:"page"`
	PageSize int              `json:"page_size"`
}

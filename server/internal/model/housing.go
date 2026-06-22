package model

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：房源租赁数据模型

import "time"

// HousingListing represents a rental property listing.
type HousingListing struct {
	ID           string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Title        string    `gorm:"type:varchar(200);not null" json:"title"`
	Description  string    `gorm:"type:text" json:"description"`
	Price        float64   `gorm:"type:decimal(10,2);not null" json:"price"`
	Area         float64   `gorm:"type:decimal(8,2);default:0" json:"area"`
	Address      string    `gorm:"type:varchar(300)" json:"address"`
	City         string    `gorm:"type:varchar(50);index" json:"city"`
	District     string    `gorm:"type:varchar(50);index" json:"district"`
	Bedrooms     int       `gorm:"default:0" json:"bedrooms"`
	LivingRooms  int       `gorm:"default:0" json:"living_rooms"`
	Bathrooms    int       `gorm:"default:0" json:"bathrooms"`
	Floor        int       `gorm:"default:0" json:"floor"`
	TotalFloors  int       `gorm:"default:0" json:"total_floors"`
	Orientation  string    `gorm:"type:varchar(20)" json:"orientation"`
	Decoration   string    `gorm:"type:varchar(30)" json:"decoration"`
	PropertyType string    `gorm:"type:varchar(30)" json:"property_type"`
	Images       string    `gorm:"type:text" json:"images"`
	ContactPhone string    `gorm:"type:varchar(20)" json:"contact_phone"`
	ContactName  string    `gorm:"type:varchar(50)" json:"contact_name"`
	PublisherID  string    `gorm:"type:uuid;not null;index" json:"publisher_id"`
	Status       string    `gorm:"type:varchar(20);default:'published';index" json:"status"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// HousingFavorite stores user-favorited listings.
type HousingFavorite struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    string    `gorm:"type:uuid;not null;uniqueIndex:idx_hf_user_listing" json:"user_id"`
	ListingID string    `gorm:"type:uuid;not null;uniqueIndex:idx_hf_user_listing" json:"listing_id"`
	CreatedAt time.Time `json:"created_at"`
}

// HousingBrowseHistory records listing browse events.
type HousingBrowseHistory struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    string    `gorm:"type:uuid;not null;index" json:"user_id"`
	ListingID string    `gorm:"type:uuid;not null" json:"listing_id"`
	CreatedAt time.Time `json:"created_at"`
}

// HousingListResponse wraps paginated search results.
type HousingListResponse struct {
	Items      []HousingListing `json:"items"`
	Total      int64            `json:"total"`
	Page       int              `json:"page"`
	PageSize   int              `json:"page_size"`
}

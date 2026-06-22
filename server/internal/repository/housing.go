package repository

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：房源数据库操作

import (
	"dochatapp/server/internal/model"

	"gorm.io/gorm"
)

// HousingRepository handles database operations for housing listings.
type HousingRepository struct {
	db *gorm.DB
}

// NewHousingRepository creates a new HousingRepository.
func NewHousingRepository(db *gorm.DB) *HousingRepository {
	return &HousingRepository{db: db}
}

// Create inserts a new housing listing.
func (r *HousingRepository) Create(listing *model.HousingListing) error {
	return r.db.Create(listing).Error
}

// Update modifies an existing listing (only by owner).
func (r *HousingRepository) Update(listing *model.HousingListing) error {
	return r.db.Save(listing).Error
}

// Delete removes a listing by ID (only by owner).
func (r *HousingRepository) Delete(id, publisherID string) error {
	return r.db.Where("id = ? AND publisher_id = ?", id, publisherID).Delete(&model.HousingListing{}).Error
}

// FindByID retrieves a single listing by its ID.
func (r *HousingRepository) FindByID(id string) (*model.HousingListing, error) {
	var listing model.HousingListing
	err := r.db.Where("id = ?", id).First(&listing).Error
	if err != nil {
		return nil, err
	}
	return &listing, nil
}

// HousingListParams holds filtering and pagination parameters.
type HousingListParams struct {
	City         string
	District     string
	MinPrice     float64
	MaxPrice     float64
	MinArea      float64
	MaxArea      float64
	Bedrooms     int
	PropertyType string
	Decoration   string
	Orientation  string
	Keyword      string
	Page         int
	PageSize     int
}

// List returns paginated listings matching the given filters.
func (r *HousingRepository) List(params HousingListParams) ([]model.HousingListing, int64, error) {
	query := r.db.Model(&model.HousingListing{}).Where("status = ?", "published")

	if params.City != "" {
		query = query.Where("city = ?", params.City)
	}
	if params.District != "" {
		query = query.Where("district = ?", params.District)
	}
	if params.MinPrice > 0 {
		query = query.Where("price >= ?", params.MinPrice)
	}
	if params.MaxPrice > 0 {
		query = query.Where("price <= ?", params.MaxPrice)
	}
	if params.MinArea > 0 {
		query = query.Where("area >= ?", params.MinArea)
	}
	if params.MaxArea > 0 {
		query = query.Where("area <= ?", params.MaxArea)
	}
	if params.Bedrooms > 0 {
		query = query.Where("bedrooms = ?", params.Bedrooms)
	}
	if params.PropertyType != "" {
		query = query.Where("property_type = ?", params.PropertyType)
	}
	if params.Decoration != "" {
		query = query.Where("decoration = ?", params.Decoration)
	}
	if params.Orientation != "" {
		query = query.Where("orientation = ?", params.Orientation)
	}
	if params.Keyword != "" {
		kw := "%" + params.Keyword + "%"
		query = query.Where("title ILIKE ? OR description ILIKE ? OR address ILIKE ?", kw, kw, kw)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	page := params.Page
	if page < 1 {
		page = 1
	}
	pageSize := params.PageSize
	if pageSize < 1 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var listings []model.HousingListing
	err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&listings).Error
	return listings, total, err
}

// FindByPublisher returns listings published by a specific user.
func (r *HousingRepository) FindByPublisher(publisherID string) ([]model.HousingListing, error) {
	var listings []model.HousingListing
	err := r.db.Where("publisher_id = ?", publisherID).Order("created_at DESC").Find(&listings).Error
	return listings, err
}

// AddFavorite adds a listing to user favorites.
func (r *HousingRepository) AddFavorite(fav *model.HousingFavorite) error {
	return r.db.Create(fav).Error
}

// RemoveFavorite removes a listing from user favorites.
func (r *HousingRepository) RemoveFavorite(userID, listingID string) error {
	return r.db.Where("user_id = ? AND listing_id = ?", userID, listingID).Delete(&model.HousingFavorite{}).Error
}

// IsFavorited checks if a user has favorited a listing.
func (r *HousingRepository) IsFavorited(userID, listingID string) (bool, error) {
	var count int64
	err := r.db.Model(&model.HousingFavorite{}).Where("user_id = ? AND listing_id = ?", userID, listingID).Count(&count).Error
	return count > 0, err
}

// GetFavorites returns a user's favorited listing IDs.
func (r *HousingRepository) GetFavorites(userID string) ([]model.HousingFavorite, error) {
	var favs []model.HousingFavorite
	err := r.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&favs).Error
	return favs, err
}

// RecordBrowse saves a browse history entry.
func (r *HousingRepository) RecordBrowse(history *model.HousingBrowseHistory) error {
	return r.db.Create(history).Error
}

// GetBrowseHistory returns a user's browse history.
func (r *HousingRepository) GetBrowseHistory(userID string, limit int) ([]model.HousingBrowseHistory, error) {
	var history []model.HousingBrowseHistory
	err := r.db.Where("user_id = ?", userID).Order("created_at DESC").Limit(limit).Find(&history).Error
	return history, err
}

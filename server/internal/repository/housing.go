package repository

import (
	"dochatapp/server/internal/model"
	"gorm.io/gorm"
)

type HousingRepository struct {
	db *gorm.DB
}

func NewHousingRepository(db *gorm.DB) *HousingRepository {
	return &HousingRepository{db: db}
}

func (r *HousingRepository) Create(listing *model.HousingListing) error {
	return r.db.Create(listing).Error
}

func (r *HousingRepository) Update(listing *model.HousingListing) error {
	return r.db.Save(listing).Error
}

func (r *HousingRepository) Delete(id, publisherID string) error {
	return r.db.Where("id = ? AND publisher_id = ?", id, publisherID).Delete(&model.HousingListing{}).Error
}

func (r *HousingRepository) FindByID(id string) (*model.HousingListing, error) {
	var listing model.HousingListing
	err := r.db.Where("id = ?", id).First(&listing).Error
	if err != nil {
		return nil, err
	}
	return &listing, nil
}

type HousingListParams struct {
	Province, City, District, Town, PropertyType, Decoration, Keyword string
	MinPrice, MaxPrice float64
	Page, PageSize int
}

func (r *HousingRepository) List(params HousingListParams) ([]model.HousingListing, int64, error) {
	query := r.db.Model(&model.HousingListing{})
	if params.Province != "" { query = query.Where("province = ?", params.Province) }
	if params.City != "" { query = query.Where("city = ?", params.City) }
	if params.District != "" { query = query.Where("district = ?", params.District) }
	if params.Town != "" { query = query.Where("town = ?", params.Town) }
	if params.PropertyType != "" { query = query.Where("property_type = ?", params.PropertyType) }
	if params.MinPrice > 0 { query = query.Where("price >= ?", params.MinPrice) }
	if params.MaxPrice > 0 { query = query.Where("price <= ?", params.MaxPrice) }
	if params.Decoration != "" { query = query.Where("decoration = ?", params.Decoration) }
	if params.Keyword != "" { kw := "%" + params.Keyword + "%"; query = query.Where("title ILIKE ? OR description ILIKE ?", kw, kw) }
	var total int64
	if err := query.Count(&total).Error; err != nil { return nil, 0, err }
	page := params.Page; if page < 1 { page = 1 }
	pageSize := params.PageSize; if pageSize < 1 { pageSize = 20 }
	offset := (page - 1) * pageSize
	var listings []model.HousingListing
	err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&listings).Error
	return listings, total, err
}

func (r *HousingRepository) FindByPublisher(publisherID string) ([]model.HousingListing, error) {
	var listings []model.HousingListing
	err := r.db.Where("publisher_id = ?", publisherID).Order("created_at DESC").Find(&listings).Error
	return listings, err
}

func (r *HousingRepository) AddFavorite(fav *model.HousingFavorite) error { return r.db.Create(fav).Error }
func (r *HousingRepository) RemoveFavorite(userID, listingID string) error {
	return r.db.Where("user_id = ? AND listing_id = ?", userID, listingID).Delete(&model.HousingFavorite{}).Error
}
func (r *HousingRepository) IsFavorited(userID, listingID string) (bool, error) {
	var count int64
	err := r.db.Model(&model.HousingFavorite{}).Where("user_id = ? AND listing_id = ?", userID, listingID).Count(&count).Error
	return count > 0, err
}
func (r *HousingRepository) GetFavorites(userID string) ([]model.HousingFavorite, error) {
	var favs []model.HousingFavorite
	err := r.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&favs).Error
	return favs, err
}
func (r *HousingRepository) RecordBrowse(history *model.HousingBrowseHistory) error { return r.db.Create(history).Error }
func (r *HousingRepository) GetBrowseHistory(userID string, limit int) ([]model.HousingBrowseHistory, error) {
	var history []model.HousingBrowseHistory
	err := r.db.Where("user_id = ?", userID).Order("created_at DESC").Limit(limit).Find(&history).Error
	return history, err
}

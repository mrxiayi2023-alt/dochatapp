package service

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：房源租赁业务逻辑

import (
	"errors"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"

	"gorm.io/gorm"
)

// HousingService handles housing business logic.
type HousingService struct {
	repo *repository.HousingRepository
}

// NewHousingService creates a new HousingService.
func NewHousingService(repo *repository.HousingRepository) *HousingService {
	return &HousingService{repo: repo}
}

// PublishRequest is the payload for publishing a listing.
type PublishRequest struct {
	Title        string  `json:"title" binding:"required"`
	Description  string  `json:"description"`
	Price        float64 `json:"price" binding:"required,gt=0"`
	Area         float64 `json:"area"`
	Address      string  `json:"address"`
	City         string  `json:"city" binding:"required"`
	District     string  `json:"district"`
	Bedrooms     int     `json:"bedrooms"`
	LivingRooms  int     `json:"living_rooms"`
	Bathrooms    int     `json:"bathrooms"`
	Floor        int     `json:"floor"`
	TotalFloors  int     `json:"total_floors"`
	Orientation  string  `json:"orientation"`
	Decoration   string  `json:"decoration"`
	PropertyType string  `json:"property_type"`
	Images       string  `json:"images"`
	ContactPhone string  `json:"contact_phone"`
	ContactName  string  `json:"contact_name"`
}

// ListRequest is the payload for listing with filters.
type ListRequest struct {
	City         string  `form:"city"`
	District     string  `form:"district"`
	MinPrice     float64 `form:"min_price"`
	MaxPrice     float64 `form:"max_price"`
	MinArea      float64 `form:"min_area"`
	MaxArea      float64 `form:"max_area"`
	Bedrooms     int     `form:"bedrooms"`
	PropertyType string  `form:"property_type"`
	Decoration   string  `form:"decoration"`
	Orientation  string  `form:"orientation"`
	Keyword      string  `form:"keyword"`
	Page         int     `form:"page"`
	PageSize     int     `form:"page_size"`
}

// Publish creates a new housing listing.
func (s *HousingService) Publish(publisherID string, req *PublishRequest) (*model.HousingListing, error) {
	listing := &model.HousingListing{
		Title:        req.Title,
		Description:  req.Description,
		Price:        req.Price,
		Area:         req.Area,
		Address:      req.Address,
		City:         req.City,
		District:     req.District,
		Bedrooms:     req.Bedrooms,
		LivingRooms:  req.LivingRooms,
		Bathrooms:    req.Bathrooms,
		Floor:        req.Floor,
		TotalFloors:  req.TotalFloors,
		Orientation:  req.Orientation,
		Decoration:   req.Decoration,
		PropertyType: req.PropertyType,
		Images:       req.Images,
		ContactPhone: req.ContactPhone,
		ContactName:  req.ContactName,
		PublisherID:  publisherID,
		Status:       "published",
	}
	if err := s.repo.Create(listing); err != nil {
		return nil, errors.New("failed to create listing")
	}
	return listing, nil
}

// Update modifies an existing listing.
func (s *HousingService) Update(publisherID, id string, req *PublishRequest) (*model.HousingListing, error) {
	listing, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("listing not found")
		}
		return nil, errors.New("database error")
	}
	if listing.PublisherID != publisherID {
		return nil, errors.New("not authorized to edit this listing")
	}

	listing.Title = req.Title
	listing.Description = req.Description
	listing.Price = req.Price
	listing.Area = req.Area
	listing.Address = req.Address
	listing.City = req.City
	listing.District = req.District
	listing.Bedrooms = req.Bedrooms
	listing.LivingRooms = req.LivingRooms
	listing.Bathrooms = req.Bathrooms
	listing.Floor = req.Floor
	listing.TotalFloors = req.TotalFloors
	listing.Orientation = req.Orientation
	listing.Decoration = req.Decoration
	listing.PropertyType = req.PropertyType
	listing.Images = req.Images
	listing.ContactPhone = req.ContactPhone
	listing.ContactName = req.ContactName

	if err := s.repo.Update(listing); err != nil {
		return nil, errors.New("failed to update listing")
	}
	return listing, nil
}

// Delete removes a listing.
func (s *HousingService) Delete(publisherID, id string) error {
	listing, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("listing not found")
		}
		return errors.New("database error")
	}
	if listing.PublisherID != publisherID {
		return errors.New("not authorized to delete this listing")
	}
	return s.repo.Delete(id, publisherID)
}

// List returns paginated listings with filters.
func (s *HousingService) List(req *ListRequest) (*model.HousingListResponse, error) {
	params := repository.HousingListParams{
		City:         req.City,
		District:     req.District,
		MinPrice:     req.MinPrice,
		MaxPrice:     req.MaxPrice,
		MinArea:      req.MinArea,
		MaxArea:      req.MaxArea,
		Bedrooms:     req.Bedrooms,
		PropertyType: req.PropertyType,
		Decoration:   req.Decoration,
		Orientation:  req.Orientation,
		Keyword:      req.Keyword,
		Page:         req.Page,
		PageSize:     req.PageSize,
	}

	items, total, err := s.repo.List(params)
	if err != nil {
		return nil, errors.New("failed to query listings")
	}

	page := req.Page
	if page < 1 {
		page = 1
	}
	pageSize := req.PageSize
	if pageSize < 1 {
		pageSize = 20
	}

	return &model.HousingListResponse{
		Items:    items,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// Detail returns a single listing by ID and records a browse event.
func (s *HousingService) Detail(userID, id string) (*model.HousingListing, bool, error) {
	listing, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, false, errors.New("listing not found")
		}
		return nil, false, errors.New("database error")
	}

	favorited, _ := s.repo.IsFavorited(userID, id)

	// Record browse history
	_ = s.repo.RecordBrowse(&model.HousingBrowseHistory{
		UserID:    userID,
		ListingID: id,
	})

	return listing, favorited, nil
}

// ToggleFavorite adds or removes a favorite.
func (s *HousingService) ToggleFavorite(userID, listingID string, add bool) error {
	if add {
		return s.repo.AddFavorite(&model.HousingFavorite{
			UserID:    userID,
			ListingID: listingID,
		})
	}
	return s.repo.RemoveFavorite(userID, listingID)
}

// GetFavorites returns a user's favorited listings.
func (s *HousingService) GetFavorites(userID string) ([]model.HousingListing, error) {
	favs, err := s.repo.GetFavorites(userID)
	if err != nil {
		return nil, errors.New("failed to get favorites")
	}

	var result []model.HousingListing
	for _, f := range favs {
		listing, err := s.repo.FindByID(f.ListingID)
		if err == nil {
			result = append(result, *listing)
		}
	}

	return result, nil
}

// GetBrowseHistory returns the user's browse history.
func (s *HousingService) GetBrowseHistory(userID string, limit int) ([]model.HousingBrowseHistory, error) {
	if limit < 1 || limit > 100 {
		limit = 20
	}
	return s.repo.GetBrowseHistory(userID, limit)
}

// GetMyListings returns listings published by the current user.
func (s *HousingService) GetMyListings(userID string) ([]model.HousingListing, error) {
	return s.repo.FindByPublisher(userID)
}

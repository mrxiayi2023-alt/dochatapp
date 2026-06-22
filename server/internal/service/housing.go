package service

import (
	"encoding/json"
	"errors"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"

	"gorm.io/gorm"
)

type HousingService struct {
	repo *repository.HousingRepository
}

func NewHousingService(repo *repository.HousingRepository) *HousingService {
	return &HousingService{repo: repo}
}

type PublishRequest struct {
	Title        string   `json:"title" binding:"required"`
	PropertyType string   `json:"property_type" binding:"required"`
	Province     string   `json:"province" binding:"required"`
	City         string   `json:"city" binding:"required"`
	District     string   `json:"district" binding:"required"`
	Town         string   `json:"town"`
	Layout       string   `json:"layout" binding:"required"`
	Size         float64  `json:"size" binding:"required"`
	Floor        string   `json:"floor" binding:"required"`
	Decoration   string   `json:"decoration" binding:"required"`
	Price        float64  `json:"price" binding:"required"`
	Description  string   `json:"description"`
	Contact      string   `json:"contact" binding:"required"`
	Photos       []string `json:"photos"`
	PublisherType string  `json:"publisher_type"`
	CompanyName  string   `json:"company_name"`
}

type ListRequest struct {
	Province     string  `form:"province"`
	City         string  `form:"city"`
	District     string  `form:"district"`
	Town         string  `form:"town"`
	PropertyType string  `form:"property_type"`
	MinPrice     float64 `form:"price_min"`
	MaxPrice     float64 `form:"price_max"`
	Decoration   string  `form:"decoration"`
	Keyword      string  `form:"keyword"`
	Page         int     `form:"page"`
	PageSize     int     `form:"page_size"`
}

func (s *HousingService) Publish(publisherID string, req *PublishRequest) (*model.HousingListing, error) {
	photosJSON := "[]"
	if len(req.Photos) > 0 {
		b, _ := json.Marshal(req.Photos)
		photosJSON = string(b)
	}
	publisherType := req.PublisherType
	if publisherType == "" {
		publisherType = "个人"
	}
	listing := &model.HousingListing{
		PublisherID:        publisherID,
		Title:              req.Title,
		PropertyType:       req.PropertyType,
		Province:           req.Province,
		City:               req.City,
		District:           req.District,
		Town:               req.Town,
		Layout:             req.Layout,
		Size:               req.Size,
		Floor:              req.Floor,
		Decoration:         req.Decoration,
		Price:              req.Price,
		Description:        req.Description,
		Contact:            req.Contact,
		Photos:             photosJSON,
		PublisherType:      publisherType,
		CompanyName:        req.CompanyName,
		VerificationStatus: "pending",
	}
	if err := s.repo.Create(listing); err != nil {
		return nil, errors.New("failed to create listing")
	}
	return listing, nil
}

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
	photosJSON := "[]"
	if len(req.Photos) > 0 {
		b, _ := json.Marshal(req.Photos)
		photosJSON = string(b)
	}
	listing.Title = req.Title
	listing.PropertyType = req.PropertyType
	listing.Province = req.Province
	listing.City = req.City
	listing.District = req.District
	listing.Town = req.Town
	listing.Layout = req.Layout
	listing.Size = req.Size
	listing.Floor = req.Floor
	listing.Decoration = req.Decoration
	listing.Price = req.Price
	listing.Description = req.Description
	listing.Contact = req.Contact
	listing.Photos = photosJSON
	listing.PublisherType = req.PublisherType
	listing.CompanyName = req.CompanyName
	if err := s.repo.Update(listing); err != nil {
		return nil, errors.New("failed to update listing")
	}
	return listing, nil
}

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

func (s *HousingService) List(req *ListRequest) (*model.HousingListResponse, error) {
	params := repository.HousingListParams{
		Province: req.Province, City: req.City, District: req.District, Town: req.Town,
		PropertyType: req.PropertyType, MinPrice: req.MinPrice, MaxPrice: req.MaxPrice,
		Decoration: req.Decoration, Keyword: req.Keyword, Page: req.Page, PageSize: req.PageSize,
	}
	items, total, err := s.repo.List(params)
	if err != nil {
		return nil, errors.New("failed to query listings")
	}
	page := req.Page; if page < 1 { page = 1 }
	pageSize := req.PageSize; if pageSize < 1 { pageSize = 20 }
	return &model.HousingListResponse{Items: items, Total: total, Page: page, PageSize: pageSize}, nil
}

func (s *HousingService) Detail(userID, id string) (*model.HousingListing, bool, error) {
	listing, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, false, errors.New("listing not found")
		}
		return nil, false, errors.New("database error")
	}
	favorited, _ := s.repo.IsFavorited(userID, id)
	_ = s.repo.RecordBrowse(&model.HousingBrowseHistory{UserID: userID, ListingID: id})
	return listing, favorited, nil
}

func (s *HousingService) ToggleFavorite(userID, listingID string, add bool) error {
	if add {
		return s.repo.AddFavorite(&model.HousingFavorite{UserID: userID, ListingID: listingID})
	}
	return s.repo.RemoveFavorite(userID, listingID)
}

func (s *HousingService) GetFavorites(userID string) ([]model.HousingListing, error) {
	favs, err := s.repo.GetFavorites(userID)
	if err != nil { return nil, errors.New("failed to get favorites") }
	var result []model.HousingListing
	for _, f := range favs {
		listing, err := s.repo.FindByID(f.ListingID)
		if err == nil { result = append(result, *listing) }
	}
	return result, nil
}

func (s *HousingService) GetBrowseHistory(userID string, limit int) ([]model.HousingBrowseHistory, error) {
	if limit < 1 || limit > 100 { limit = 20 }
	return s.repo.GetBrowseHistory(userID, limit)
}

func (s *HousingService) GetMyListings(userID string) ([]model.HousingListing, error) {
	return s.repo.FindByPublisher(userID)
}

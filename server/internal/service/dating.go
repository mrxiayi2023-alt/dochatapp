package service

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：婚恋业务逻辑

import (
	"encoding/json"
	"errors"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"

	"gorm.io/gorm"
)

// DatingService handles dating business logic.
type DatingService struct {
	repo *repository.DatingRepository
}

// NewDatingService creates a new DatingService.
func NewDatingService(repo *repository.DatingRepository) *DatingService {
	return &DatingService{repo: repo}
}

// SaveProfileRequest is the payload for saving a dating profile.
type SaveProfileRequest struct {
	Name           string   `json:"name"`
	Age            int      `json:"age"`
	Gender         string   `json:"gender"`
	Tags           []string `json:"tags"`
	Intro          string   `json:"intro"`
	DatingCriteria string   `json:"dating_criteria"`
}

// LikeRequest is the payload for liking/unliking a user.
type LikeRequest struct {
	ToUID string `json:"to_uid" binding:"required"`
	Liked bool   `json:"liked"`
}

// SaveProfile creates or updates a dating profile.
func (s *DatingService) SaveProfile(userID string, req *SaveProfileRequest) (*model.DatingProfile, error) {
	tagsJSON, _ := json.Marshal(req.Tags)

	profile := &model.DatingProfile{
		UserID:         userID,
		Name:           req.Name,
		Age:            req.Age,
		Gender:         req.Gender,
		Tags:           string(tagsJSON),
		Intro:          req.Intro,
		DatingCriteria: req.DatingCriteria,
	}

	if req.Intro != "" && req.DatingCriteria != "" {
		profile.CompletenessScore = 80
	} else if req.Intro != "" || req.DatingCriteria != "" {
		profile.CompletenessScore = 40
	}

	if err := s.repo.SaveProfile(profile); err != nil {
		return nil, errors.New("failed to save profile")
	}
	return profile, nil
}

// GetProfile returns the current user's dating profile.
func (s *DatingService) GetProfile(userID string) (*model.DatingProfile, error) {
	profile, err := s.repo.FindProfileByUserID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("profile not found")
		}
		return nil, errors.New("database error")
	}
	return profile, nil
}

// GetProfileByID returns another user's dating profile.
func (s *DatingService) GetProfileByID(userID, profileUserID string) (*model.DatingProfile, bool, error) {
	if userID == profileUserID {
		profile, err := s.GetProfile(userID)
		if err != nil {
			return nil, false, err
		}
		return profile, false, nil
	}

	profile, err := s.repo.FindProfileByUserID(profileUserID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, false, errors.New("profile not found")
		}
		return nil, false, errors.New("database error")
	}

	isLiked, _ := s.repo.IsLiked(userID, profileUserID)
	return profile, isLiked, nil
}

// Recommend returns recommended dating profiles.
func (s *DatingService) Recommend(userID string, page, pageSize int, gender string, ageMin, ageMax int) (*model.DatingListResponse, error) {
	items, _, err := s.repo.ListProfiles(page, pageSize, gender, ageMin, ageMax)
	if err != nil {
		return nil, errors.New("failed to query profiles")
	}

	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}

	// Filter out own profile and already-liked profiles
	likedUIDs, _ := s.repo.GetLikedUIDs(userID)
	likedSet := make(map[string]bool)
	for _, uid := range likedUIDs {
		likedSet[uid] = true
	}

	var filtered []model.DatingProfile
	for _, p := range items {
		if p.UserID != userID && !likedSet[p.UserID] {
			filtered = append(filtered, p)
		}
	}

	return &model.DatingListResponse{
		Items:    filtered,
		Total:    int64(len(filtered)),
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// Like records a like or unlike action.
func (s *DatingService) Like(userID string, req *LikeRequest) error {
	if userID == req.ToUID {
		return errors.New("cannot like yourself")
	}

	like := &model.DatingLike{
		FromUID: userID,
		ToUID:   req.ToUID,
		Liked:   req.Liked,
	}
	return s.repo.AddLike(like)
}

// GetMatches returns profiles where mutual likes exist.
func (s *DatingService) GetMatches(userID string) ([]model.DatingProfile, error) {
	return s.repo.GetMatches(userID)
}

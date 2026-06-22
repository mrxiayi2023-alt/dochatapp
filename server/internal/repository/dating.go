package repository

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：婚恋数据库操作

import (
	"dochatapp/server/internal/model"

	"gorm.io/gorm"
)

// DatingRepository handles database operations for dating.
type DatingRepository struct {
	db *gorm.DB
}

// NewDatingRepository creates a new DatingRepository.
func NewDatingRepository(db *gorm.DB) *DatingRepository {
	return &DatingRepository{db: db}
}

// SaveProfile creates or updates a dating profile.
func (r *DatingRepository) SaveProfile(p *model.DatingProfile) error {
	existing, err := r.FindProfileByUserID(p.UserID)
	if err != nil {
		return r.db.Create(p).Error
	}
	p.ID = existing.ID
	p.CreatedAt = existing.CreatedAt
	return r.db.Save(p).Error
}

// FindProfileByUserID retrieves a profile by user ID.
func (r *DatingRepository) FindProfileByUserID(userID string) (*model.DatingProfile, error) {
	var p model.DatingProfile
	err := r.db.Where("user_id = ?", userID).First(&p).Error
	if err != nil {
		return nil, err
	}
	return &p, nil
}

// ListProfiles returns paginated profiles with optional filters.
func (r *DatingRepository) ListProfiles(page, pageSize int, gender string, ageMin, ageMax int) ([]model.DatingProfile, int64, error) {
	query := r.db.Model(&model.DatingProfile{})

	if gender != "" {
		query = query.Where("gender = ?", gender)
	}
	if ageMin > 0 {
		query = query.Where("age >= ?", ageMin)
	}
	if ageMax > 0 {
		query = query.Where("age <= ?", ageMax)
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

	var profiles []model.DatingProfile
	err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&profiles).Error
	return profiles, total, err
}

// AddLike inserts a new like record (upsert).
func (r *DatingRepository) AddLike(like *model.DatingLike) error {
	existing, err := r.FindLike(like.FromUID, like.ToUID)
	if err != nil {
		return r.db.Create(like).Error
	}
	return r.db.Model(existing).Update("liked", like.Liked).Error
}

// FindLike finds an existing like record.
func (r *DatingRepository) FindLike(fromUID, toUID string) (*model.DatingLike, error) {
	var like model.DatingLike
	err := r.db.Where("from_uid = ? AND to_uid = ?", fromUID, toUID).First(&like).Error
	if err != nil {
		return nil, err
	}
	return &like, nil
}

// IsLiked checks if a user has liked another user.
func (r *DatingRepository) IsLiked(fromUID, toUID string) (bool, error) {
	var count int64
	err := r.db.Model(&model.DatingLike{}).
		Where("from_uid = ? AND to_uid = ? AND liked = true", fromUID, toUID).
		Count(&count).Error
	return count > 0, err
}

// GetLikedUIDs returns all UIDs that a user has liked.
func (r *DatingRepository) GetLikedUIDs(userID string) ([]string, error) {
	var likes []model.DatingLike
	err := r.db.Where("from_uid = ? AND liked = true", userID).Find(&likes).Error
	if err != nil {
		return nil, err
	}
	uids := make([]string, len(likes))
	for i, l := range likes {
		uids[i] = l.ToUID
	}
	return uids, nil
}

// GetMatches returns profiles where both users liked each other.
func (r *DatingRepository) GetMatches(userID string) ([]model.DatingProfile, error) {
	// Get all users that I liked
	var myLikes []model.DatingLike
	if err := r.db.Where("from_uid = ? AND liked = true", userID).Find(&myLikes).Error; err != nil {
		return nil, err
	}

	var matchedProfiles []model.DatingProfile
	for _, myLike := range myLikes {
		// Check if they liked me back
		isLiked, err := r.IsLiked(myLike.ToUID, userID)
		if err != nil {
			continue
		}
		if isLiked {
			profile, err := r.FindProfileByUserID(myLike.ToUID)
			if err == nil {
				matchedProfiles = append(matchedProfiles, *profile)
			}
		}
	}

	return matchedProfiles, nil
}

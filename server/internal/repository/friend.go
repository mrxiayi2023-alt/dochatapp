package repository

import (
	"dochatapp/server/internal/model"

	"gorm.io/gorm"
)

// FriendRepository handles database operations for friends and friend requests.
type FriendRepository struct {
	db *gorm.DB
}

func NewFriendRepository(db *gorm.DB) *FriendRepository {
	return &FriendRepository{db: db}
}

// CreateRequest inserts a new friend request.
func (r *FriendRepository) CreateRequest(req *model.FriendRequest) error {
	return r.db.Create(req).Error
}

// FindPendingRequest checks if there's already a pending request between two users (either direction).
func (r *FriendRepository) FindPendingRequest(fromID, toID string) (*model.FriendRequest, error) {
	var req model.FriendRequest
	err := r.db.Where(
		"((from_id = ? AND to_id = ?) OR (from_id = ? AND to_id = ?)) AND status = ?",
		fromID, toID, toID, fromID, model.FriendStatusPending,
	).First(&req).Error
	if err != nil {
		return nil, err
	}
	return &req, nil
}

// FindRequestByID finds a friend request by ID.
func (r *FriendRepository) FindRequestByID(id string) (*model.FriendRequest, error) {
	var req model.FriendRequest
	err := r.db.Where("id = ?", id).First(&req).Error
	if err != nil {
		return nil, err
	}
	return &req, nil
}

// UpdateRequestStatus updates the status of a friend request.
func (r *FriendRepository) UpdateRequestStatus(id, status string) error {
	return r.db.Model(&model.FriendRequest{}).Where("id = ?", id).Update("status", status).Error
}

// GetIncomingRequests returns all pending friend requests sent to a user.
func (r *FriendRepository) GetIncomingRequests(userID string) ([]model.FriendRequestView, error) {
	var results []model.FriendRequestView
	err := r.db.Raw(`
		SELECT
			fr.id,
			fr.from_id,
			u.nickname AS from_nickname,
			u.phone    AS from_phone,
			fr.status,
			to_char(fr.created_at, 'YYYY-MM-DD HH24:MI') AS created_at
		FROM friend_requests fr
		JOIN users u ON u.id = fr.from_id
		WHERE fr.to_id = ? AND fr.status = ?
		ORDER BY fr.created_at DESC
	`, userID, model.FriendStatusPending).Scan(&results).Error
	return results, err
}

// AddFriend inserts a bidirectional friendship record.
func (r *FriendRepository) AddFriend(userID, friendID string) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// Insert both directions
		f1 := model.Friend{UserID: userID, FriendID: friendID}
		f2 := model.Friend{UserID: friendID, FriendID: userID}
		if err := tx.Create(&f1).Error; err != nil {
			return err
		}
		if err := tx.Create(&f2).Error; err != nil {
			return err
		}
		return nil
	})
}

// GetFriends returns the friend list for a user.
func (r *FriendRepository) GetFriends(userID string) ([]model.FriendView, error) {
	var friends []model.FriendView
	err := r.db.Raw(`
		SELECT
			u.id       AS user_id,
			u.nickname,
			u.phone
		FROM friends f
		JOIN users u ON u.id = f.friend_id
		WHERE f.user_id = ?
		ORDER BY u.nickname ASC
	`, userID).Scan(&friends).Error
	return friends, err
}

// IsFriend checks if two users are already friends.
func (r *FriendRepository) IsFriend(userID, otherID string) (bool, error) {
	var count int64
	err := r.db.Model(&model.Friend{}).
		Where("user_id = ? AND friend_id = ?", userID, otherID).
		Count(&count).Error
	return count > 0, err
}

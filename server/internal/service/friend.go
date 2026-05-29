package service

import (
	"errors"
	"time"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"

	"gorm.io/gorm"
)

// FriendService handles friend-related business logic.
type FriendService struct {
	friendRepo *repository.FriendRepository
	userRepo   *repository.UserRepository
}

func NewFriendService(friendRepo *repository.FriendRepository, userRepo *repository.UserRepository) *FriendService {
	return &FriendService{friendRepo: friendRepo, userRepo: userRepo}
}

// SendRequest creates a friend request from fromID to the user identified by toPhone.
func (s *FriendService) SendRequest(fromID, toPhone string) error {
	// Look up the target user by phone
	target, err := s.userRepo.FindByPhone(toPhone)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("user not found")
		}
		return errors.New("database error")
	}

	if target.ID == fromID {
		return errors.New("cannot add yourself as friend")
	}

	// Check if already friends
	already, err := s.friendRepo.IsFriend(fromID, target.ID)
	if err != nil {
		return errors.New("database error")
	}
	if already {
		return errors.New("already friends")
	}

	// Check for existing pending request
	existing, _ := s.friendRepo.FindPendingRequest(fromID, target.ID)
	if existing != nil {
		return errors.New("friend request already sent")
	}

	req := &model.FriendRequest{
		FromID:    fromID,
		ToID:      target.ID,
		Status:    model.FriendStatusPending,
		CreatedAt: time.Now(),
	}
	return s.friendRepo.CreateRequest(req)
}

// GetIncomingRequests returns pending friend requests for a user.
func (s *FriendService) GetIncomingRequests(userID string) ([]model.FriendRequestView, error) {
	return s.friendRepo.GetIncomingRequests(userID)
}

// AcceptRequest accepts a friend request.
func (s *FriendService) AcceptRequest(userID, requestID string) error {
	req, err := s.friendRepo.FindRequestByID(requestID)
	if err != nil {
		return errors.New("request not found")
	}
	if req.ToID != userID {
		return errors.New("unauthorized")
	}
	if req.Status != model.FriendStatusPending {
		return errors.New("request already processed")
	}

	// Update status
	if err := s.friendRepo.UpdateRequestStatus(requestID, model.FriendStatusAccepted); err != nil {
		return errors.New("failed to accept request")
	}

	// Add bidirectional friendship
	return s.friendRepo.AddFriend(req.FromID, req.ToID)
}

// RejectRequest rejects a friend request.
func (s *FriendService) RejectRequest(userID, requestID string) error {
	req, err := s.friendRepo.FindRequestByID(requestID)
	if err != nil {
		return errors.New("request not found")
	}
	if req.ToID != userID {
		return errors.New("unauthorized")
	}
	if req.Status != model.FriendStatusPending {
		return errors.New("request already processed")
	}
	return s.friendRepo.UpdateRequestStatus(requestID, model.FriendStatusRejected)
}

// GetFriends returns the friend list for a user.
func (s *FriendService) GetFriends(userID string) ([]model.FriendView, error) {
	return s.friendRepo.GetFriends(userID)
}

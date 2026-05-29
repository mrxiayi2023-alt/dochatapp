package model

import "time"

// Friend request statuses
const (
	FriendStatusPending  = "pending"
	FriendStatusAccepted = "accepted"
	FriendStatusRejected = "rejected"
)

// FriendRequest represents a friend request between two users.
type FriendRequest struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	FromID    string    `gorm:"type:uuid;not null;index" json:"from_id"`
	ToID      string    `gorm:"type:uuid;not null;index" json:"to_id"`
	Status    string    `gorm:"type:varchar(20);not null;default:pending" json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

// Friend is a join record representing an accepted friendship.
type Friend struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    string    `gorm:"type:uuid;not null;index" json:"user_id"`
	FriendID  string    `gorm:"type:uuid;not null;index" json:"friend_id"`
	CreatedAt time.Time `json:"created_at"`
}

// FriendRequestView is the DTO returned by the friend request list API.
type FriendRequestView struct {
	ID            string `json:"id"`
	FromID        string `json:"from_id"`
	FromNickname  string `json:"from_nickname"`
	FromPhone     string `json:"from_phone"`
	Status        string `json:"status"`
	CreatedAt     string `json:"created_at"`
}

// FriendView is the DTO returned by the friend list API.
type FriendView struct {
	UserID   string `json:"user_id"`
	Nickname string `json:"nickname"`
	Phone    string `json:"phone"`
}

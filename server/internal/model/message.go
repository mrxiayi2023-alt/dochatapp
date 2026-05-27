package model

import "time"

// Message types
const (
	MsgTypeText  = "text"
	MsgTypeImage = "image"
	MsgTypeFile  = "file"
)

// Message represents a chat message stored in the database.
type Message struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	FromID    string    `gorm:"type:uuid;not null;index" json:"from_id"`
	ToID      string    `gorm:"type:uuid;not null;index" json:"to_id"`
	GroupID   string    `gorm:"type:uuid;default:null;index" json:"group_id,omitempty"`
	Content   string    `gorm:"type:text;not null" json:"content"`
	Type      string    `gorm:"type:varchar(20);not null;default:text" json:"type"`
	CreatedAt time.Time `json:"created_at"`
}

// Conversation summary returned by the conversations endpoint.
type Conversation struct {
	WithUserID   string `json:"with_user_id"`
	WithNickname string `json:"with_nickname"`
	WithAvatar   string `json:"with_avatar"`
	LastMessage  string `json:"last_message"`
	LastTime     string `json:"last_time"`
	UnreadCount  int    `json:"unread_count"`
}

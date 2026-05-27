package repository

import (
	"time"

	"dochatapp/server/internal/model"

	"gorm.io/gorm"
)

// MessageRepository handles database operations for messages.
type MessageRepository struct {
	db *gorm.DB
}

func NewMessageRepository(db *gorm.DB) *MessageRepository {
	return &MessageRepository{db: db}
}

// Save inserts a new message.
func (r *MessageRepository) Save(msg *model.Message) error {
	return r.db.Create(msg).Error
}

// GetChatHistory returns messages between two users, ordered by time ascending.
func (r *MessageRepository) GetChatHistory(userID, otherID string, limit, offset int) ([]model.Message, error) {
	var messages []model.Message
	err := r.db.Where(
		"(from_id = ? AND to_id = ?) OR (from_id = ? AND to_id = ?)",
		userID, otherID, otherID, userID,
	).
		Order("created_at asc").
		Limit(limit).
		Offset(offset).
		Find(&messages).Error
	return messages, err
}

// GetConversations returns the latest message for each user the given user has chatted with.
func (r *MessageRepository) GetConversations(userID string) ([]model.Conversation, error) {
	// Subquery: get the latest message per conversation partner
	type result struct {
		WithID    string
		Content   string
		CreatedAt time.Time
	}

	var rows []result
	// Use DISTINCT ON with created_at DESC to get the latest message per partner.
	// PostgreSQL does not support MAX(uuid), so we order by created_at instead.
	err := r.db.Raw(`
		SELECT DISTINCT ON (other_user)
			other_user AS with_id,
			content,
			created_at
		FROM (
			SELECT
				CASE WHEN from_id = ? THEN to_id ELSE from_id END AS other_user,
				content,
				created_at
			FROM messages
			WHERE from_id = ? OR to_id = ?
		) sub
		ORDER BY other_user, created_at DESC
	`, userID, userID, userID).Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	// Build conversations with user info
	var conversations []model.Conversation
	for _, row := range rows {
		var user model.User
		if err := r.db.Where("id = ?", row.WithID).First(&user).Error; err != nil {
			continue
		}
		conversations = append(conversations, model.Conversation{
			WithUserID:   row.WithID,
			WithNickname: user.Nickname,
			WithAvatar:   user.Avatar,
			LastMessage:  row.Content,
			LastTime:     row.CreatedAt.Format("15:04"),
		})
	}
	return conversations, nil
}

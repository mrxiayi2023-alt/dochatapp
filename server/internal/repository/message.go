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
		CreatedAt   time.Time
		UnreadCount int
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

	// Count unread messages for each conversation partner
	// FIXED: populate unread count from database
	for i := range rows {
		var cnt int64
		r.db.Raw("SELECT COUNT(*) FROM messages m WHERE ((m.from_id = ? AND m.to_id = ?) OR (m.from_id = ? AND m.to_id = ?)) AND m.created_at > (SELECT COALESCE(MAX(m2.created_at), '1970-01-01') FROM messages m2 WHERE m2.from_id = ? AND m2.to_id = ?)", rows[i].WithID, userID, userID, rows[i].WithID, userID, rows[i].WithID).Scan(&cnt)
		rows[i].UnreadCount = int(cnt)
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
			UnreadCount:  row.UnreadCount,  // FIXED: populate unread count from query
		})
	}
	return conversations, nil
}

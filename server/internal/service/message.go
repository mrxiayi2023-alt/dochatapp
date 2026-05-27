package service

import (
	"time"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"
	"dochatapp/server/internal/websocket"
)

// MessageService handles message business logic.
type MessageService struct {
	repo *repository.MessageRepository
	hub  *websocket.Hub
}

func NewMessageService(repo *repository.MessageRepository, hub *websocket.Hub) *MessageService {
	return &MessageService{repo: repo, hub: hub}
}

// SendRequest is the payload for sending a message.
type SendRequest struct {
	ToID    string `json:"to_id" binding:"required"`
	Content string `json:"content" binding:"required"`
	Type    string `json:"type"` // defaults to "text"
}

// SendMessage stores a message and pushes it via WebSocket.
func (s *MessageService) SendMessage(fromID string, req *SendRequest) (*model.Message, error) {
	msgType := req.Type
	if msgType == "" {
		msgType = model.MsgTypeText
	}

	msg := &model.Message{
		FromID:    fromID,
		ToID:      req.ToID,
		Content:   req.Content,
		Type:      msgType,
		CreatedAt: time.Now(),
	}

	if err := s.repo.Save(msg); err != nil {
		return nil, err
	}

	// Push via WebSocket to the recipient
	s.hub.SendMessage(fromID, req.ToID, req.Content, msg.CreatedAt.Format("15:04"), msg.ID)

	return msg, nil
}

// GetChatHistory returns paginated chat history between two users.
func (s *MessageService) GetChatHistory(userID, otherID string, limit, offset int) ([]model.Message, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	return s.repo.GetChatHistory(userID, otherID, limit, offset)
}

// GetConversations returns conversation summaries.
func (s *MessageService) GetConversations(userID string) ([]model.Conversation, error) {
	return s.repo.GetConversations(userID)
}

package service

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：邮件业务逻辑

import (
	"errors"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"

	"gorm.io/gorm"
)

// MailService handles mail business logic.
type MailService struct {
	repo *repository.MailRepository
}

// NewMailService creates a new MailService.
func NewMailService(repo *repository.MailRepository) *MailService {
	return &MailService{repo: repo}
}

// SendMailRequest is the payload for sending a mail.
type SendMailRequest struct {
	ToUID   string `json:"to_uid" binding:"required"`
	To      string `json:"to"`
	Subject string `json:"subject" binding:"required"`
	Body    string `json:"body" binding:"required"`
}

// Send creates a sent mail and an inbox mail.
func (s *MailService) Send(fromUID, sender string, req *SendMailRequest) (*model.Mail, error) {
	if fromUID == req.ToUID {
		return nil, errors.New("cannot send mail to yourself")
	}

	// Create sent copy
	sentMail := &model.Mail{
		FromUID: fromUID,
		ToUID:   req.ToUID,
		Sender:  sender,
		To:      req.To,
		Subject: req.Subject,
		Body:    req.Body,
		Folder:  model.MailFolderSent,
		IsRead:  true,
	}
	if err := s.repo.Create(sentMail); err != nil {
		return nil, errors.New("failed to send mail")
	}

	// Create inbox copy for recipient
	inboxMail := &model.Mail{
		FromUID: fromUID,
		ToUID:   req.ToUID,
		Sender:  sender,
		To:      req.To,
		Subject: req.Subject,
		Body:    req.Body,
		Folder:  model.MailFolderInbox,
		IsRead:  false,
	}
	_ = s.repo.Create(inboxMail)

	return sentMail, nil
}

// ListInbox returns the inbox folder.
func (s *MailService) ListInbox(userID string, page, pageSize int) (*model.MailListResponse, error) {
	items, total, err := s.repo.ListByUser(userID, model.MailFolderInbox, page, pageSize)
	if err != nil {
		return nil, errors.New("failed to query inbox")
	}
	return s.buildResponse(items, total, page, pageSize), nil
}

// ListSent returns the sent folder.
func (s *MailService) ListSent(userID string, page, pageSize int) (*model.MailListResponse, error) {
	items, total, err := s.repo.ListByUser(userID, model.MailFolderSent, page, pageSize)
	if err != nil {
		return nil, errors.New("failed to query sent")
	}
	return s.buildResponse(items, total, page, pageSize), nil
}

// ListDrafts returns the drafts folder.
func (s *MailService) ListDrafts(userID string, page, pageSize int) (*model.MailListResponse, error) {
	items, total, err := s.repo.ListByUser(userID, model.MailFolderDrafts, page, pageSize)
	if err != nil {
		return nil, errors.New("failed to query drafts")
	}
	return s.buildResponse(items, total, page, pageSize), nil
}

// Detail returns a mail and marks it as read.
func (s *MailService) Detail(userID, id string) (*model.Mail, error) {
	mail, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("mail not found")
		}
		return nil, errors.New("database error")
	}

	// Only mark as read if the user is the recipient
	if mail.ToUID == userID && !mail.IsRead {
		_ = s.repo.MarkAsRead(id)
		mail.IsRead = true
	}

	return mail, nil
}

// MoveToTrash moves a mail to the trash folder.
func (s *MailService) MoveToTrash(userID, id string) error {
	mail, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("mail not found")
	}
	if mail.ToUID != userID && mail.FromUID != userID {
		return errors.New("not authorized")
	}
	return s.repo.UpdateFolder(id, model.MailFolderTrash)
}

// Restore moves a mail from trash back to its original folder.
func (s *MailService) Restore(userID, id string) error {
	mail, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("mail not found")
	}
	if mail.ToUID != userID && mail.FromUID != userID {
		return errors.New("not authorized")
	}
	if mail.Folder != model.MailFolderTrash {
		return errors.New("mail is not in trash")
	}

	// Restore to original folder based on ownership
	targetFolder := model.MailFolderInbox
	if mail.FromUID == userID {
		targetFolder = model.MailFolderSent
	}
	return s.repo.UpdateFolder(id, targetFolder)
}

// Delete permanently removes a mail.
func (s *MailService) Delete(userID, id string) error {
	mail, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("mail not found")
	}
	if mail.ToUID != userID && mail.FromUID != userID {
		return errors.New("not authorized")
	}
	return s.repo.Delete(id)
}

func (s *MailService) buildResponse(items []model.Mail, total int64, page, pageSize int) *model.MailListResponse {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	return &model.MailListResponse{
		Items:    items,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}
}

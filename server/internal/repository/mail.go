package repository

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：邮件数据库操作

import (
	"dochatapp/server/internal/model"

	"gorm.io/gorm"
)

// MailRepository handles database operations for mails.
type MailRepository struct {
	db *gorm.DB
}

// NewMailRepository creates a new MailRepository.
func NewMailRepository(db *gorm.DB) *MailRepository {
	return &MailRepository{db: db}
}

// Create inserts a new mail record.
func (r *MailRepository) Create(m *model.Mail) error {
	return r.db.Create(m).Error
}

// FindByID retrieves a mail by ID.
func (r *MailRepository) FindByID(id string) (*model.Mail, error) {
	var m model.Mail
	err := r.db.Where("id = ?", id).First(&m).Error
	if err != nil {
		return nil, err
	}
	return &m, nil
}

// ListByUser returns paginated mails for a user in a specific folder.
func (r *MailRepository) ListByUser(userID, folder string, page, pageSize int) ([]model.Mail, int64, error) {
	var query *gorm.DB
	switch folder {
	case model.MailFolderInbox:
		query = r.db.Model(&model.Mail{}).Where("to_uid = ? AND folder = ?", userID, model.MailFolderInbox)
	case model.MailFolderSent:
		query = r.db.Model(&model.Mail{}).Where("from_uid = ? AND folder = ?", userID, model.MailFolderSent)
	default:
		query = r.db.Model(&model.Mail{}).Where("(to_uid = ? OR from_uid = ?) AND folder = ?", userID, userID, folder)
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

	var mails []model.Mail
	err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&mails).Error
	return mails, total, err
}

// UpdateFolder moves a mail to a different folder.
func (r *MailRepository) UpdateFolder(id, folder string) error {
	return r.db.Model(&model.Mail{}).Where("id = ?", id).Update("folder", folder).Error
}

// MarkAsRead marks a mail as read.
func (r *MailRepository) MarkAsRead(id string) error {
	return r.db.Model(&model.Mail{}).Where("id = ?", id).Update("is_read", true).Error
}

// Delete permanently removes a mail.
func (r *MailRepository) Delete(id string) error {
	return r.db.Where("id = ?", id).Delete(&model.Mail{}).Error
}

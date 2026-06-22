package model

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：邮件数据模型

import "time"

// 邮件文件夹常量
const (
	MailFolderInbox  = "inbox"
	MailFolderSent   = "sent"
	MailFolderDrafts = "drafts"
	MailFolderTrash  = "trash"
)

// Mail 内部邮件
type Mail struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	FromUID   string    `gorm:"type:uuid;not null;index" json:"from_uid"`
	ToUID     string    `gorm:"type:uuid;not null;index" json:"to_uid"`
	Sender    string    `gorm:"type:varchar(100)" json:"sender"`
	To        string    `gorm:"type:varchar(100)" json:"to"`
	Subject   string    `gorm:"type:varchar(200)" json:"subject"`
	Body      string    `gorm:"type:text" json:"body"`
	Folder    string    `gorm:"type:varchar(20);default:'inbox'" json:"folder"`
	IsRead    bool      `gorm:"default:false" json:"is_read"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// MailListResponse wraps paginated mail results.
type MailListResponse struct {
	Items    []Mail `json:"items"`
	Total    int64  `json:"total"`
	Page     int    `json:"page"`
	PageSize int    `json:"page_size"`
}

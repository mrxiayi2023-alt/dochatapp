package model

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：用户数据模型



import "time"

// User represents a registered user in the system.
type User struct {
	ID         string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Phone      string    `gorm:"type:varchar(20);uniqueIndex;not null" json:"phone"`
	Password   string    `gorm:"type:varchar(255);not null" json:"-"`
	Nickname   string    `gorm:"type:varchar(50);default:''" json:"nickname"`
	Avatar     string    `gorm:"type:varchar(255);default:''" json:"avatar"`
	Email      string    `gorm:"type:varchar(100);default:''" json:"email"`
	IsVerified bool      `gorm:"default:false" json:"is_verified"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

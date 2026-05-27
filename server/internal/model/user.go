package model

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

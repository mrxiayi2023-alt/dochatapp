package repository

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：用户数据库操作



import (
	"dochatapp/server/internal/model"

	"gorm.io/gorm"
)

// UserRepository handles database operations for users.
type UserRepository struct {
	db *gorm.DB
}

// NewUserRepository creates a new UserRepository.
func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

// Create inserts a new user record.
func (r *UserRepository) Create(user *model.User) error {
	return r.db.Create(user).Error
}

// FindByPhone finds a user by phone number.
func (r *UserRepository) FindByPhone(phone string) (*model.User, error) {
	var user model.User
	err := r.db.Where("phone = ?", phone).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// FindByID finds a user by UUID.
func (r *UserRepository) FindByID(id string) (*model.User, error) {
	var user model.User
	err := r.db.Where("id = ?", id).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

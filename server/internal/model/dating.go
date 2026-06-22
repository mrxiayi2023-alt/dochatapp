package model

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：婚恋数据模型

import "time"

// DatingProfile 婚恋资料
type DatingProfile struct {
	ID                       string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID                   string    `gorm:"type:uuid;not null;uniqueIndex" json:"user_id"`
	Name                     string    `gorm:"type:varchar(50)" json:"name"`
	Age                      int       `gorm:"default:0" json:"age"`
	Gender                   string    `gorm:"type:varchar(4)" json:"gender"`
	Tags                     string    `gorm:"type:text;default:'[]'" json:"tags"`
	Intro                    string    `gorm:"type:text" json:"intro"`
	DatingCriteria           string    `gorm:"type:text" json:"dating_criteria"`
	RealnessScore            int       `gorm:"default:0" json:"realness_score"`
	InteractionScore         int       `gorm:"default:0" json:"interaction_score"`
	CompletenessScore        int       `gorm:"default:0" json:"completeness_score"`
	IntegrityScore           int       `gorm:"default:0" json:"integrity_score"`
	IsRealNameVerified       bool      `gorm:"default:false" json:"is_real_name_verified"`
	IsFaceVerified           bool      `gorm:"default:false" json:"is_face_verified"`
	IsSingleCommitmentSigned bool      `gorm:"default:false" json:"is_single_commitment_signed"`
	CreatedAt                time.Time `json:"created_at"`
	UpdatedAt                time.Time `json:"updated_at"`
}

// DatingLike 喜欢记录
type DatingLike struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	FromUID   string    `gorm:"type:uuid;not null;index:idx_like_from" json:"from_uid"`
	ToUID     string    `gorm:"type:uuid;not null;index:idx_like_to" json:"to_uid"`
	Liked     bool      `gorm:"default:true" json:"liked"`
	CreatedAt time.Time `json:"created_at"`
}

// DatingListResponse wraps paginated dating results.
type DatingListResponse struct {
	Items    []DatingProfile `json:"items"`
	Total    int64           `json:"total"`
	Page     int             `json:"page"`
	PageSize int             `json:"page_size"`
}

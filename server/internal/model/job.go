package model

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：招聘求职数据模型

import "time"

// Job represents a job posting.
type Job struct {
	ID          string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	CompanyID   string    `gorm:"type:uuid;not null;index" json:"company_id"`
	Title       string    `gorm:"type:varchar(200);not null" json:"title"`
	Description string    `gorm:"type:text" json:"description"`
	Requirements string   `gorm:"type:text" json:"requirements"`
	SalaryRange string    `gorm:"type:varchar(100)" json:"salary_range"`
	Location    string    `gorm:"type:varchar(200)" json:"location"`
	City        string    `gorm:"type:varchar(50);index" json:"city"`
	District    string    `gorm:"type:varchar(50)" json:"district"`
	Education   string    `gorm:"type:varchar(30)" json:"education"`
	Experience  string    `gorm:"type:varchar(30)" json:"experience"`
	JobType     string    `gorm:"type:varchar(30)" json:"job_type"`
	Openings    int       `gorm:"default:1" json:"openings"`
	Status      string    `gorm:"type:varchar(20);default:'published';index" json:"status"`
	PublisherID string    `gorm:"type:uuid;not null;index" json:"publisher_id"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Company represents a registered company.
type Company struct {
	ID           string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID       string    `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	Name         string    `gorm:"type:varchar(200);not null" json:"name"`
	Description  string    `gorm:"type:text" json:"description"`
	Industry     string    `gorm:"type:varchar(50)" json:"industry"`
	Scale        string    `gorm:"type:varchar(30)" json:"scale"`
	Address      string    `gorm:"type:varchar(300)" json:"address"`
	City         string    `gorm:"type:varchar(50)" json:"city"`
	District     string    `gorm:"type:varchar(50)" json:"district"`
	Logo         string    `gorm:"type:varchar(500)" json:"logo"`
	ContactPhone string    `gorm:"type:varchar(20)" json:"contact_phone"`
	ContactName  string    `gorm:"type:varchar(50)" json:"contact_name"`
	Status       string    `gorm:"type:varchar(20);default:'active'" json:"status"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// Resume represents a job seeker's resume.
type Resume struct {
	ID              string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID          string    `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	Name            string    `gorm:"type:varchar(50);not null" json:"name"`
	Gender          string    `gorm:"type:varchar(10)" json:"gender"`
	Age             int       `gorm:"default:0" json:"age"`
	Education       string    `gorm:"type:varchar(30)" json:"education"`
	Experience      string    `gorm:"type:varchar(30)" json:"experience"`
	Skills          string    `gorm:"type:text" json:"skills"`
	Introduction    string    `gorm:"type:text" json:"introduction"`
	Phone           string    `gorm:"type:varchar(20)" json:"phone"`
	Email           string    `gorm:"type:varchar(100)" json:"email"`
	CurrentStatus   string    `gorm:"type:varchar(20)" json:"current_status"`
	AvailableTime   string    `gorm:"type:varchar(20)" json:"available_time"`
	ExpectedSalary  string    `gorm:"type:varchar(100)" json:"expected_salary"`
	ExpectedCity    string    `gorm:"type:varchar(50)" json:"expected_city"`
	ExpectedDistrict string   `gorm:"type:varchar(50)" json:"expected_district"`
	JobType         string    `gorm:"type:varchar(30)" json:"job_type"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// JobApplication represents a job application.
type JobApplication struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	JobID     string    `gorm:"type:uuid;not null;index" json:"job_id"`
	UserID    string    `gorm:"type:uuid;not null;index" json:"user_id"`
	ResumeID  string    `gorm:"type:uuid;not null" json:"resume_id"`
	Status    string    `gorm:"type:varchar(20);default:'pending';index" json:"status"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Interview represents a scheduled interview.
type Interview struct {
	ID            string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	ApplicationID string    `gorm:"type:uuid;not null;index" json:"application_id"`
	JobID         string    `gorm:"type:uuid;not null" json:"job_id"`
	CompanyID     string    `gorm:"type:uuid;not null" json:"company_id"`
	UserID        string    `gorm:"type:uuid;not null;index" json:"user_id"`
	InterviewTime time.Time `json:"interview_time"`
	Location      string    `gorm:"type:varchar(300)" json:"location"`
	Status        string    `gorm:"type:varchar(20);default:'scheduled'" json:"status"`
	Remark        string    `gorm:"type:text" json:"remark"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// JobFavorite stores user-favorited jobs.
type JobFavorite struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    string    `gorm:"type:uuid;not null;uniqueIndex:idx_jf_user_job" json:"user_id"`
	JobID     string    `gorm:"type:uuid;not null;uniqueIndex:idx_jf_user_job" json:"job_id"`
	CreatedAt time.Time `json:"created_at"`
}

// JobListResponse wraps paginated job search results.
type JobListResponse struct {
	Items    []Job `json:"items"`
	Total    int64 `json:"total"`
	Page     int   `json:"page"`
	PageSize int   `json:"page_size"`
}

// ApplicationListResponse wraps paginated application results.
type ApplicationListResponse struct {
	Items    []JobApplication `json:"items"`
	Total    int64            `json:"total"`
	Page     int              `json:"page"`
	PageSize int              `json:"page_size"`
}

// InterviewListResponse wraps interview list results.
type InterviewListResponse struct {
	Items []Interview `json:"items"`
	Total int64       `json:"total"`
}

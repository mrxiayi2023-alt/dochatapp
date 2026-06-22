package repository

import (
	"dochatapp/server/internal/model"
	"gorm.io/gorm"
)

type JobRepo struct {
	db *gorm.DB
}

func NewJobRepo(db *gorm.DB) *JobRepo {
	return &JobRepo{db: db}
}

func (r *JobRepo) CreateJob(job *model.Job) error {
	return r.db.Create(job).Error
}

func (r *JobRepo) UpdateJob(job *model.Job) error {
	return r.db.Save(job).Error
}

func (r *JobRepo) DeleteJob(id, publisherID string) error {
	return r.db.Where("id = ? AND publisher_id = ?", id, publisherID).Delete(&model.Job{}).Error
}

func (r *JobRepo) FindJobByID(id string) (*model.Job, error) {
	var job model.Job
	err := r.db.Where("id = ?", id).First(&job).Error
	if err != nil {
		return nil, err
	}
	return &job, nil
}

// JobListParams holds filtering and pagination parameters for job listing.
type JobListParams struct {
	City        string
	District    string
	Education   string
	Experience  string
	SalaryRange string
	JobType     string
	Keyword     string
	CompanyID   string
	Page        int
	PageSize    int
}

// ListJobs returns paginated jobs matching the given filters.
func (r *JobRepo) ListJobs(params JobListParams) ([]model.Job, int64, error) {
	query := r.db.Model(&model.Job{}).Where("status = ?", "published")

	if params.City != "" {
		query = query.Where("city = ?", params.City)
	}
	if params.District != "" {
		query = query.Where("district = ?", params.District)
	}
	if params.Education != "" {
		query = query.Where("education = ?", params.Education)
	}
	if params.Experience != "" {
		query = query.Where("experience = ?", params.Experience)
	}
	if params.SalaryRange != "" {
		query = query.Where("salary_range = ?", params.SalaryRange)
	}
	if params.JobType != "" {
		query = query.Where("job_type = ?", params.JobType)
	}
	if params.CompanyID != "" {
		query = query.Where("company_id = ?", params.CompanyID)
	}
	if params.Keyword != "" {
		kw := "%" + params.Keyword + "%"
		query = query.Where("title ILIKE ? OR description ILIKE ?", kw, kw)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	page := params.Page
	if page < 1 {
		page = 1
	}
	pageSize := params.PageSize
	if pageSize < 1 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var jobs []model.Job
	err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&jobs).Error
	return jobs, total, err
}

// FindJobsByPublisher returns jobs published by a specific user.
func (r *JobRepo) FindJobsByPublisher(publisherID string) ([]model.Job, error) {
	var jobs []model.Job
	err := r.db.Where("publisher_id = ?", publisherID).Order("created_at DESC").Find(&jobs).Error
	return jobs, err
}

// ======================== CompanyRepo ========================

// CompanyRepo handles database operations for companies.
type CompanyRepo struct {
	db *gorm.DB
}

// NewCompanyRepo creates a new CompanyRepo.
func NewCompanyRepo(db *gorm.DB) *CompanyRepo {
	return &CompanyRepo{db: db}
}

// CreateCompany inserts a new company record.
func (r *CompanyRepo) CreateCompany(company *model.Company) error {
	return r.db.Create(company).Error
}

// UpdateCompany modifies an existing company.
func (r *CompanyRepo) UpdateCompany(company *model.Company) error {
	return r.db.Save(company).Error
}

// FindCompanyByUserID retrieves a company by its owner user ID.
func (r *CompanyRepo) FindCompanyByUserID(userID string) (*model.Company, error) {
	var company model.Company
	err := r.db.Where("user_id = ?", userID).First(&company).Error
	if err != nil {
		return nil, err
	}
	return &company, nil
}

// FindCompanyByID retrieves a company by ID.
func (r *CompanyRepo) FindCompanyByID(id string) (*model.Company, error) {
	var company model.Company
	err := r.db.Where("id = ?", id).First(&company).Error
	if err != nil {
		return nil, err
	}
	return &company, nil
}

// ======================== ResumeRepo ========================

// ResumeRepo handles database operations for resumes.
type ResumeRepo struct {
	db *gorm.DB
}

// NewResumeRepo creates a new ResumeRepo.
func NewResumeRepo(db *gorm.DB) *ResumeRepo {
	return &ResumeRepo{db: db}
}

// CreateResume inserts a new resume.
func (r *ResumeRepo) CreateResume(resume *model.Resume) error {
	return r.db.Create(resume).Error
}

// UpdateResume modifies an existing resume.
func (r *ResumeRepo) UpdateResume(resume *model.Resume) error {
	return r.db.Save(resume).Error
}

// FindResumeByUserID retrieves a resume by its owner user ID.
func (r *ResumeRepo) FindResumeByUserID(userID string) (*model.Resume, error) {
	var resume model.Resume
	err := r.db.Where("user_id = ?", userID).First(&resume).Error
	if err != nil {
		return nil, err
	}
	return &resume, nil
}

// FindResumeByID retrieves a resume by ID.
func (r *ResumeRepo) FindResumeByID(id string) (*model.Resume, error) {
	var resume model.Resume
	err := r.db.Where("id = ?", id).First(&resume).Error
	if err != nil {
		return nil, err
	}
	return &resume, nil
}

// ======================== ApplicationRepo ========================

// ApplicationRepo handles database operations for job applications.
type ApplicationRepo struct {
	db *gorm.DB
}

// NewApplicationRepo creates a new ApplicationRepo.
func NewApplicationRepo(db *gorm.DB) *ApplicationRepo {
	return &ApplicationRepo{db: db}
}

// CreateApplication inserts a new job application.
func (r *ApplicationRepo) CreateApplication(app *model.JobApplication) error {
	return r.db.Create(app).Error
}

// UpdateApplication modifies an application status.
func (r *ApplicationRepo) UpdateApplication(app *model.JobApplication) error {
	return r.db.Save(app).Error
}

// FindApplicationByID retrieves an application by ID.
func (r *ApplicationRepo) FindApplicationByID(id string) (*model.JobApplication, error) {
	var app model.JobApplication
	err := r.db.Where("id = ?", id).First(&app).Error
	if err != nil {
		return nil, err
	}
	return &app, nil
}

// FindApplicationsByUser returns all applications for a user with pagination.
func (r *ApplicationRepo) FindApplicationsByUser(userID string, page, pageSize int) ([]model.JobApplication, int64, error) {
	query := r.db.Model(&model.JobApplication{}).Where("user_id = ?", userID)

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

	var apps []model.JobApplication
	err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&apps).Error
	return apps, total, err
}

// FindApplicationsByJob returns all applications for a job.
func (r *ApplicationRepo) FindApplicationsByJob(jobID string) ([]model.JobApplication, error) {
	var apps []model.JobApplication
	err := r.db.Where("job_id = ?", jobID).Order("created_at DESC").Find(&apps).Error
	return apps, err
}

// FindApplicationByUserAndJob checks if a user already applied.
func (r *ApplicationRepo) FindApplicationByUserAndJob(userID, jobID string) (*model.JobApplication, error) {
	var app model.JobApplication
	err := r.db.Where("user_id = ? AND job_id = ?", userID, jobID).First(&app).Error
	if err != nil {
		return nil, err
	}
	return &app, nil
}

// ======================== InterviewRepo ========================

// InterviewRepo handles database operations for interviews.
type InterviewRepo struct {
	db *gorm.DB
}

// NewInterviewRepo creates a new InterviewRepo.
func NewInterviewRepo(db *gorm.DB) *InterviewRepo {
	return &InterviewRepo{db: db}
}

// CreateInterview inserts a new interview record.
func (r *InterviewRepo) CreateInterview(interview *model.Interview) error {
	return r.db.Create(interview).Error
}

// UpdateInterview modifies an interview record.
func (r *InterviewRepo) UpdateInterview(interview *model.Interview) error {
	return r.db.Save(interview).Error
}

// FindInterviewByID retrieves an interview by ID.
func (r *InterviewRepo) FindInterviewByID(id string) (*model.Interview, error) {
	var interview model.Interview
	err := r.db.Where("id = ?", id).First(&interview).Error
	if err != nil {
		return nil, err
	}
	return &interview, nil
}

// FindInterviewsByUser returns all interviews for a user.
func (r *InterviewRepo) FindInterviewsByUser(userID string) ([]model.Interview, int64, error) {
	var interviews []model.Interview
	var total int64
	query := r.db.Model(&model.Interview{}).Where("user_id = ?", userID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Order("interview_time DESC").Find(&interviews).Error
	return interviews, total, err
}

// FindInterviewsByCompany returns all interviews for a company.
func (r *InterviewRepo) FindInterviewsByCompany(companyID string) ([]model.Interview, int64, error) {
	var interviews []model.Interview
	var total int64
	query := r.db.Model(&model.Interview{}).Where("company_id = ?", companyID)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := query.Order("interview_time DESC").Find(&interviews).Error
	return interviews, total, err
}

// ======================== JobFavoriteRepo ========================

// JobFavoriteRepo handles database operations for job favorites.
type JobFavoriteRepo struct {
	db *gorm.DB
}

// NewJobFavoriteRepo creates a new JobFavoriteRepo.
func NewJobFavoriteRepo(db *gorm.DB) *JobFavoriteRepo {
	return &JobFavoriteRepo{db: db}
}

// AddFavorite adds a job to user favorites.
func (r *JobFavoriteRepo) AddFavorite(fav *model.JobFavorite) error {
	return r.db.Create(fav).Error
}

// RemoveFavorite removes a job from user favorites.
func (r *JobFavoriteRepo) RemoveFavorite(userID, jobID string) error {
	return r.db.Where("user_id = ? AND job_id = ?", userID, jobID).Delete(&model.JobFavorite{}).Error
}

// IsFavorited checks if a user has favorited a job.
func (r *JobFavoriteRepo) IsFavorited(userID, jobID string) (bool, error) {
	var count int64
	err := r.db.Model(&model.JobFavorite{}).Where("user_id = ? AND job_id = ?", userID, jobID).Count(&count).Error
	return count > 0, err
}

// GetFavorites returns a user's favorited job IDs.
func (r *JobFavoriteRepo) GetFavorites(userID string) ([]model.JobFavorite, error) {
	var favs []model.JobFavorite
	err := r.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&favs).Error
	return favs, err
}

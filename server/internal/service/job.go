package service

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：招聘求职业务逻辑

import (
	"errors"
	"time"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"

	"gorm.io/gorm"
)

// JobService handles job-related business logic.
type JobService struct {
	jobRepo         *repository.JobRepo
	companyRepo     *repository.CompanyRepo
	resumeRepo      *repository.ResumeRepo
	applicationRepo *repository.ApplicationRepo
	interviewRepo   *repository.InterviewRepo
	favoriteRepo    *repository.JobFavoriteRepo
}

// NewJobService creates a new JobService.
func NewJobService(
	jobRepo *repository.JobRepo,
	companyRepo *repository.CompanyRepo,
	resumeRepo *repository.ResumeRepo,
	applicationRepo *repository.ApplicationRepo,
	interviewRepo *repository.InterviewRepo,
	favoriteRepo *repository.JobFavoriteRepo,
) *JobService {
	return &JobService{
		jobRepo:         jobRepo,
		companyRepo:     companyRepo,
		resumeRepo:      resumeRepo,
		applicationRepo: applicationRepo,
		interviewRepo:   interviewRepo,
		favoriteRepo:    favoriteRepo,
	}
}

// ======================== Request Types ========================

// PublishJobRequest is the payload for publishing a job.
type PublishJobRequest struct {
	CompanyID    string `json:"company_id" binding:"required"`
	Title        string `json:"title" binding:"required"`
	Description  string `json:"description"`
	Requirements string `json:"requirements"`
	SalaryRange  string `json:"salary_range"`
	Location     string `json:"location"`
	City         string `json:"city" binding:"required"`
	District     string `json:"district"`
	Education    string `json:"education"`
	Experience   string `json:"experience"`
	JobType      string `json:"job_type"`
	Openings     int    `json:"openings"`
}

// JobListRequest is the payload for listing jobs.
type JobListRequest struct {
	City        string `form:"city"`
	District    string `form:"district"`
	Education   string `form:"education"`
	Experience  string `form:"experience"`
	SalaryRange string `form:"salary_range"`
	JobType     string `form:"job_type"`
	Keyword     string `form:"keyword"`
	CompanyID   string `form:"company_id"`
	Page        int    `form:"page"`
	PageSize    int    `form:"page_size"`
}

// RegisterCompanyRequest is the payload for registering a company.
type RegisterCompanyRequest struct {
	Name         string `json:"name" binding:"required"`
	Description  string `json:"description"`
	Industry     string `json:"industry"`
	Scale        string `json:"scale"`
	Address      string `json:"address"`
	City         string `json:"city"`
	District     string `json:"district"`
	Logo         string `json:"logo"`
	ContactPhone string `json:"contact_phone"`
	ContactName  string `json:"contact_name"`
}

// CreateResumeRequest is the payload for creating/updating a resume.
type CreateResumeRequest struct {
	Name             string `json:"name" binding:"required"`
	Gender           string `json:"gender"`
	Age              int    `json:"age"`
	Education        string `json:"education"`
	Experience       string `json:"experience"`
	Skills           string `json:"skills"`
	Introduction     string `json:"introduction"`
	Phone            string `json:"phone"`
	Email            string `json:"email"`
	CurrentStatus    string `json:"current_status"`
	AvailableTime    string `json:"available_time"`
	ExpectedSalary   string `json:"expected_salary"`
	ExpectedCity     string `json:"expected_city"`
	ExpectedDistrict string `json:"expected_district"`
	JobType          string `json:"job_type"`
}

// ApplyJobRequest is the payload for applying to a job.
type ApplyJobRequest struct {
	JobID    string `json:"job_id" binding:"required"`
	ResumeID string `json:"resume_id" binding:"required"`
}

// UpdateApplicationRequest is the payload for updating application status.
type UpdateApplicationRequest struct {
	Status string `json:"status" binding:"required"`
}

// ScheduleInterviewRequest is the payload for scheduling an interview.
type ScheduleInterviewRequest struct {
	ApplicationID string    `json:"application_id" binding:"required"`
	JobID         string    `json:"job_id" binding:"required"`
	CompanyID     string    `json:"company_id" binding:"required"`
	UserID        string    `json:"user_id" binding:"required"`
	InterviewTime time.Time `json:"interview_time" binding:"required"`
	Location      string    `json:"location"`
	Remark        string    `json:"remark"`
}

// UpdateInterviewRequest is the payload for updating an interview.
type UpdateInterviewRequest struct {
	InterviewTime time.Time `json:"interview_time"`
	Location      string    `json:"location"`
	Status        string    `json:"status"`
	Remark        string    `json:"remark"`
}

// ======================== Service Methods ========================

// PublishJob creates a new job posting.
func (s *JobService) PublishJob(publisherID string, req *PublishJobRequest) (*model.Job, error) {
	company, err := s.companyRepo.FindCompanyByID(req.CompanyID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("company not found")
		}
		return nil, errors.New("database error")
	}
	if company.UserID != publisherID {
		return nil, errors.New("not authorized to publish for this company")
	}

	job := &model.Job{
		CompanyID:    req.CompanyID,
		Title:        req.Title,
		Description:  req.Description,
		Requirements: req.Requirements,
		SalaryRange:  req.SalaryRange,
		Location:     req.Location,
		City:         req.City,
		District:     req.District,
		Education:    req.Education,
		Experience:   req.Experience,
		JobType:      req.JobType,
		Openings:     req.Openings,
		PublisherID:  publisherID,
		Status:       "published",
	}
	if err := s.jobRepo.CreateJob(job); err != nil {
		return nil, errors.New("failed to create job")
	}
	return job, nil
}

// UpdateJob modifies an existing job posting.
func (s *JobService) UpdateJob(publisherID, jobID string, req *PublishJobRequest) (*model.Job, error) {
	job, err := s.jobRepo.FindJobByID(jobID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("job not found")
		}
		return nil, errors.New("database error")
	}
	if job.PublisherID != publisherID {
		return nil, errors.New("not authorized to edit this job")
	}

	job.CompanyID = req.CompanyID
	job.Title = req.Title
	job.Description = req.Description
	job.Requirements = req.Requirements
	job.SalaryRange = req.SalaryRange
	job.Location = req.Location
	job.City = req.City
	job.District = req.District
	job.Education = req.Education
	job.Experience = req.Experience
	job.JobType = req.JobType
	job.Openings = req.Openings

	if err := s.jobRepo.UpdateJob(job); err != nil {
		return nil, errors.New("failed to update job")
	}
	return job, nil
}

// DeleteJob removes a job posting.
func (s *JobService) DeleteJob(publisherID, jobID string) error {
	job, err := s.jobRepo.FindJobByID(jobID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("job not found")
		}
		return errors.New("database error")
	}
	if job.PublisherID != publisherID {
		return errors.New("not authorized to delete this job")
	}
	return s.jobRepo.DeleteJob(jobID, publisherID)
}

// ListJobs returns paginated jobs with filters.
func (s *JobService) ListJobs(req *JobListRequest) (*model.JobListResponse, error) {
	params := repository.JobListParams{
		City:        req.City,
		District:    req.District,
		Education:   req.Education,
		Experience:  req.Experience,
		SalaryRange: req.SalaryRange,
		JobType:     req.JobType,
		Keyword:     req.Keyword,
		CompanyID:   req.CompanyID,
		Page:        req.Page,
		PageSize:    req.PageSize,
	}

	items, total, err := s.jobRepo.ListJobs(params)
	if err != nil {
		return nil, errors.New("failed to query jobs")
	}

	page := req.Page
	if page < 1 {
		page = 1
	}
	pageSize := req.PageSize
	if pageSize < 1 {
		pageSize = 20
	}

	return &model.JobListResponse{
		Items:    items,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// GetJobDetail returns a job by ID with favorite status.
func (s *JobService) GetJobDetail(userID, jobID string) (*model.Job, *model.Company, bool, error) {
	job, err := s.jobRepo.FindJobByID(jobID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil, false, errors.New("job not found")
		}
		return nil, nil, false, errors.New("database error")
	}

	favorited, _ := s.favoriteRepo.IsFavorited(userID, jobID)
	company, err := s.companyRepo.FindCompanyByID(job.CompanyID)
	if err != nil {
		company = nil
	}

	return job, company, favorited, nil
}

// ToggleJobFavorite adds or removes a job favorite.
func (s *JobService) ToggleJobFavorite(userID, jobID string, add bool) error {
	if add {
		return s.favoriteRepo.AddFavorite(&model.JobFavorite{
			UserID: userID,
			JobID:  jobID,
		})
	}
	return s.favoriteRepo.RemoveFavorite(userID, jobID)
}

// GetJobFavorites returns a user's favorited jobs.
func (s *JobService) GetJobFavorites(userID string) ([]model.Job, error) {
	favs, err := s.favoriteRepo.GetFavorites(userID)
	if err != nil {
		return nil, errors.New("failed to get favorites")
	}

	var result []model.Job
	for _, f := range favs {
		job, err := s.jobRepo.FindJobByID(f.JobID)
		if err == nil {
			result = append(result, *job)
		}
	}

	return result, nil
}

// ApplyJob submits a job application.
func (s *JobService) ApplyJob(userID string, req *ApplyJobRequest) (*model.JobApplication, error) {
	_, err := s.jobRepo.FindJobByID(req.JobID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("job not found")
		}
		return nil, errors.New("database error")
	}

	resume, err := s.resumeRepo.FindResumeByID(req.ResumeID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("resume not found")
		}
		return nil, errors.New("database error")
	}
	if resume.UserID != userID {
		return nil, errors.New("resume does not belong to you")
	}

	existing, _ := s.applicationRepo.FindApplicationByUserAndJob(userID, req.JobID)
	if existing != nil {
		return nil, errors.New("already applied to this job")
	}

	app := &model.JobApplication{
		JobID:    req.JobID,
		UserID:   userID,
		ResumeID: req.ResumeID,
		Status:   "pending",
	}
	if err := s.applicationRepo.CreateApplication(app); err != nil {
		return nil, errors.New("failed to submit application")
	}
	return app, nil
}

// GetMyApplications returns a user's job applications.
func (s *JobService) GetMyApplications(userID string, page, pageSize int) (*model.ApplicationListResponse, error) {
	items, total, err := s.applicationRepo.FindApplicationsByUser(userID, page, pageSize)
	if err != nil {
		return nil, errors.New("failed to get applications")
	}

	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}

	return &model.ApplicationListResponse{
		Items:    items,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// GetJobApplications returns applications for a specific job.
func (s *JobService) GetJobApplications(jobID string) ([]model.JobApplication, error) {
	return s.applicationRepo.FindApplicationsByJob(jobID)
}

// UpdateApplicationStatus updates an application's status.
func (s *JobService) UpdateApplicationStatus(publisherID, applicationID string, status string) (*model.JobApplication, error) {
	app, err := s.applicationRepo.FindApplicationByID(applicationID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("application not found")
		}
		return nil, errors.New("database error")
	}

	job, err := s.jobRepo.FindJobByID(app.JobID)
	if err != nil || job.PublisherID != publisherID {
		return nil, errors.New("not authorized")
	}

	app.Status = status
	if err := s.applicationRepo.UpdateApplication(app); err != nil {
		return nil, errors.New("failed to update application")
	}
	return app, nil
}

// RegisterCompany creates a new company profile.
func (s *JobService) RegisterCompany(userID string, req *RegisterCompanyRequest) (*model.Company, error) {
	existing, _ := s.companyRepo.FindCompanyByUserID(userID)
	if existing != nil {
		return nil, errors.New("you already have a company profile")
	}

	company := &model.Company{
		UserID:       userID,
		Name:         req.Name,
		Description:  req.Description,
		Industry:     req.Industry,
		Scale:        req.Scale,
		Address:      req.Address,
		City:         req.City,
		District:     req.District,
		Logo:         req.Logo,
		ContactPhone: req.ContactPhone,
		ContactName:  req.ContactName,
		Status:       "active",
	}
	if err := s.companyRepo.CreateCompany(company); err != nil {
		return nil, errors.New("failed to create company")
	}
	return company, nil
}

// UpdateCompany modifies a company profile.
func (s *JobService) UpdateCompany(userID string, req *RegisterCompanyRequest) (*model.Company, error) {
	company, err := s.companyRepo.FindCompanyByUserID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("company not found")
		}
		return nil, errors.New("database error")
	}

	company.Name = req.Name
	company.Description = req.Description
	company.Industry = req.Industry
	company.Scale = req.Scale
	company.Address = req.Address
	company.City = req.City
	company.District = req.District
	company.Logo = req.Logo
	company.ContactPhone = req.ContactPhone
	company.ContactName = req.ContactName

	if err := s.companyRepo.UpdateCompany(company); err != nil {
		return nil, errors.New("failed to update company")
	}
	return company, nil
}

// GetCompanyProfile returns the company profile for a user.
func (s *JobService) GetCompanyProfile(userID string) (*model.Company, error) {
	company, err := s.companyRepo.FindCompanyByUserID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("company not found")
		}
		return nil, errors.New("database error")
	}
	return company, nil
}

// GetCompanyByID returns a company by ID.
func (s *JobService) GetCompanyByID(id string) (*model.Company, error) {
	company, err := s.companyRepo.FindCompanyByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("company not found")
		}
		return nil, errors.New("database error")
	}
	return company, nil
}

// CreateResume creates a new resume.
func (s *JobService) CreateResume(userID string, req *CreateResumeRequest) (*model.Resume, error) {
	existing, _ := s.resumeRepo.FindResumeByUserID(userID)
	if existing != nil {
		return nil, errors.New("you already have a resume, use update instead")
	}

	resume := &model.Resume{
		UserID:           userID,
		Name:             req.Name,
		Gender:           req.Gender,
		Age:              req.Age,
		Education:        req.Education,
		Experience:       req.Experience,
		Skills:           req.Skills,
		Introduction:     req.Introduction,
		Phone:            req.Phone,
		Email:            req.Email,
		CurrentStatus:    req.CurrentStatus,
		AvailableTime:    req.AvailableTime,
		ExpectedSalary:   req.ExpectedSalary,
		ExpectedCity:     req.ExpectedCity,
		ExpectedDistrict: req.ExpectedDistrict,
		JobType:          req.JobType,
	}
	if err := s.resumeRepo.CreateResume(resume); err != nil {
		return nil, errors.New("failed to create resume")
	}
	return resume, nil
}

// UpdateResume modifies an existing resume.
func (s *JobService) UpdateResume(userID string, req *CreateResumeRequest) (*model.Resume, error) {
	resume, err := s.resumeRepo.FindResumeByUserID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("resume not found")
		}
		return nil, errors.New("database error")
	}

	resume.Name = req.Name
	resume.Gender = req.Gender
	resume.Age = req.Age
	resume.Education = req.Education
	resume.Experience = req.Experience
	resume.Skills = req.Skills
	resume.Introduction = req.Introduction
	resume.Phone = req.Phone
	resume.Email = req.Email
	resume.CurrentStatus = req.CurrentStatus
	resume.AvailableTime = req.AvailableTime
	resume.ExpectedSalary = req.ExpectedSalary
	resume.ExpectedCity = req.ExpectedCity
	resume.ExpectedDistrict = req.ExpectedDistrict
	resume.JobType = req.JobType

	if err := s.resumeRepo.UpdateResume(resume); err != nil {
		return nil, errors.New("failed to update resume")
	}
	return resume, nil
}

// GetMyResume returns the user's own resume.
func (s *JobService) GetMyResume(userID string) (*model.Resume, error) {
	resume, err := s.resumeRepo.FindResumeByUserID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("resume not found")
		}
		return nil, errors.New("database error")
	}
	return resume, nil
}

// GetResumeByID returns a resume by ID.
func (s *JobService) GetResumeByID(id string) (*model.Resume, error) {
	resume, err := s.resumeRepo.FindResumeByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("resume not found")
		}
		return nil, errors.New("database error")
	}
	return resume, nil
}

// ScheduleInterview creates a new interview record.
func (s *JobService) ScheduleInterview(req *ScheduleInterviewRequest) (*model.Interview, error) {
	interview := &model.Interview{
		ApplicationID: req.ApplicationID,
		JobID:         req.JobID,
		CompanyID:     req.CompanyID,
		UserID:        req.UserID,
		InterviewTime: req.InterviewTime,
		Location:      req.Location,
		Status:        "scheduled",
		Remark:        req.Remark,
	}
	if err := s.interviewRepo.CreateInterview(interview); err != nil {
		return nil, errors.New("failed to schedule interview")
	}
	return interview, nil
}

// UpdateInterview modifies an interview record.
func (s *JobService) UpdateInterview(interviewID string, req *UpdateInterviewRequest) (*model.Interview, error) {
	interview, err := s.interviewRepo.FindInterviewByID(interviewID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("interview not found")
		}
		return nil, errors.New("database error")
	}

	if !req.InterviewTime.IsZero() {
		interview.InterviewTime = req.InterviewTime
	}
	if req.Location != "" {
		interview.Location = req.Location
	}
	if req.Status != "" {
		interview.Status = req.Status
	}
	if req.Remark != "" {
		interview.Remark = req.Remark
	}

	if err := s.interviewRepo.UpdateInterview(interview); err != nil {
		return nil, errors.New("failed to update interview")
	}
	return interview, nil
}

// GetMyInterviews returns interviews for the current user.
func (s *JobService) GetMyInterviews(userID string) (*model.InterviewListResponse, error) {
	interviews, total, err := s.interviewRepo.FindInterviewsByUser(userID)
	if err != nil {
		return nil, errors.New("failed to get interviews")
	}
	return &model.InterviewListResponse{
		Items: interviews,
		Total: total,
	}, nil
}

// GetCompanyInterviews returns interviews for a company.
func (s *JobService) GetCompanyInterviews(companyID string) (*model.InterviewListResponse, error) {
	interviews, total, err := s.interviewRepo.FindInterviewsByCompany(companyID)
	if err != nil {
		return nil, errors.New("failed to get interviews")
	}
	return &model.InterviewListResponse{
		Items: interviews,
		Total: total,
	}, nil
}

// GetMyJobs returns jobs published by the current user.
func (s *JobService) GetMyJobs(userID string) ([]model.Job, error) {
	return s.jobRepo.FindJobsByPublisher(userID)
}

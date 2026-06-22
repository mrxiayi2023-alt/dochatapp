package handler

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：招聘求职HTTP处理器

import (
	"net/http"
	"strconv"

	"dochatapp/server/internal/service"
	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
)

// JobHandler handles job-related HTTP requests.
type JobHandler struct {
	svc *service.JobService
}

// NewJobHandler creates a new JobHandler.
func NewJobHandler(svc *service.JobService) *JobHandler {
	return &JobHandler{svc: svc}
}

// PublishJob handles POST /api/jobs/publish.
func (h *JobHandler) PublishJob(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.PublishJobRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	job, err := h.svc.PublishJob(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, job)
}

// UpdateJob handles PUT /api/jobs/:id.
func (h *JobHandler) UpdateJob(c *gin.Context) {
	userID, _ := c.Get("userID")
	jobID := c.Param("id")

	var req service.PublishJobRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	job, err := h.svc.UpdateJob(userID.(string), jobID, &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, job)
}

// DeleteJob handles DELETE /api/jobs/:id.
func (h *JobHandler) DeleteJob(c *gin.Context) {
	userID, _ := c.Get("userID")
	jobID := c.Param("id")

	if err := h.svc.DeleteJob(userID.(string), jobID); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "job deleted"})
}

// ListJobs handles GET /api/jobs/list.
func (h *JobHandler) ListJobs(c *gin.Context) {
	var req service.JobListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid query: "+err.Error())
		return
	}

	result, err := h.svc.ListJobs(&req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// GetJobDetail handles GET /api/jobs/:id.
func (h *JobHandler) GetJobDetail(c *gin.Context) {
	userID, _ := c.Get("userID")
	jobID := c.Param("id")

	job, company, favorited, err := h.svc.GetJobDetail(userID.(string), jobID)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, gin.H{
		"job":       job,
		"company":   company,
		"favorited": favorited,
	})
}

// AddJobFavorite handles POST /api/jobs/:id/favorite.
func (h *JobHandler) AddJobFavorite(c *gin.Context) {
	userID, _ := c.Get("userID")
	jobID := c.Param("id")

	if err := h.svc.ToggleJobFavorite(userID.(string), jobID, true); err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to add favorite")
		return
	}

	response.Success(c, gin.H{"message": "favorited"})
}

// RemoveJobFavorite handles DELETE /api/jobs/:id/favorite.
func (h *JobHandler) RemoveJobFavorite(c *gin.Context) {
	userID, _ := c.Get("userID")
	jobID := c.Param("id")

	if err := h.svc.ToggleJobFavorite(userID.(string), jobID, false); err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to remove favorite")
		return
	}

	response.Success(c, gin.H{"message": "unfavorited"})
}

// GetJobFavorites handles GET /api/jobs/favorites.
func (h *JobHandler) GetJobFavorites(c *gin.Context) {
	userID, _ := c.Get("userID")

	jobs, err := h.svc.GetJobFavorites(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, jobs)
}

// ApplyJob handles POST /api/jobs/apply.
func (h *JobHandler) ApplyJob(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.ApplyJobRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	app, err := h.svc.ApplyJob(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, app)
}

// GetMyApplications handles GET /api/jobs/applications.
func (h *JobHandler) GetMyApplications(c *gin.Context) {
	userID, _ := c.Get("userID")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	result, err := h.svc.GetMyApplications(userID.(string), page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// GetJobApplications handles GET /api/jobs/:id/applications.
func (h *JobHandler) GetJobApplications(c *gin.Context) {
	jobID := c.Param("id")

	apps, err := h.svc.GetJobApplications(jobID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, apps)
}

// UpdateApplicationStatus handles PUT /api/jobs/applications/:id.
func (h *JobHandler) UpdateApplicationStatus(c *gin.Context) {
	userID, _ := c.Get("userID")
	appID := c.Param("id")

	var req service.UpdateApplicationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	app, err := h.svc.UpdateApplicationStatus(userID.(string), appID, req.Status)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, app)
}

// RegisterCompany handles POST /api/company/register.
func (h *JobHandler) RegisterCompany(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.RegisterCompanyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	company, err := h.svc.RegisterCompany(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, company)
}

// UpdateCompany handles PUT /api/company/profile.
func (h *JobHandler) UpdateCompany(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.RegisterCompanyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	company, err := h.svc.UpdateCompany(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, company)
}

// GetCompanyProfile handles GET /api/company/profile.
func (h *JobHandler) GetCompanyProfile(c *gin.Context) {
	userID, _ := c.Get("userID")

	company, err := h.svc.GetCompanyProfile(userID.(string))
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, company)
}

// GetCompanyByID handles GET /api/company/:id.
func (h *JobHandler) GetCompanyByID(c *gin.Context) {
	id := c.Param("id")

	company, err := h.svc.GetCompanyByID(id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, company)
}

// CreateResume handles POST /api/resume/create.
func (h *JobHandler) CreateResume(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.CreateResumeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	resume, err := h.svc.CreateResume(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, resume)
}

// UpdateResume handles PUT /api/resume/update.
func (h *JobHandler) UpdateResume(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.CreateResumeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	resume, err := h.svc.UpdateResume(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, resume)
}

// GetMyResume handles GET /api/resume/my.
func (h *JobHandler) GetMyResume(c *gin.Context) {
	userID, _ := c.Get("userID")

	resume, err := h.svc.GetMyResume(userID.(string))
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, resume)
}

// GetResumeByID handles GET /api/resume/:id.
func (h *JobHandler) GetResumeByID(c *gin.Context) {
	id := c.Param("id")

	resume, err := h.svc.GetResumeByID(id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, resume)
}

// ScheduleInterview handles POST /api/interview/schedule.
func (h *JobHandler) ScheduleInterview(c *gin.Context) {
	var req service.ScheduleInterviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	interview, err := h.svc.ScheduleInterview(&req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, interview)
}

// UpdateInterview handles PUT /api/interview/:id.
func (h *JobHandler) UpdateInterview(c *gin.Context) {
	id := c.Param("id")

	var req service.UpdateInterviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	interview, err := h.svc.UpdateInterview(id, &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, interview)
}

// GetMyInterviews handles GET /api/interview/list.
func (h *JobHandler) GetMyInterviews(c *gin.Context) {
	userID, _ := c.Get("userID")

	result, err := h.svc.GetMyInterviews(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// GetCompanyInterviews handles GET /api/interview/company.
func (h *JobHandler) GetCompanyInterviews(c *gin.Context) {
	companyID := c.Query("company_id")
	if companyID == "" {
		response.Error(c, http.StatusBadRequest, "missing company_id")
		return
	}

	result, err := h.svc.GetCompanyInterviews(companyID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// GetMyJobs handles GET /api/jobs/my.
func (h *JobHandler) GetMyJobs(c *gin.Context) {
	userID, _ := c.Get("userID")

	jobs, err := h.svc.GetMyJobs(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, jobs)
}

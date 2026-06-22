package handler

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：婚恋HTTP处理器

import (
	"net/http"
	"strconv"

	"dochatapp/server/internal/service"
	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
)

// DatingHandler handles dating-related HTTP requests.
type DatingHandler struct {
	svc *service.DatingService
}

// NewDatingHandler creates a new DatingHandler.
func NewDatingHandler(svc *service.DatingService) *DatingHandler {
	return &DatingHandler{svc: svc}
}

// SaveProfile handles POST /api/dating/profile.
func (h *DatingHandler) SaveProfile(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.SaveProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	profile, err := h.svc.SaveProfile(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, profile)
}

// GetProfile handles GET /api/dating/profile.
func (h *DatingHandler) GetProfile(c *gin.Context) {
	userID, _ := c.Get("userID")

	profile, err := h.svc.GetProfile(userID.(string))
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, profile)
}

// GetProfileByID handles GET /api/dating/profile/:id.
func (h *DatingHandler) GetProfileByID(c *gin.Context) {
	userID, _ := c.Get("userID")
	profileUserID := c.Param("id")

	profile, liked, err := h.svc.GetProfileByID(userID.(string), profileUserID)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, gin.H{
		"profile": profile,
		"liked":   liked,
	})
}

// Recommend handles GET /api/dating/recommend.
func (h *DatingHandler) Recommend(c *gin.Context) {
	userID, _ := c.Get("userID")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	gender := c.Query("gender")
	ageMin, _ := strconv.Atoi(c.DefaultQuery("age_min", "0"))
	ageMax, _ := strconv.Atoi(c.DefaultQuery("age_max", "0"))

	result, err := h.svc.Recommend(userID.(string), page, pageSize, gender, ageMin, ageMax)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// Like handles POST /api/dating/like.
func (h *DatingHandler) Like(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.LikeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if err := h.svc.Like(userID.(string), &req); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "ok"})
}

// GetMatches handles GET /api/dating/matches.
func (h *DatingHandler) GetMatches(c *gin.Context) {
	userID, _ := c.Get("userID")

	profiles, err := h.svc.GetMatches(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, profiles)
}

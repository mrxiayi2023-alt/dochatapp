package handler

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：房源租赁HTTP处理器

import (
	"net/http"
	"strconv"

	"dochatapp/server/internal/service"
	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
)

// HousingHandler handles housing-related HTTP requests.
type HousingHandler struct {
	svc *service.HousingService
}

// NewHousingHandler creates a new HousingHandler.
func NewHousingHandler(svc *service.HousingService) *HousingHandler {
	return &HousingHandler{svc: svc}
}

// Publish handles POST /api/housing/publish.
func (h *HousingHandler) Publish(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.PublishRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	listing, err := h.svc.Publish(userID.(string), &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, listing)
}

// Update handles PUT /api/housing/:id.
func (h *HousingHandler) Update(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	var req service.PublishRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	listing, err := h.svc.Update(userID.(string), id, &req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, listing)
}

// Delete handles DELETE /api/housing/:id.
func (h *HousingHandler) Delete(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	if err := h.svc.Delete(userID.(string), id); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, gin.H{"message": "listing deleted"})
}

// List handles GET /api/housing/list.
func (h *HousingHandler) List(c *gin.Context) {
	var req service.ListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid query: "+err.Error())
		return
	}

	result, err := h.svc.List(&req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, result)
}

// Detail handles GET /api/housing/:id.
func (h *HousingHandler) Detail(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	listing, favorited, err := h.svc.Detail(userID.(string), id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, gin.H{
		"listing":   listing,
		"favorited": favorited,
	})
}

// AddFavorite handles POST /api/housing/:id/favorite.
func (h *HousingHandler) AddFavorite(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	if err := h.svc.ToggleFavorite(userID.(string), id, true); err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to add favorite")
		return
	}

	response.Success(c, gin.H{"message": "favorited"})
}

// RemoveFavorite handles DELETE /api/housing/:id/favorite.
func (h *HousingHandler) RemoveFavorite(c *gin.Context) {
	userID, _ := c.Get("userID")
	id := c.Param("id")

	if err := h.svc.ToggleFavorite(userID.(string), id, false); err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to remove favorite")
		return
	}

	response.Success(c, gin.H{"message": "unfavorited"})
}

// GetFavorites handles GET /api/housing/favorites.
func (h *HousingHandler) GetFavorites(c *gin.Context) {
	userID, _ := c.Get("userID")

	listings, err := h.svc.GetFavorites(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, listings)
}

// GetBrowseHistory handles GET /api/housing/history.
func (h *HousingHandler) GetBrowseHistory(c *gin.Context) {
	userID, _ := c.Get("userID")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	history, err := h.svc.GetBrowseHistory(userID.(string), limit)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, history)
}

// GetMyListings handles GET /api/housing/my.
func (h *HousingHandler) GetMyListings(c *gin.Context) {
	userID, _ := c.Get("userID")

	listings, err := h.svc.GetMyListings(userID.(string))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, listings)
}

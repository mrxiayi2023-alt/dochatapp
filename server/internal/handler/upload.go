package handler

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：文件上传HTTP处理器

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"dochatapp/server/pkg/response"

	"github.com/gin-gonic/gin"
)

const uploadDir = "uploads"

// UploadHandler handles file upload requests.
type UploadHandler struct{}

// NewUploadHandler creates a new UploadHandler and ensures upload directory exists.
func NewUploadHandler() *UploadHandler {
	os.MkdirAll(uploadDir, 0755)
	return &UploadHandler{}
}

// UploadImage handles POST /api/upload/image.
func (h *UploadHandler) UploadImage(c *gin.Context) {
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "missing file")
		return
	}
	defer file.Close()

	ext := filepath.Ext(header.Filename)
	if ext == "" {
		ext = ".jpg"
	}
	filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	dst := filepath.Join(uploadDir, filename)

	out, err := os.Create(dst)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to save file")
		return
	}
	defer out.Close()

	if _, err := io.Copy(out, file); err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to write file")
		return
	}

	response.Success(c, gin.H{
		"url":      "/uploads/" + filename,
		"filename": filename,
	})
}

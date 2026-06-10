package response

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：统一API响应格式



import "github.com/gin-gonic/gin"

// Response is the unified API response format.
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// Success sends a 200 success response.
func Success(c *gin.Context, data interface{}) {
	c.JSON(200, Response{
		Code:    200,
		Message: "success",
		Data:    data,
	})
}

// Error sends an error response with the given HTTP status and message.
func Error(c *gin.Context, httpStatus int, message string) {
	c.JSON(httpStatus, Response{
		Code:    httpStatus,
		Message: message,
		Data:    nil,
	})
}

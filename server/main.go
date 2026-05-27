package main

import (
	"fmt"
	"log"

	"dochatapp/server/config"
	"dochatapp/server/internal/handler"
	"dochatapp/server/internal/middleware"
	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"
	"dochatapp/server/internal/service"
	"dochatapp/server/internal/websocket"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	cfg := config.Load()

	// Connect to PostgreSQL
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable TimeZone=Asia/Shanghai",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName,
	)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("failed to connect database: %v", err)
	}
	log.Println("PostgreSQL connected successfully")

	// Auto-migrate
	if err := db.AutoMigrate(&model.User{}); err != nil {
		log.Fatalf("failed to migrate database: %v", err)
	}
	log.Println("Database migration completed")

	// Initialize layers
	userRepo := repository.NewUserRepository(db)
	authSvc := service.NewAuthService(userRepo, cfg.JWTSecret)
	authHdr := handler.NewAuthHandler(authSvc)

	// WebSocket hub
	hub := websocket.NewHub()

	// Gin engine
	r := gin.Default()

	// CORS middleware
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// Public routes
	api := r.Group("/api")
	{
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHdr.Register)
			auth.POST("/login", authHdr.Login)
		}
	}

	// Protected routes
	protected := api.Group("/user")
	protected.Use(middleware.JWTAuth(cfg.JWTSecret))
	{
		protected.GET("/profile", authHdr.Profile)
	}

	// WebSocket route
	r.GET("/ws", func(c *gin.Context) {
		// In production, extract userID from query param or JWT
		userID := c.Query("user_id")
		if userID == "" {
			userID = "anonymous"
		}
		hub.HandleWebSocket(c.Writer, c.Request, userID)
	})

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	addr := ":" + cfg.ServerPort
	log.Printf("Server starting on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("failed to start server: %v", err)
	}
}

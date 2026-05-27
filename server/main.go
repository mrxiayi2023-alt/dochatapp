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
	if err := db.AutoMigrate(&model.User{}, &model.Message{}); err != nil {
		log.Fatalf("failed to migrate database: %v", err)
	}
	log.Println("Database migration completed")

	// WebSocket hub
	hub := websocket.NewHub()
	go hub.Run()

	// Initialize layers
	userRepo := repository.NewUserRepository(db)
	msgRepo := repository.NewMessageRepository(db)
	authSvc := service.NewAuthService(userRepo, cfg.JWTSecret)
	msgSvc := service.NewMessageService(msgRepo, hub)
	authHdr := handler.NewAuthHandler(authSvc)
	msgHdr := handler.NewMessageHandler(msgSvc)

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
	jwt := middleware.JWTAuth(cfg.JWTSecret)
	protected := api.Group("/user")
	protected.Use(jwt)
	{
		protected.GET("/profile", authHdr.Profile)
		protected.GET("/search", authHdr.SearchUser)
	}

	// Message routes (protected)
	msgs := api.Group("/messages")
	msgs.Use(jwt)
	{
		msgs.POST("/send", msgHdr.Send)
		msgs.GET("/conversations", msgHdr.Conversations)
		msgs.GET("/chat", msgHdr.ChatHistory)
	}

	// WebSocket route
	r.GET("/ws", func(c *gin.Context) {
		userID := c.Query("user_id")
		if userID == "" {
			c.JSON(400, gin.H{"error": "missing user_id"})
			return
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

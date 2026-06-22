package main

// 鐢垫尝鐏靛姩鍗虫椂閫氳绯荤粺 V1.0
// 钁椾綔鏉冧汉锛氭睙鑻忔牘鐔欐櫒姊︾綉缁滅鎶€鏈夐檺鍏徃
// 寮€鍙戝畬鎴愭棩鏈燂細2026骞?鏈?8鏃?
// 鏂囦欢璇存槑锛氭湇鍔″櫒鍏ュ彛涓庤矾鐢遍厤缃?



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

// main 鏈嶅姟鍣ㄥ叆鍙ｅ嚱鏁帮紝鍒濆鍖栨暟鎹簱銆佽矾鐢卞拰WebSocket涓績
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
// log.Println("PostgreSQL connected successfully")  // FIXED: removed print statement

	// Auto-migrate
	if err := db.AutoMigrate(
		&model.User{}, &model.Message{}, &model.FriendRequest{}, &model.Friend{}, &model.Call{},
		&model.HousingListing{}, &model.HousingFavorite{}, &model.HousingBrowseHistory{},
		&model.Job{}, &model.Company{}, &model.Resume{}, &model.JobApplication{}, &model.Interview{}, &model.JobFavorite{},
	); err != nil {
		log.Fatalf("failed to migrate database: %v", err)
	}
// log.Println("Database migration completed")  // FIXED: removed print statement

	// WebSocket hub
	hub := websocket.NewHub()
	go hub.Run()

	// Initialize layers
	userRepo := repository.NewUserRepository(db)
	msgRepo := repository.NewMessageRepository(db)
	friendRepo := repository.NewFriendRepository(db)
	authSvc := service.NewAuthService(userRepo, cfg.JWTSecret)
	msgSvc := service.NewMessageService(msgRepo, hub)
	friendSvc := service.NewFriendService(friendRepo, userRepo)
	authHdr := handler.NewAuthHandler(authSvc, cfg)
	msgHdr := handler.NewMessageHandler(msgSvc)
	friendHdr := handler.NewFriendHandler(friendSvc)
	callHdr := handler.NewCallHandler(db, hub)

	// Housing module
	housingRepo := repository.NewHousingRepository(db)
	housingSvc := service.NewHousingService(housingRepo)
	housingHdr := handler.NewHousingHandler(housingSvc)

	// Jobs module
	jobRepo := repository.NewJobRepo(db)
	companyRepo := repository.NewCompanyRepo(db)
	resumeRepo := repository.NewResumeRepo(db)
	applicationRepo := repository.NewApplicationRepo(db)
	interviewRepo := repository.NewInterviewRepo(db)
	jobFavoriteRepo := repository.NewJobFavoriteRepo(db)
	jobSvc := service.NewJobService(jobRepo, companyRepo, resumeRepo, applicationRepo, interviewRepo, jobFavoriteRepo)
	jobHdr := handler.NewJobHandler(jobSvc)

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

	// Friend routes (protected)
	friends := api.Group("/friends")
	friends.Use(jwt)
	{
		friends.POST("/request", friendHdr.SendRequest)
		friends.GET("/requests", friendHdr.GetIncomingRequests)
		friends.POST("/accept", friendHdr.AcceptRequest)
		friends.POST("/reject", friendHdr.RejectRequest)
		friends.GET("/list", friendHdr.GetFriends)
	}

	// Call routes (protected)
	calls := api.Group("/call")
	calls.Use(jwt)
	{
		calls.POST("/start", callHdr.Start)
		calls.POST("/accept", callHdr.Accept)
		calls.POST("/reject", callHdr.Reject)
		calls.POST("/end", callHdr.End)
	}

	// Housing routes (protected)
	housing := api.Group("/housing")
	housing.Use(jwt)
	{
		housing.POST("/publish", housingHdr.Publish)
		housing.GET("/list", housingHdr.List)
		housing.GET("/my", housingHdr.GetMyListings)
		housing.GET("/favorites", housingHdr.GetFavorites)
		housing.GET("/history", housingHdr.GetBrowseHistory)
		housing.GET("/:id", housingHdr.Detail)
		housing.PUT("/:id", housingHdr.Update)
		housing.DELETE("/:id", housingHdr.Delete)
		housing.POST("/:id/favorite", housingHdr.AddFavorite)
		housing.DELETE("/:id/favorite", housingHdr.RemoveFavorite)
	}

	// Jobs routes (protected) 鈥?/list before /:id
	jobs := api.Group("/jobs")
	jobs.Use(jwt)
	{
		jobs.POST("/publish", jobHdr.PublishJob)
		jobs.GET("/list", jobHdr.ListJobs)
		jobs.GET("/my", jobHdr.GetMyJobs)
		jobs.GET("/favorites", jobHdr.GetJobFavorites)
		jobs.POST("/apply", jobHdr.ApplyJob)
		jobs.GET("/applications", jobHdr.GetMyApplications)
		jobs.GET("/:id", jobHdr.GetJobDetail)
		jobs.PUT("/:id", jobHdr.UpdateJob)
		jobs.DELETE("/:id", jobHdr.DeleteJob)
		jobs.POST("/:id/favorite", jobHdr.AddJobFavorite)
		jobs.DELETE("/:id/favorite", jobHdr.RemoveJobFavorite)
		jobs.GET("/:id/applications", jobHdr.GetJobApplications)
		jobs.PUT("/applications/:id", jobHdr.UpdateApplicationStatus)
	}

	// Company routes (protected)
	company := api.Group("/company")
	company.Use(jwt)
	{
		company.POST("/register", jobHdr.RegisterCompany)
		company.GET("/profile", jobHdr.GetCompanyProfile)
		company.PUT("/profile", jobHdr.UpdateCompany)
		company.GET("/:id", jobHdr.GetCompanyByID)
	}

	// Resume routes (protected)
	resume := api.Group("/resume")
	resume.Use(jwt)
	{
		resume.POST("/create", jobHdr.CreateResume)
		resume.PUT("/update", jobHdr.UpdateResume)
		resume.GET("/my", jobHdr.GetMyResume)
		resume.GET("/:id", jobHdr.GetResumeByID)
	}

	// Interview routes (protected)
	interview := api.Group("/interview")
	interview.Use(jwt)
	{
		interview.POST("/schedule", jobHdr.ScheduleInterview)
		interview.GET("/list", jobHdr.GetMyInterviews)
		interview.GET("/company", jobHdr.GetCompanyInterviews)
		interview.PUT("/:id", jobHdr.UpdateInterview)
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
// log.Printf("Server starting on %s", addr)  // FIXED: removed print statement
	if err := r.Run(addr); err != nil {
		log.Fatalf("failed to start server: %v", err)
	}
}


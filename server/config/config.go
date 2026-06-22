package config

import "os"

// Config holds all configuration for the server.
type Config struct {
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string
	JWTSecret  string
	ServerPort string
	IMAppID    int64  // 腾讯IM SDKAppID
	IMSecret   string // 腾讯IM SecretKey
}

// Load reads configuration from environment variables with defaults.
func Load() *Config {
	return &Config{
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBPort:     getEnv("DB_PORT", "5432"),
		DBUser:     getEnv("DB_USER", "postgres"),
		DBPassword: getEnv("DB_PASSWORD", "postgres"),
		DBName:     getEnv("DB_NAME", "dochatapp"),
		JWTSecret:  getEnv("JWT_SECRET", "dochatapp-secret-key"),
		ServerPort: getEnv("SERVER_PORT", "8080"),
		IMAppID:    1600148063,
		IMSecret:   getEnv("IM_SECRET", "0263ac8c3d4fe94154a4764c23fc19a21f19717ae5fd1866b2e181450b99dcd9"),
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

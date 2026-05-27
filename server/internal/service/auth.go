package service

import (
	"errors"
	"regexp"
	"time"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// AuthService handles authentication business logic.
type AuthService struct {
	repo      *repository.UserRepository
	jwtSecret string
}

// NewAuthService creates a new AuthService.
func NewAuthService(repo *repository.UserRepository, jwtSecret string) *AuthService {
	return &AuthService{repo: repo, jwtSecret: jwtSecret}
}

// RegisterRequest is the payload for user registration.
type RegisterRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required,min=6"`
	Code     string `json:"code" binding:"required"`
}

// LoginRequest is the payload for user login.
type LoginRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse is returned after successful auth.
type AuthResponse struct {
	Token string       `json:"token"`
	User  *model.User `json:"user"`
}

// Register creates a new user and returns a JWT.
func (s *AuthService) Register(req *RegisterRequest) (*AuthResponse, error) {
	// Validate phone format (simple Chinese mobile: 11 digits starting with 1)
	matched, _ := regexp.MatchString(`^1\d{10}$`, req.Phone)
	if !matched {
		return nil, errors.New("invalid phone number format")
	}

	// Accept any 6-digit verification code for now
	if matched, _ := regexp.MatchString(`^\d{6}$`, req.Code); !matched {
		return nil, errors.New("invalid verification code")
	}

	// Check if phone already registered
	existing, _ := s.repo.FindByPhone(req.Phone)
	if existing != nil {
		return nil, errors.New("phone already registered")
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, errors.New("failed to hash password")
	}

	user := &model.User{
		Phone:    req.Phone,
		Password: string(hashedPassword),
		Nickname: "用户" + req.Phone[len(req.Phone)-4:],
	}

	if err := s.repo.Create(user); err != nil {
		return nil, errors.New("failed to create user")
	}

	token, err := s.generateToken(user.ID)
	if err != nil {
		return nil, errors.New("failed to generate token")
	}

	return &AuthResponse{Token: token, User: user}, nil
}

// Login authenticates a user and returns a JWT.
func (s *AuthService) Login(req *LoginRequest) (*AuthResponse, error) {
	user, err := s.repo.FindByPhone(req.Phone)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("user not found")
		}
		return nil, errors.New("database error")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return nil, errors.New("incorrect password")
	}

	token, err := s.generateToken(user.ID)
	if err != nil {
		return nil, errors.New("failed to generate token")
	}

	return &AuthResponse{Token: token, User: user}, nil
}

// SearchByPhone finds a user by phone number (used for "new chat").
func (s *AuthService) SearchByPhone(phone string) (*model.User, error) {
	return s.repo.FindByPhone(phone)
}

// GetProfile returns user info by ID.
func (s *AuthService) GetProfile(userID string) (*model.User, error) {
	user, err := s.repo.FindByID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("user not found")
		}
		return nil, errors.New("database error")
	}
	return user, nil
}

func (s *AuthService) generateToken(userID string) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(72 * time.Hour).Unix(),
		"iat":     time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.jwtSecret))
}

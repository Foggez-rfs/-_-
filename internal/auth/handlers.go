package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"

	"github.com/Foggez-rfs/moedelo/internal/users"
	"github.com/Foggez-rfs/moedelo/pkg/db"
	"github.com/Foggez-rfs/moedelo/pkg/middleware"
)

type RegisterInput struct {
	Phone     string `json:"phone" binding:"required"`
	Password  string `json:"password" binding:"required,min=6"`
	Role      string `json:"role" binding:"required,oneof=customer executor"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
}

func Register(c *gin.Context) {
	var input RegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка хеширования"})
		return
	}
	user := users.User{
		Phone: input.Phone, PasswordHash: string(hash), Role: input.Role,
		FirstName: input.FirstName, LastName: input.LastName,
	}
	if err := db.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "пользователь уже существует"})
		return
	}
	token, _ := middleware.GenerateToken(user.ID, user.Role)
	c.JSON(http.StatusCreated, gin.H{"message": "регистрация успешна", "token": token, "user_id": user.ID})
}

func Login(c *gin.Context) {
	var input struct {
		Phone    string `json:"phone" binding:"required"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	var user users.User
	if err := db.DB.Where("phone = ?", input.Phone).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "неверный телефон или пароль"})
		return
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(input.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "неверный телефон или пароль"})
		return
	}
	token, _ := middleware.GenerateToken(user.ID, user.Role)
	c.JSON(http.StatusOK, gin.H{"token": token, "user_id": user.ID, "role": user.Role})
}

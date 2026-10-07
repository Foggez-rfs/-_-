package auth

import (
"strings"

"github.com/gin-gonic/gin"
"golang.org/x/crypto/bcrypt"

"github.com/Foggez-rfs/moedelo/internal/users"
"github.com/Foggez-rfs/moedelo/pkg/db"
"github.com/Foggez-rfs/moedelo/pkg/middleware"
)

type RegisterInput struct {
Phone     string `json:"phone" binding:"required,min=10,max=20"`
Password  string `json:"password" binding:"required,min=4,max=100"`
Role      string `json:"role" binding:"required,oneof=customer executor"`
FirstName string `json:"first_name" binding:"max=100"`
LastName  string `json:"last_name" binding:"max=100"`
}

func Register(c *gin.Context) {
var in RegisterInput
if err := c.ShouldBindJSON(&in); err != nil {
c.JSON(400, gin.H{"error": err.Error()})
return
}
phone := strings.TrimSpace(in.Phone)

var existing users.User
if err := db.DB.Where("phone = ?", phone).First(&existing).Error; err == nil {
c.JSON(409, gin.H{"error": "пользователь уже существует"})
return
}

hash, _ := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
u := users.User{
Phone: phone, PasswordHash: string(hash),
Role: in.Role, FirstName: in.FirstName, LastName: in.LastName,
Lat: 55.75, Lon: 37.62,
}
if err := db.DB.Create(&u).Error; err != nil {
c.JSON(500, gin.H{"error": "не удалось создать пользователя"})
return
}
token, _ := middleware.GenerateToken(u.ID, u.Role)
c.JSON(201, gin.H{
"message": "регистрация успешна",
"token":   token,
"user_id": u.ID,
"role":    u.Role,
"name":    u.FirstName,
})
}

func Login(c *gin.Context) {
var in struct {
Phone    string `json:"phone" binding:"required"`
Password string `json:"password" binding:"required"`
}
if err := c.ShouldBindJSON(&in); err != nil {
c.JSON(400, gin.H{"error": err.Error()})
return
}
var u users.User
if err := db.DB.Where("phone = ?", strings.TrimSpace(in.Phone)).First(&u).Error; err != nil {
c.JSON(401, gin.H{"error": "неверный телефон или пароль"})
return
}
if bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(in.Password)) != nil {
c.JSON(401, gin.H{"error": "неверный телефон или пароль"})
return
}
token, _ := middleware.GenerateToken(u.ID, u.Role)
c.JSON(200, gin.H{
"token": token, "user_id": u.ID, "role": u.Role, "name": u.FirstName,
})
}

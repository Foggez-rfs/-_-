package middleware

import (
"net/http"
"os"
"strconv"
"strings"
"time"

"github.com/gin-gonic/gin"
"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
UserID uint   `json:"user_id"`
Role   string `json:"role"`
jwt.RegisteredClaims
}

func secret() []byte {
s := os.Getenv("JWT_SECRET")
if s == "" {
s = "default-secret-change-me"
}
return []byte(s)
}

func ttl() time.Duration {
h, _ := strconv.Atoi(os.Getenv("JWT_EXPIRES_HOURS"))
if h <= 0 {
h = 72
}
return time.Duration(h) * time.Hour
}

func GenerateToken(userID uint, role string) (string, error) {
c := Claims{
UserID: userID, Role: role,
RegisteredClaims: jwt.RegisteredClaims{
ExpiresAt: jwt.NewNumericDate(time.Now().Add(ttl())),
IssuedAt:  jwt.NewNumericDate(time.Now()),
Issuer:    "moe-delo",
},
}
return jwt.NewWithClaims(jwt.SigningMethodHS256, c).SignedString(secret())
}

func AuthMiddleware() gin.HandlerFunc {
return func(c *gin.Context) {
h := c.GetHeader("Authorization")
if h == "" || !strings.HasPrefix(h, "Bearer ") {
c.JSON(http.StatusUnauthorized, gin.H{"error": "требуется токен"})
c.Abort()
return
}
cl := &Claims{}
t, err := jwt.ParseWithClaims(strings.TrimPrefix(h, "Bearer "), cl, func(t *jwt.Token) (interface{}, error) {
return secret(), nil
})
if err != nil || !t.Valid {
c.JSON(http.StatusUnauthorized, gin.H{"error": "недействительный токен"})
c.Abort()
return
}
c.Set("user_id", cl.UserID)
c.Set("role", cl.Role)
c.Next()
}
}

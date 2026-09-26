package main

import (
"log"
"os"

"github.com/gin-gonic/gin"

"github.com/Foggez-rfs/moedelo/internal/auth"
"github.com/Foggez-rfs/moedelo/internal/docs"
"github.com/Foggez-rfs/moedelo/internal/orders"
"github.com/Foggez-rfs/moedelo/internal/rating"
"github.com/Foggez-rfs/moedelo/internal/users"
"github.com/Foggez-rfs/moedelo/pkg/db"
"github.com/Foggez-rfs/moedelo/pkg/middleware"
)

func main() {
db.InitDB()
db.DB.AutoMigrate(&users.User{}, &orders.Order{}, &rating.Review{}, &docs.Document{})

r := gin.Default()
r.Use(func(c *gin.Context) {
c.Header("Access-Control-Allow-Origin", "*")
c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
if c.Request.Method == "OPTIONS" {
c.AbortWithStatus(204)
return
}
c.Next()
})

r.POST("/auth/register", auth.Register)
r.POST("/auth/login", auth.Login)

api := r.Group("/api")
api.Use(middleware.AuthMiddleware())
{
api.POST("/orders", orders.CreateOrder)
api.GET("/orders/nearby", orders.NearbyOrders)
api.POST("/orders/:id/accept", orders.AcceptOrder)
api.POST("/orders/:id/rate", rating.RateOrder)
api.POST("/docs/upload", docs.UploadDocument)
}

port := os.Getenv("PORT")
if port == "" {
port = "8080"
}
log.Printf("Сервер запущен на http://localhost:%s", port)
r.Run(":" + port)
}

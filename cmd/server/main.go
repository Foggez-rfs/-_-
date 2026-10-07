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
if err := db.DB.AutoMigrate(
&users.User{}, &orders.Order{}, &rating.Review{}, &docs.Document{},
); err != nil {
log.Fatalf("❌ Миграция не прошла: %v", err)
}
log.Println("✅ Таблицы готовы")

if os.Getenv("GIN_MODE") == "release" {
gin.SetMode(gin.ReleaseMode)
}
r := gin.New()
r.Use(gin.Logger(), gin.Recovery())

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

r.GET("/health", func(c *gin.Context) {
sqlDB, err := db.DB.DB()
dbOk := err == nil && sqlDB.Ping() == nil
c.JSON(200, gin.H{"status": "ok", "database": dbOk, "service": "moe-delo"})
})

r.POST("/auth/register", auth.Register)
r.POST("/auth/login", auth.Login)

api := r.Group("/api")
api.Use(middleware.AuthMiddleware())
{
api.POST("/orders", orders.CreateOrder)
api.GET("/orders/my", orders.MyOrders)
api.GET("/orders/nearby", orders.NearbyOrders)
api.POST("/orders/:id/accept", orders.AcceptOrder)
api.POST("/orders/:id/complete", orders.CompleteOrder)
api.POST("/orders/:id/rate", rating.RateOrder)
api.POST("/docs/upload", docs.UploadDocument)
}

// Статика (HTML-версия)
if info, err := os.Stat("web"); err == nil && info.IsDir() {
r.GET("/", func(c *gin.Context) { c.File("web/index.html") })
r.Static("/static", "web")
r.NoRoute(func(c *gin.Context) {
p := c.Request.URL.Path
if len(p) >= 4 && (p[:4] == "/api" || p[:5] == "/auth") {
c.JSON(404, gin.H{"error": "not found"})
return
}
c.File("web/index.html")
})
}

host := os.Getenv("HOST")
if host == "" {
host = "0.0.0.0"
}
port := os.Getenv("PORT")
if port == "" {
port = "8080"
}
addr := host + ":" + port

log.Println("═══════════════════════════════════════════")
log.Printf("  🚀 Сервер на %s", addr)
log.Println("═══════════════════════════════════════════")

if err := r.Run(addr); err != nil {
log.Fatalf("❌ Сервер упал: %v", err)
}
}

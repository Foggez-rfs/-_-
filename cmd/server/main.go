package main

import (
"log"
"net/http"
"os"
"path/filepath"

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
// --- База данных ---
db.InitDB()
if err := db.DB.AutoMigrate(&users.User{}, &orders.Order{}, &rating.Review{}, &docs.Document{}); err != nil {
log.Fatalf("❌ Миграция не прошла: %v", err)
}
log.Println("✅ Таблицы готовы")

// --- Gin ---
if os.Getenv("GIN_MODE") == "release" {
gin.SetMode(gin.ReleaseMode)
}
r := gin.New()
r.Use(gin.Logger(), gin.Recovery())

// --- CORS ---
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

// --- Health ---
r.GET("/health", func(c *gin.Context) {
sqlDB, err := db.DB.DB()
dbOk := err == nil && sqlDB.Ping() == nil
c.JSON(200, gin.H{"status": "ok", "database": dbOk, "service": "moe-delo"})
})

// --- Публичные API ---
r.POST("/auth/register", auth.Register)
r.POST("/auth/login", auth.Login)

// --- Защищённые API ---
api := r.Group("/api")
api.Use(middleware.AuthMiddleware())
{
api.POST("/orders", orders.CreateOrder)
api.GET("/orders/nearby", orders.NearbyOrders)
api.POST("/orders/:id/accept", orders.AcceptOrder)
api.POST("/orders/:id/rate", rating.RateOrder)
api.POST("/docs/upload", docs.UploadDocument)
}

// --- Статика: HTML, CSS, JS ---
// Ищем папку web/ относительно рабочей директории и относительно бинаря
webDir := findWebDir()
if webDir != "" {
log.Printf("📂 Статика: %s", webDir)

// /  →  index.html
r.GET("/", func(c *gin.Context) {
c.File(filepath.Join(webDir, "index.html"))
})

// /static/*  →  файлы из web/
r.Static("/static", webDir)

// Фолбэк: любой не-API и не-static путь → index.html (SPA-роутинг)
r.NoRoute(func(c *gin.Context) {
path := c.Request.URL.Path
// API-запросы — оставляем 404
if len(path) >= 4 && (path[:4] == "/api" || path[:5] == "/auth") {
c.JSON(404, gin.H{"error": "not found"})
return
}
c.File(filepath.Join(webDir, "index.html"))
})
} else {
log.Println("⚠️  Папка web/ не найдена — только API")
}

// --- Запуск ---
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
log.Println("  🚀 Сервер «Моё дело»")
log.Println("═══════════════════════════════════════════")
log.Printf("  📡 Слушает:    %s", addr)
log.Printf("  🏠 Локально:   http://127.0.0.1:%s", port)
log.Printf("  🌐 По сети:    http://<IP-телефона>:%s", port)
log.Printf("  ❤️  Health:     http://127.0.0.1:%s/health", port)
if webDir != "" {
log.Printf("  🌍 Сайт:       http://127.0.0.1:%s/", port)
}
log.Println("═══════════════════════════════════════════")

if err := r.Run(addr); err != nil {
log.Fatalf("❌ Сервер упал: %v", err)
}
}

// findWebDir ищет папку web/ в нескольких местах
func findWebDir() string {
candidates := []string{
"web",           // если запускаем из ~/moe-delo
"../web",        // из cmd/server/
"./cmd/web",     // редко
"/data/data/com.termux/files/home/moe-delo/web", // хардкод Termux
}
for _, c := range candidates {
if info, err := os.Stat(c); err == nil && info.IsDir() {
if _, err := os.Stat(filepath.Join(c, "index.html")); err == nil {
return c
}
}
}
return ""
}

// заглушка, чтобы импорт net/http использовался
var _ = http.StatusOK

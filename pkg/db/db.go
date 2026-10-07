package db

import (
"fmt"
"log"
"os"
"time"

"github.com/joho/godotenv"
"gorm.io/driver/postgres"
"gorm.io/gorm"
"gorm.io/gorm/logger"
)

var DB *gorm.DB

func InitDB() {
_ = godotenv.Load()
dsn := fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=%s password='%s'",
getEnv("DB_HOST", "localhost"),
getEnv("DB_PORT", "5432"),
getEnv("DB_USER", "moe_user"),
getEnv("DB_NAME", "moe_delo"),
getEnv("DB_SSLMODE", "disable"),
getEnv("DB_PASSWORD", ""),
)
var err error
DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
Logger: logger.Default.LogMode(logger.Silent),
})
if err != nil {
log.Fatalf("❌ Ошибка подключения к БД: %v", err)
}
sqlDB, _ := DB.DB()
sqlDB.SetMaxOpenConns(20)
sqlDB.SetMaxIdleConns(5)
sqlDB.SetConnMaxLifetime(time.Hour)
if err := sqlDB.Ping(); err != nil {
log.Fatalf("❌ БД не отвечает: %v", err)
}
log.Println("✅ PostgreSQL подключена")
}

func getEnv(k, fb string) string {
if v := os.Getenv(k); v != "" {
return v
}
return fb
}

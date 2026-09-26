package db

import (
"fmt"
"log"
"os"

"github.com/joho/godotenv"
"gorm.io/driver/postgres"
"gorm.io/gorm"
)

var DB *gorm.DB

func InitDB() {
_ = godotenv.Load()

// Формат key=value безопаснее задавать через url.URL либо
// строкой без пробела перед dbname. Используем явные кавычки.
dsn := fmt.Sprintf(
"host=%s port=%s user=%s dbname=%s sslmode=disable password=%s",
getEnv("DB_HOST", "localhost"),
getEnv("DB_PORT", "5432"),
getEnv("DB_USER", "moe_user"),
getEnv("DB_NAME", "moe_delo"),
quoteIfEmpty(getEnv("DB_PASSWORD", "")),
)


var err error
DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
if err != nil {
log.Fatalf("Ошибка подключения к БД: %v", err)
}
log.Println("PostgreSQL подключена")
}

// quoteIfEmpty оборачивает пароль в кавычки, если он пустой
func quoteIfEmpty(s string) string {
if s == "" {
return "''"
}
return s
}

func getEnv(key, fallback string) string {
if val := os.Getenv(key); val != "" {
return val
}
return fallback
}

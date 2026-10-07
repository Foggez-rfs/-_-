package main

import (
"fmt"
"net/http"
"os"
"time"
)

func main() {
url := os.Getenv("MOE_URL")
if url == "" {
url = "http://127.0.0.1:8080"
}

fmt.Println("\n═══════════════════════════════════════════")
fmt.Println("  Проверка сервера «Моё дело»")
fmt.Println("═══════════════════════════════════════════")
fmt.Printf("  URL: %s\n\n", url)

client := &http.Client{Timeout: 5 * time.Second}
resp, err := client.Get(url + "/health")
if err != nil {
fmt.Printf("  ❌ Сервер не отвечает: %v\n\n", err)
os.Exit(1)
}
defer resp.Body.Close()

if resp.StatusCode == 200 {
fmt.Println("  ✅ Сервер работает")
fmt.Println("  ✅ БД подключена")
} else {
fmt.Printf("  ⚠️  HTTP %d\n", resp.StatusCode)
}

r2, err := client.Get(url + "/")
if err == nil {
r2.Body.Close()
if r2.StatusCode == 200 {
fmt.Println("  ✅ Главная страница отдаётся")
}
}

fmt.Println("\n═══════════════════════════════════════════\n")
}

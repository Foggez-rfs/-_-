package main

import (
"fmt"
"log"
"os"

"github.com/Foggez-rfs/moedelo/internal/users"
"github.com/Foggez-rfs/moedelo/pkg/db"
)

func main() {
if len(os.Args) < 2 {
printHelp()
return
}
db.InitDB()

switch os.Args[1] {
case "list":
listUsers()
case "orders":
listOrders()
case "delete":
if len(os.Args) < 3 {
log.Fatal("Укажите телефон: delete <phone>")
}
deleteUser(os.Args[2])
case "role":
if len(os.Args) < 4 {
log.Fatal("Использование: role <phone> <customer|executor>")
}
changeRole(os.Args[2], os.Args[3])
default:
printHelp()
}
}

func printHelp() {
fmt.Println(`
Команды:
  list                             список пользователей
  orders                           список заказов
  delete <phone>                   удалить пользователя
  role <phone> <customer|executor> сменить роль
`)
}

func listUsers() {
var us []users.User
db.DB.Order("id").Find(&us)
fmt.Printf("\n%-4s %-16s %-12s %-12s %s\n", "ID", "Телефон", "Роль", "Имя", "Рейтинг")
fmt.Println("─────────────────────────────────────────────────────────")
for _, u := range us {
fmt.Printf("%-4d %-16s %-12s %-12s %.1f\n", u.ID, u.Phone, u.Role, u.FirstName, u.Rating)
}
fmt.Printf("\nВсего: %d\n", len(us))
}

func listOrders() {
type Row struct {
ID          uint
Category    string
Priority    int
Status      string
Description string
}
var rows []Row
db.DB.Table("orders").Select("id, category, priority, status, description").Order("id").Scan(&rows)
fmt.Printf("\n%-4s %-16s %-10s %-12s %s\n", "ID", "Категория", "Приор.", "Статус", "Описание")
fmt.Println("──────────────────────────────────────────────────────────────────────")
for _, o := range rows {
d := o.Description
if len(d) > 30 {
d = d[:30] + "…"
}
fmt.Printf("%-4d %-16s %-10d %-12s %s\n", o.ID, o.Category, o.Priority, o.Status, d)
}
fmt.Printf("\nВсего: %d\n", len(rows))
}

func deleteUser(phone string) {
var u users.User
if err := db.DB.Where("phone = ?", phone).First(&u).Error; err != nil {
log.Fatalf("❌ %s не найден", phone)
}
db.DB.Delete(&u)
fmt.Printf("✅ Удалён: %s\n", phone)
}

func changeRole(phone, role string) {
if role != "customer" && role != "executor" {
log.Fatal("Роль: customer или executor")
}
var u users.User
if err := db.DB.Where("phone = ?", phone).First(&u).Error; err != nil {
log.Fatalf("❌ %s не найден", phone)
}
db.DB.Model(&u).Update("role", role)
fmt.Printf("✅ %s → %s\n", phone, role)
}

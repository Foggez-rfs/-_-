package main

import (
"log"

"github.com/Foggez-rfs/moedelo/internal/orders"
"github.com/Foggez-rfs/moedelo/internal/users"
"github.com/Foggez-rfs/moedelo/pkg/db"
"golang.org/x/crypto/bcrypt"
)

func main() {
db.InitDB()
db.DB.AutoMigrate(&users.User{}, &orders.Order{})

testUsers := []struct{ Phone, Pass, Role, Name string }{
{"+79001112233", "demo1", "customer", "Иван"},
{"+79004445566", "demo2", "executor", "Пётр"},
{"+79007778899", "demo3", "executor", "Сергей"},
}
for _, u := range testUsers {
var ex users.User
if err := db.DB.Where("phone = ?", u.Phone).First(&ex).Error; err == nil {
log.Printf("⚠️  %s уже существует", u.Phone)
continue
}
h, _ := bcrypt.GenerateFromPassword([]byte(u.Pass), bcrypt.DefaultCost)
user := users.User{
Phone: u.Phone, PasswordHash: string(h),
Role: u.Role, FirstName: u.Name, Lat: 55.75, Lon: 37.62,
}
db.DB.Create(&user)
log.Printf("✅ %s (%s)", u.Phone, u.Role)
}

var ivan users.User
if err := db.DB.Where("phone = ?", "+79001112233").First(&ivan).Error; err == nil {
ordersList := []orders.Order{
{CustomerID: ivan.ID, Description: "Прорвало кран на кухне, вода льётся!",
Category: "сантехника", Priority: 1, Address: "ул. Ленина 1", Lat: 55.75, Lon: 37.62, Status: "pending"},
{CustomerID: ivan.ID, Description: "Проводить в поликлинику",
Category: "сопровождение", Priority: 2, Address: "ул. Пушкина 10", Lat: 55.76, Lon: 37.63, Status: "pending"},
{CustomerID: ivan.ID, Description: "Привезти продукты из магазина",
Category: "доставка", Priority: 2, Address: "ул. Гагарина 5", Lat: 55.74, Lon: 37.61, Status: "pending"},
{CustomerID: ivan.ID, Description: "Заменить розетку в спальне",
Category: "электрика", Priority: 2, Address: "ул. Мира 3", Lat: 55.75, Lon: 37.62, Status: "pending"},
}
for _, o := range ordersList {
db.DB.Create(&o)
}
log.Printf("✅ Создано заказов: %d", len(ordersList))
}

log.Println("")
log.Println("═══════════════════════════════════════")
log.Println("  ✅ БД заполнена")
log.Println("═══════════════════════════════════════")
log.Println("  Заказчик:    +79001112233 / demo1")
log.Println("  Исполнитель: +79004445566 / demo2")
log.Println("  Исполнитель: +79007778899 / demo3")
log.Println("")
}

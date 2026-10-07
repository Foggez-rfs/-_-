package orders

import (
"strconv"

"github.com/gin-gonic/gin"

"github.com/Foggez-rfs/moedelo/internal/ai"
"github.com/Foggez-rfs/moedelo/internal/geo"
"github.com/Foggez-rfs/moedelo/pkg/db"
)

// CreateOrder — создание заказа с ИИ-классификацией
func CreateOrder(c *gin.Context) {
var in struct {
Description string  `json:"description" binding:"required,min=3,max=500"`
Address     string  `json:"address" binding:"max=300"`
Lat         float64 `json:"lat"`
Lon         float64 `json:"lon"`
}
if err := c.ShouldBindJSON(&in); err != nil {
c.JSON(400, gin.H{"error": err.Error()})
return
}
lat, lon := in.Lat, in.Lon
if lat == 0 && lon == 0 {
lat, lon = 55.75, 37.62
}

cat, prio := ai.ClassifyOrder(in.Description)
uid := c.GetUint("user_id")
o := Order{
CustomerID: uid, Description: in.Description,
Category: string(cat), Priority: prio,
Address: in.Address, Lat: lat, Lon: lon, Status: "pending",
}
if err := db.DB.Create(&o).Error; err != nil {
c.JSON(500, gin.H{"error": "не удалось создать заказ"})
return
}
c.JSON(201, gin.H{
"message": "заказ создан", "order": o,
"category": cat, "priority": prio,
})
}

// NearbyOrders — заказы в радиусе от исполнителя
func NearbyOrders(c *gin.Context) {
lat, _ := strconv.ParseFloat(c.Query("lat"), 64)
lon, _ := strconv.ParseFloat(c.Query("lon"), 64)
radius, _ := strconv.ParseFloat(c.DefaultQuery("radius", "1000"), 64)
if lat == 0 || lon == 0 {
lat, lon = 55.75, 37.62
}

var orders []Order
db.DB.Where("status = ?", "pending").Order("priority asc, created_at desc").Find(&orders)

type item struct {
Order
Distance float64 `json:"distance_m"`
}
res := make([]item, 0)
for _, o := range orders {
d := geo.Haversine(lat, lon, o.Lat, o.Lon)
if d <= radius {
res = append(res, item{Order: o, Distance: d})
}
}
c.JSON(200, gin.H{"orders": res, "count": len(res), "radius": radius})
}

// MyOrders — заказы текущего пользователя
func MyOrders(c *gin.Context) {
uid := c.GetUint("user_id")
role := c.GetString("role")

var orders []Order
q := db.DB.Model(&Order{})
if role == "executor" {
q = q.Where("executor_id = ?", uid).Order("updated_at desc")
} else {
q = q.Where("customer_id = ?", uid).Order("created_at desc")
}
q.Find(&orders)

c.JSON(200, gin.H{"orders": orders, "count": len(orders)})
}

// AcceptOrder — исполнитель принимает заказ
func AcceptOrder(c *gin.Context) {
id, _ := strconv.ParseUint(c.Param("id"), 10, 32)
uid := c.GetUint("user_id")
r := db.DB.Model(&Order{}).
Where("id = ? AND status = ?", id, "pending").
Updates(map[string]interface{}{"executor_id": uid, "status": "accepted"})
if r.RowsAffected == 0 {
c.JSON(409, gin.H{"error": "заказ уже принят или не существует"})
return
}
c.JSON(200, gin.H{"message": "заказ принят", "order_id": id})
}

// CompleteOrder — исполнитель завершает заказ
func CompleteOrder(c *gin.Context) {
id, _ := strconv.ParseUint(c.Param("id"), 10, 32)
uid := c.GetUint("user_id")
r := db.DB.Model(&Order{}).
Where("id = ? AND executor_id = ? AND status = ?", id, uid, "accepted").
Update("status", "completed")
if r.RowsAffected == 0 {
c.JSON(409, gin.H{"error": "нельзя завершить этот заказ"})
return
}
c.JSON(200, gin.H{"message": "заказ завершён", "order_id": id})
}

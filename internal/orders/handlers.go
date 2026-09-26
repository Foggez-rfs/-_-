package orders

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/Foggez-rfs/moedelo/internal/ai"
	"github.com/Foggez-rfs/moedelo/internal/geo"
	"github.com/Foggez-rfs/moedelo/pkg/db"
)

func CreateOrder(c *gin.Context) {
	var input struct {
		Description string  `json:"description" binding:"required"`
		Address     string  `json:"address"`
		Lat         float64 `json:"lat"`
		Lon         float64 `json:"lon"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	category, priority := ai.ClassifyOrder(input.Description)
	userID := c.GetUint("user_id")
	order := Order{
		CustomerID: userID, Description: input.Description,
		Category: string(category), Priority: priority,
		Address: input.Address, Lat: input.Lat, Lon: input.Lon,
	}
	if err := db.DB.Create(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "не удалось создать заказ"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "заказ создан", "order": order, "category": category, "priority": priority})
}

func NearbyOrders(c *gin.Context) {
	lat, _ := strconv.ParseFloat(c.Query("lat"), 64)
	lon, _ := strconv.ParseFloat(c.Query("lon"), 64)
	radius, _ := strconv.ParseFloat(c.DefaultQuery("radius", "1000"), 64)

	var orders []Order
	db.DB.Where("status = ?", "pending").Find(&orders)

	var nearby []Order
	for _, o := range orders {
		if geo.Haversine(lat, lon, o.Lat, o.Lon) <= radius {
			nearby = append(nearby, o)
		}
	}
	c.JSON(http.StatusOK, gin.H{"orders": nearby, "count": len(nearby)})
}

func AcceptOrder(c *gin.Context) {
	id, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	userID := c.GetUint("user_id")
	result := db.DB.Model(&Order{}).
		Where("id = ? AND status = ?", id, "pending").
		Updates(map[string]interface{}{"executor_id": userID, "status": "accepted"})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusConflict, gin.H{"error": "заказ уже принят или не существует"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "заказ принят"})
}

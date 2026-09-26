package rating

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/Foggez-rfs/moedelo/internal/users"
	"github.com/Foggez-rfs/moedelo/pkg/db"
)

func RateOrder(c *gin.Context) {
	orderID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	var input struct {
		Score   int    `json:"score" binding:"required,min=1,max=5"`
		Comment string `json:"comment"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	customerID := c.GetUint("user_id")

	var order struct{ ExecutorID *uint }
	if err := db.DB.Table("orders").Select("executor_id").
		Where("id = ? AND customer_id = ?", orderID, customerID).Scan(&order).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "заказ не найден"})
		return
	}
	if order.ExecutorID == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "заказ ещё не принят"})
		return
	}

	review := Review{
		OrderID: uint(orderID), ExecutorID: *order.ExecutorID,
		CustomerID: customerID, Score: input.Score, Comment: input.Comment,
	}
	db.DB.Create(&review)

	var avg float64
	db.DB.Model(&Review{}).Where("executor_id = ?", *order.ExecutorID).
		Select("COALESCE(AVG(score), 5.0)").Scan(&avg)
	db.DB.Model(&users.User{}).Where("id = ?", *order.ExecutorID).Update("rating", avg)
	db.DB.Table("orders").Where("id = ?", orderID).Update("status", "completed")

	c.JSON(http.StatusOK, gin.H{"message": "оценка сохранена", "new_rating": avg})
}

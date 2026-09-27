package rating

import (
"strconv"

"github.com/gin-gonic/gin"

"github.com/Foggez-rfs/moedelo/internal/users"
"github.com/Foggez-rfs/moedelo/pkg/db"
)

func RateOrder(c *gin.Context) {
oid, _ := strconv.ParseUint(c.Param("id"), 10, 32)
var in struct {
Score   int    `json:"score" binding:"required,min=1,max=5"`
Comment string `json:"comment" binding:"max=500"`
}
if err := c.ShouldBindJSON(&in); err != nil {
c.JSON(400, gin.H{"error": err.Error()})
return
}
uid := c.GetUint("user_id")
var o struct{ ExecutorID *uint }
if err := db.DB.Table("orders").Select("executor_id").
Where("id = ? AND customer_id = ?", oid, uid).Scan(&o).Error; err != nil {
c.JSON(404, gin.H{"error": "заказ не найден"})
return
}
if o.ExecutorID == nil {
c.JSON(400, gin.H{"error": "заказ ещё не принят"})
return
}
db.DB.Create(&Review{OrderID: uint(oid), ExecutorID: *o.ExecutorID, CustomerID: uid, Score: in.Score, Comment: in.Comment})
var avg float64
db.DB.Model(&Review{}).Where("executor_id = ?", *o.ExecutorID).Select("COALESCE(AVG(score), 5.0)").Scan(&avg)
db.DB.Model(&users.User{}).Where("id = ?", *o.ExecutorID).Update("rating", avg)
db.DB.Table("orders").Where("id = ?", oid).Update("status", "completed")
c.JSON(200, gin.H{"message": "оценка сохранена", "new_rating": avg})
}

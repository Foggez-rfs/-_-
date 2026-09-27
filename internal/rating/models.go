package rating

import "time"

type Review struct {
ID         uint      `gorm:"primaryKey" json:"id"`
OrderID    uint      `gorm:"not null;index" json:"order_id"`
ExecutorID uint      `gorm:"not null;index" json:"executor_id"`
CustomerID uint      `gorm:"not null" json:"customer_id"`
Score      int       `gorm:"not null" json:"score"`
Comment    string    `gorm:"type:text" json:"comment"`
CreatedAt  time.Time `json:"created_at"`
}

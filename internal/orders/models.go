package orders

import "time"

type Order struct {
ID          uint      `gorm:"primaryKey" json:"id"`
CustomerID  uint      `gorm:"not null;index" json:"customer_id"`
ExecutorID  *uint     `gorm:"index" json:"executor_id"`
Description string    `gorm:"not null;type:text" json:"description"`
Category    string    `gorm:"not null;index" json:"category"`
Priority    int       `gorm:"default:2;index" json:"priority"`
Address     string    `json:"address"`
Lat         float64   `json:"lat"`
Lon         float64   `json:"lon"`
Status      string    `gorm:"default:'pending';index" json:"status"`
CreatedAt   time.Time `json:"created_at"`
UpdatedAt   time.Time `json:"updated_at"`
}

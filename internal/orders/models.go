package orders

import "time"

type Order struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	CustomerID  uint      `gorm:"not null;index" json:"customer_id"`
	ExecutorID  *uint     `gorm:"index" json:"executor_id"`
	Description string    `gorm:"not null" json:"description"`
	Category    string    `gorm:"not null" json:"category"`
	Priority    int       `gorm:"default:2" json:"priority"`
	Address     string    `json:"address"`
	Lat         float64   `json:"lat"`
	Lon         float64   `json:"lon"`
	Status      string    `gorm:"default:'pending'" json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

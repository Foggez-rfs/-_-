package users

import "time"

type User struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	Phone        string    `gorm:"uniqueIndex;not null" json:"phone"`
	PasswordHash string    `gorm:"not null" json:"-"`
	Role         string    `gorm:"not null;default:'customer'" json:"role"`
	FirstName    string    `json:"first_name"`
	LastName     string    `json:"last_name"`
	Rating       float64   `gorm:"default:5.0" json:"rating"`
	Skills       string    `json:"skills"`
	Lat          float64   `json:"lat"`
	Lon          float64   `json:"lon"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

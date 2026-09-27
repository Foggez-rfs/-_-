package docs

import "time"

type Document struct {
ID        uint      `gorm:"primaryKey" json:"id"`
UserID    uint      `gorm:"not null;index" json:"user_id"`
DocType   string    `gorm:"not null" json:"doc_type"`
FilePath  string    `gorm:"not null" json:"file_path"`
Verified  bool      `gorm:"default:false" json:"verified"`
CreatedAt time.Time `json:"created_at"`
}

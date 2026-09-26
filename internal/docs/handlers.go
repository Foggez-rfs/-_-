package docs

import (
	"fmt"
	"net/http"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/Foggez-rfs/moedelo/pkg/db"
)

func UploadDocument(c *gin.Context) {
	userID := c.GetUint("user_id")
	docType := c.PostForm("doc_type")
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "файл не загружен"})
		return
	}
	ext := filepath.Ext(file.Filename)
	filename := fmt.Sprintf("doc_%d_%d%s", userID, time.Now().Unix(), ext)
	filePath := filepath.Join("uploads", filename)
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сохранения файла"})
		return
	}
	doc := Document{UserID: userID, DocType: docType, FilePath: filePath}
	db.DB.Create(&doc)
	c.JSON(http.StatusCreated, gin.H{"message": "документ загружен", "document": doc})
}

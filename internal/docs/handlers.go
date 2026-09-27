package docs

import (
"fmt"
"os"
"path/filepath"
"time"

"github.com/gin-gonic/gin"

"github.com/Foggez-rfs/moedelo/pkg/db"
)

func UploadDocument(c *gin.Context) {
uid := c.GetUint("user_id")
dt := c.PostForm("doc_type")
if dt == "" {
c.JSON(400, gin.H{"error": "укажите тип документа"})
return
}
f, err := c.FormFile("file")
if err != nil {
c.JSON(400, gin.H{"error": "файл не загружен"})
return
}
if f.Size > 10*1024*1024 {
c.JSON(413, gin.H{"error": "файл больше 10 МБ"})
return
}
_ = os.MkdirAll("uploads", 0755)
name := fmt.Sprintf("doc_%d_%d%s", uid, time.Now().Unix(), filepath.Ext(f.Filename))
path := filepath.Join("uploads", name)
if err := c.SaveUploadedFile(f, path); err != nil {
c.JSON(500, gin.H{"error": "не удалось сохранить"})
return
}
d := Document{UserID: uid, DocType: dt, FilePath: path}
db.DB.Create(&d)
c.JSON(201, gin.H{"message": "документ загружен", "document": d})
}

# Моё дело

Волонтёрская платформа помощи пожилым людям и людям с ОВЗ.

## Стек
Go · Gin · GORM · PostgreSQL · JWT · bcrypt · Haversine

## Запуск
pkg install golang postgresql
pg_ctl -D $PREFIX/var/lib/postgresql start
go mod tidy
go run cmd/server/main.go

## API
POST /auth/register — регистрация
POST /auth/login — вход
POST /api/orders — создать заказ (ИИ)
GET  /api/orders/nearby?lat=&lon=&radius=1000 — заказы рядом
POST /api/orders/:id/accept — принять заказ
POST /api/orders/:id/rate — оценить
POST /api/docs/upload — загрузить документ

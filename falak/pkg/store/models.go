// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.27.0

package store

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type AuthGoogle struct {
	ID         uuid.UUID
	CustomerID uuid.UUID
	Sub        string
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type AuthPassword struct {
	ID         uuid.UUID
	CustomerID uuid.UUID
	Password   string
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type Customer struct {
	ID        uuid.UUID
	Name      string
	Email     string
	CreatedAt time.Time
	UpdatedAt time.Time
}

type MagicLink struct {
	ID         uuid.UUID
	CustomerID uuid.UUID
	Token      uuid.UUID
	ExpiresAt  time.Time
	UsedAt     sql.NullTime
	CreatedAt  time.Time
	UpdatedAt  time.Time
}
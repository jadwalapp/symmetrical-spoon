// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.27.0
// source: customer.sql

package store

import (
	"context"

	"github.com/google/uuid"
)

const createCustomer = `-- name: CreateCustomer :one
INSERT INTO customer (name, email)
VALUES ($1, LOWER($2))
RETURNING id, name, email, created_at, updated_at
`

type CreateCustomerParams struct {
	Name  string
	Lower string
}

func (q *Queries) CreateCustomer(ctx context.Context, arg CreateCustomerParams) (Customer, error) {
	row := q.db.QueryRowContext(ctx, createCustomer, arg.Name, arg.Lower)
	var i Customer
	err := row.Scan(
		&i.ID,
		&i.Name,
		&i.Email,
		&i.CreatedAt,
		&i.UpdatedAt,
	)
	return i, err
}

const deleteCustomerById = `-- name: DeleteCustomerById :exec
DELETE FROM customer WHERE id = $1
`

func (q *Queries) DeleteCustomerById(ctx context.Context, id uuid.UUID) error {
	_, err := q.db.ExecContext(ctx, deleteCustomerById, id)
	return err
}

const getCustomerByEmail = `-- name: GetCustomerByEmail :one
SELECT id, name, email, created_at, updated_at FROM customer WHERE LOWER(email) = LOWER($1)
`

func (q *Queries) GetCustomerByEmail(ctx context.Context, lower string) (Customer, error) {
	row := q.db.QueryRowContext(ctx, getCustomerByEmail, lower)
	var i Customer
	err := row.Scan(
		&i.ID,
		&i.Name,
		&i.Email,
		&i.CreatedAt,
		&i.UpdatedAt,
	)
	return i, err
}

const getCustomerById = `-- name: GetCustomerById :one
SELECT id, name, email, created_at, updated_at FROM customer WHERE id = $1
`

func (q *Queries) GetCustomerById(ctx context.Context, id uuid.UUID) (Customer, error) {
	row := q.db.QueryRowContext(ctx, getCustomerById, id)
	var i Customer
	err := row.Scan(
		&i.ID,
		&i.Name,
		&i.Email,
		&i.CreatedAt,
		&i.UpdatedAt,
	)
	return i, err
}
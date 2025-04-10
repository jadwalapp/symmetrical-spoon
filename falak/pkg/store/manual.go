package store

import (
	"context"
	"strings"

	"github.com/google/uuid"
)

const deleteDevices = `-- name: DeleteDevices :exec
DELETE FROM device WHERE id IN (/*SLICE:ids*/?)
`

func (q *Queries) DeleteDevices(ctx context.Context, ids []uuid.UUID) error {
	query := deleteDevices
	var queryParams []interface{}
	if len(ids) > 0 {
		for _, v := range ids {
			queryParams = append(queryParams, v)
		}
		query = strings.Replace(query, "/*SLICE:ids*/?", strings.Repeat(",?", len(ids))[1:], 1)
	} else {
		query = strings.Replace(query, "/*SLICE:ids*/?", "NULL", 1)
	}
	_, err := q.db.ExecContext(ctx, query, queryParams...)
	return err
}

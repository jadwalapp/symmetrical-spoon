package util

import (
	"strings"
)

// returns empty strings if it fails :D
//
// first string is before the @
// second string is after the @
func SplitEmail(email string) (string, string) {
	parts := strings.Split(email, "@")
	if len(parts) != 2 {
		return "", ""
	}

	return parts[0], parts[1]
}

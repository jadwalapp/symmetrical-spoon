package util

import (
	"crypto/sha256"
	"encoding/base64"
)

func HashStringToBase64SHA256(input string) string {
	hashedTokenBytes := sha256.Sum256([]byte(input))
	hashedToken := base64.URLEncoding.EncodeToString(hashedTokenBytes[:])

	return hashedToken
}

package client

import (
	"fmt"
	"strings"
)

func extractCSRFToken(htmlContent string) string {
	csrfTokenStart := strings.Index(htmlContent, "name=\"CSRF_TOKEN\" value=\"")
	if csrfTokenStart == -1 {
		fmt.Println("CSRF token not found in the HTML")
		return ""
	}
	csrfTokenStart += len("name=\"CSRF_TOKEN\" value=\"")

	csrfTokenEnd := strings.Index(htmlContent[csrfTokenStart:], "\"")
	if csrfTokenEnd == -1 {
		fmt.Println("End of CSRF token not found")
		return ""
	}

	return htmlContent[csrfTokenStart : csrfTokenStart+csrfTokenEnd]
}

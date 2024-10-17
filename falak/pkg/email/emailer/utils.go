package emailer

import "strings"

func splitNameEmail(input string) (name, email string) {
	// Check if the input contains "<" and ">"
	if strings.Contains(input, "<") && strings.Contains(input, ">") {
		// Split the input by "<" and ">"
		parts := strings.Split(input, " ")
		if len(parts) != 2 {
			// If the input doesn't contain a valid "<" and ">", return empty strings
			return "", ""
		}

		// Extract the name and email parts
		name = strings.TrimSpace(parts[0])
		email = strings.TrimPrefix(strings.TrimSuffix(strings.TrimSpace(parts[1]), ">"), "<")
	} else {
		// If the input doesn't contain "<" and ">", assume the whole input is the email
		email = strings.TrimSpace(input)
	}

	// If the email is valid and name is empty, use default name "Jadwal"
	if isValidEmail(email) && name == "" {
		name = "Jadwal"
	}

	return name, email
}

func isValidEmail(email string) bool {
	// This is a simplified email validation, you might want to use a more robust method
	return strings.Contains(email, "@") && strings.Contains(email, ".")
}

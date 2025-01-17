package calendar

import "strings"

func replaceSpaces(input string) string {
	return strings.ReplaceAll(input, " ", "_")
}

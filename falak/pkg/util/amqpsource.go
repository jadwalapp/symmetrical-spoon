package util

import "fmt"

func CreateAmqpSource(
	user string,
	pass string,
	host string,
	port string,
) string {
	src := fmt.Sprintf(
		"amqp://%s:%s@%s:%s/",
		user,
		pass,
		host,
		port,
	)

	return src
}

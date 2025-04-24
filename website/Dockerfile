FROM golang:1.24.2 AS builder
WORKDIR /app
RUN echo 'package main;import("log";"net/http");func main(){http.Handle("/",http.FileServer(http.Dir("/web")));log.Println("Listening on :8080...");log.Fatal(http.ListenAndServe(":8080",nil))}' > main.go
RUN CGO_ENABLED=0 GOOS=linux go build -o server main.go

FROM scratch
WORKDIR /
COPY --from=builder /app/server /server
COPY . /web
CMD ["/server"]
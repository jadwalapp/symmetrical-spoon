FROM golang:1.23.2 AS builder
WORKDIR /falak
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main cmd/main.go

FROM alpine:latest AS certs
RUN apk --update add ca-certificates

FROM scratch
COPY --from=builder /falak/main /main
COPY ./grpc.env.example /grpc.env
COPY ./pkg/store/migrations pkg/store/migrations
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
CMD [ "/main" ]
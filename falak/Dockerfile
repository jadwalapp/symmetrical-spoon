FROM golang:1.23.2 AS base
WORKDIR /falak
COPY go.mod go.sum ./
RUN go mod download
COPY . .


FROM base AS dev
CMD [ "go", "run", "cmd/main.go" ]


FROM base AS builder
RUN CGO_ENABLED=0 GOOS=linux go build -o main cmd/main.go


FROM alpine:latest AS certs
RUN apk --update add ca-certificates


FROM scratch
COPY --from=builder /falak/main /main
COPY ./falak.env.example /falak.env
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
CMD [ "/main" ]
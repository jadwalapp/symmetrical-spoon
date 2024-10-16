FROM golang:1.23.2 AS builder
WORKDIR /falak
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main cmd/main.go

FROM scratch
COPY --from=builder /falak/main /main
COPY ./grpc.env.example /grpc.env
COPY ./pkg/store/migrations pkg/store/migrations
CMD [ "/main" ]
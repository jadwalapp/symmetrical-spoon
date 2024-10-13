# symmetrical spoon

you know, something :D

## Requirements

- Golang: [https://go.dev/](https://go.dev/)
- Taskfile: [https://taskfile.dev/](https://taskfile.dev/)
- protoc: [https://grpc.io/docs/protoc-installation/](https://grpc.io/docs/protoc-installation/)
- sqlc: [https://docs.sqlc.dev/en/stable/overview/install.html](https://docs.sqlc.dev/en/stable/overview/install.html)
- migrate: [https://github.com/golang-migrate/migrate/tree/master/cmd/migrate](https://github.com/golang-migrate/migrate/tree/master/cmd/migrate)

## Generating gRPC Code from Proto Files

You need the following dependencies:

- protovalidate, already a submodule in the repository.

and you need those deps:

```
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

> Run: `task gen-proto`

## Get Submodules

```
git submodule init
```

```
git submodule update
```

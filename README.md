# symmetrical spoon

you know, something :D

## Requirements

- Docker: [https://docker.com](https://docker.com)
- Golang: [https://go.dev/](https://go.dev/)
- Taskfile: [https://taskfile.dev/](https://taskfile.dev/)
- buf cli: [https://buf.build/docs/installation](https://buf.build/docs/installation)
- protoc-gen-go: `go install google.golang.org/protobuf/cmd/protoc-gen-go@latest`
- protoc-gen-connect-go: `go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest`
- sqlc: [https://docs.sqlc.dev/en/stable/overview/install.html](https://docs.sqlc.dev/en/stable/overview/install.html)
- migrate: [https://github.com/golang-migrate/migrate/tree/master/cmd/migrate](https://github.com/golang-migrate/migrate/tree/master/cmd/migrate)

### Software that helps:

- Beekeeper Studio: [https://www.beekeeperstudio.io/](https://www.beekeeperstudio.io/)

## Generating connectRPC code from prot files

```bash
buf lint
buf generate
```

---

> [!WARNING]
>
> **⚠️ Archived**  
> This repository is no longer actively maintained. Jadwal was successfully completed and presented in May 2025 as a fully working system.

# 🗓️ Jadwal – LLM-Powered Calendar Agent (Archived)

> Jadwal is an intelligent scheduling system that extracts events from WhatsApp conversations using LLMs, syncs with calendars via CalDAV, and provides a native mobile experience.  
> Built for busy people — students, professionals, or anyone drowning in unstructured messages.

✅ Fully implemented and deployed  
📦 Stack: Go, Docker, ConnectRPC, SQLC, PlantUML  
📱 iOS frontend, backend APIs, WhatsApp integration, CalDAV sync  
📁 Archived after successful delivery — project is complete and stable

📄 [Read the full graduation project report (PDF)](./docs/report/report.pdf)

---

# symmetrical spoon

you know, something :D

## Requirements

- Docker: [https://docker.com](https://docker.com)
- Golang: [https://go.dev/](https://go.dev/)
- Taskfile: [https://taskfile.dev/](https://taskfile.dev/)
- buf cli: [https://buf.build/docs/installation](https://buf.build/docs/installation)
- protoc-gen-go: `go install google.golang.org/protobuf/cmd/protoc-gen-go@latest`
- protoc-gen-connect-go: `go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest`
- sqlc (v1.28.0): [https://docs.sqlc.dev/en/stable/overview/install.html](https://docs.sqlc.dev/en/stable/overview/install.html)
- migrate: [https://github.com/golang-migrate/migrate/tree/master/cmd/migrate](https://github.com/golang-migrate/migrate/tree/master/cmd/migrate)

### Software that helps:

- Beekeeper Studio: [https://www.beekeeperstudio.io/](https://www.beekeeperstudio.io/)

## Generating connectRPC code from proto files

```bash
buf lint
buf generate
```

## To generate diagrams using PlantUML locally

```bash
docker run --rm -p 8094:8080 plantuml/plantuml-server:jetty
```

## Setting up APNS Certificate

To use APNS (Apple Push Notification Service), you'll need to convert your .p8 certificate file to base64 and set it as an environment variable:

1. Convert your .p8 file to base64:

```bash
base64 -i AuthKey_XXXXX.p8
```

2. Set the base64 string as an environment variable:

```bash
export APNS_AUTH_KEY="YOUR_BASE64_STRING_HERE"
```

Or add it to your `.env` file:

```
APNS_AUTH_KEY=YOUR_BASE64_STRING_HERE
```

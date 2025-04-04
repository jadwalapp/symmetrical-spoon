# falak

## JWT Token Keys Generation:

Start by generating the key using openssl:

```
openssl genpkey -algorithm RSA -out falak-dev-private.pem -pkeyopt rsa_keygen_bits:4096
openssl rsa -pubout -in falak-dev-private.pem -out falak-dev-public.pem
base64 -i falak-dev-public.pem > falak-dev-public.pem.base64
base64 -i falak-dev-private.pem > falak-dev-private.pem.base64
```

Finally, update your `/.env` file with the keys.

For additional steps and details, consult the main repository's README.

## Running the project :D

```bash
go run cmd/main.go
```

But better to use the `compose.yaml`, so run:

```bash
docker compose up --build
```

Then to test the api, you need `grpcui`:

```bash
go install github.com/fullstorydev/grpcui/cmd/grpcui@latest
```

After you install it, run the following to get a web interface to call the api:

```bash
grpcui -plaintext falak.localhost:80
```

> life is cool, it is indeed, alhamdulillah

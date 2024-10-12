# falak

- you need to make a copy of `grpc.env.example` and put it in `grpc.env`, then fill the values.

## JWT Token Keys Generation:

Start by generating the key using openssl:

```
openssl genpkey -algorithm RSA -out falak-dev-private.pem -pkeyopt rsa_keygen_bits:4096
openssl rsa -pubout -in falak-dev-private.pem -out falak-dev-public.pem
base64 -i falak-dev-public.pem > falak-dev-public.pem.base64
base64 -i falak-dev-private.pem > falak-dev-private.pem.base64
```

Finally, update your `grpc.env` file with the keys.

For additional steps and details, consult the main repository's README.

## Running the project :D

```bash
go run cmd/main.go
```

Then to test the api, you need `grpcui`:

```bash
go install github.com/fullstorydev/grpcui/cmd/grpcui@latest
```

After you install it, run the following to get a web interface to call the api:

```bash
grpcui -plaintext localhost:50064
```

> If you replaced the `PORT` in `app.env`, you will need to change the `50064` to that port :D

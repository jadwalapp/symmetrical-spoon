FROM oven/bun:1.2.1-alpine

RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    git

WORKDIR /app
COPY . .
RUN bun install

CMD [ "bun", "main.ts" ]
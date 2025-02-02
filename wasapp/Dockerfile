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

# Additional dependencies as a separate layer
RUN apk add --no-cache \
    harfbuzz \
    ttf-freefont \
    alsa-lib \
    gtk+3.0 \
    libx11 \
    libxcomposite \
    libxdamage \
    libxext \
    libxfixes \
    libxrandr \
    libxrender \
    pango \
    cairo \
    cups-libs \
    dbus-libs

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR /app
COPY . .
RUN bun install

CMD [ "bun", "main.ts" ]
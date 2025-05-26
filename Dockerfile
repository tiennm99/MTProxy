# Build stage
FROM debian:10.13-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and build MTProxy
WORKDIR /app
RUN git clone https://github.com/TelegramMessenger/MTProxy.git .

# Build MTProxy
RUN make

# Runtime stage
FROM debian:10.13-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl1.1 \
    zlib1g \
    curl \
    vim-common \
    && rm -rf /var/lib/apt/lists/*

# Copy built binary from builder stage
COPY --from=builder /app/objs/bin/mtproto-proxy /usr/local/bin/

# Create non-root user
RUN useradd -r -s /bin/false mtproxy

# Create working directory
WORKDIR /data

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose ports
# - 443: Public port for MTProto proxy
# - 8888: Stats and configuration port (internal)
EXPOSE 443 8888

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command (can be overridden in docker-compose)
CMD ["mtproto-proxy", "-p", "8888", "-H", "443", "-M", "1", "--aes-pwd", "/data/proxy-secret", "/data/proxy-multi.conf"]

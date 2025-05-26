# Build stage
FROM debian:bullseye-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy local source code
WORKDIR /app
COPY . .

# Build MTProxy
RUN make && make install

# Runtime stage
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl1.1 \
    zlib1g \
    curl \
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
# - 2398: Stats and configuration port (internal)
EXPOSE 443 2398

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command (can be overridden in docker-compose)
CMD ["mtproto-proxy", "-u", "mtproxy", "-p", "2398", "-H", "443", "--aes-pwd", "/data/proxy-secret", "/data/proxy-multi.conf", "-M", "1"]

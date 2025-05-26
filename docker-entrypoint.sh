#!/bin/sh
set -e

# Increase file descriptor limits
ulimit -n 51200

# Create data directory if it doesn't exist
mkdir -p /data
cd /data

# Download proxy configuration files if they don't exist
if [ ! -f /data/proxy-secret ] || [ ! -f /data/proxy-multi.conf ]; then
    echo "Downloading proxy configuration files..."
    curl -s https://core.telegram.org/getProxySecret -o /data/proxy-secret
    curl -s https://core.telegram.org/getProxyConfig -o /data/proxy-multi.conf
fi

# Set permissions
chmod 644 /data/proxy-secret /data/proxy-multi.conf

# Generate secret if not provided
if [ -z "$SECRET" ]; then
    echo "Generating random secret..."
    SECRET=$(head -c 16 /dev/urandom | xxd -ps)
    echo "Generated secret: $SECRET"
    echo "You can use this link to connect: tg://proxy?server=$(hostname -i)&port=443&secret=dd$SECRET"
fi

# Build command arguments
CMD_ARGS="-p 8888 -H 443 -M ${WORKERS:-1} -S $SECRET --aes-pwd /data/proxy-secret /data/proxy-multi.conf"

# Add proxy tag if provided
if [ -n "$TAG" ]; then
    CMD_ARGS="$CMD_ARGS -P $TAG"
fi

echo "Starting MTProxy with arguments: $CMD_ARGS"

exec mtproto-proxy $CMD_ARGS
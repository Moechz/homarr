#!/bin/bash
set -e
set -u
mkdir -p /appdata/db /appdata/redis /appdata/trusted-certificates
F=/appdata/encryption_key
if [ ! -s "$F" ]; then
  head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$F"
fi
export SECRET_ENCRYPTION_KEY="$(cat "$F")"
if [ "${DB_MIGRATIONS_DISABLED:-false}" != "true" ]; then
  node ./db/migrations/$DB_DIALECT/migrate.cjs ./db/migrations/$DB_DIALECT
fi
export AUTH_SECRET=$(openssl rand -base64 32)
redis-server /app/redis.conf --protected-mode yes --daemonize yes
export HOSTNAME=0.0.0.0
export PORT=7575
exec node apps/nextjs/server.js

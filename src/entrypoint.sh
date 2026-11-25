#!/bin/sh
# ===========================================================================
# TOS wrapper entrypoint for Homarr.
#
# The upstream image starts as root, chowns its writable directories and then
# drops to PUID/PGID with setpriv.  The TOS package runs the container as
# 1000:1000 from the first process (no root at any point), and the installer
# chowns the mounted data directory to that user, so the chown step is not
# needed here.  This script reproduces the rest of the upstream startup:
#
#   * persistent SECRET_ENCRYPTION_KEY (generated once, kept on the volume)
#   * SQLite migrations
#   * nginx on 7575 -> Next.js on 3000 and /websockets -> 3001
#   * redis and the Next.js standalone server
#
# Running nginx matters: the upstream image serves the UI through nginx, which
# also proxies the WebSocket endpoint.  Starting Next.js directly on 7575 (as
# earlier packaging iterations did) leaves /websockets unhandled.
# ===========================================================================
set -e
set -u

# Keep the database, the encryption key and the redis dump private.
umask 077

mkdir -p /appdata/db /appdata/redis /appdata/trusted-certificates

# --- persistent encryption key ---------------------------------------------
F=/appdata/encryption_key
if [ ! -s "$F" ]; then
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$F"
    chmod 600 "$F"
fi
SECRET_ENCRYPTION_KEY="$(cat "$F")"
export SECRET_ENCRYPTION_KEY

# --- database migrations ---------------------------------------------------
if [ "${DB_MIGRATIONS_DISABLED:-false}" != "true" ]; then
    echo "Running DB migrations"
    DISABLE_REDIS_LOGS=true node ./db/migrations/"$DB_DIALECT"/migrate.cjs ./db/migrations/"$DB_DIALECT" || {
        echo "ERROR: DB migrations failed, aborting startup"
        exit 1
    }
fi

# --- secrets and request identity ------------------------------------------
AUTH_SECRET="$(openssl rand -base64 32)"
export AUTH_SECRET
HOMARR_REQUEST_IDENTITY_SECRET="$(openssl rand -hex 32)"
export HOMARR_REQUEST_IDENTITY_SECRET
NGINX_TRUSTED_PROXIES="$(node ./scripts/trusted-proxies.mjs)" || exit 1
export NGINX_TRUSTED_PROXIES

# --- nginx -----------------------------------------------------------------
NGINX_LISTEN_IPV6=''
if [ "${HOMARR_DISABLE_IPV6:-false}" != "true" ] && grep -q . /proc/net/if_inet6 2>/dev/null; then
    NGINX_LISTEN_IPV6='listen [::]:7575;'
fi
NGINX_USER=''
export NGINX_USER NGINX_LISTEN_IPV6

envsubst '${NGINX_USER} ${NGINX_LISTEN_IPV6} ${NGINX_TRUSTED_PROXIES} ${HOMARR_REQUEST_IDENTITY_SECRET}' \
    < /etc/nginx/templates/nginx.conf > /tmp/nginx.conf
# The image ships root-owned log files; logs go to stdout/stderr instead.
sed -e 's|^http {|http {\n    access_log off;\n    error_log /dev/stderr warn;|' \
    /tmp/nginx.conf > /tmp/nginx.conf.new
mv /tmp/nginx.conf.new /tmp/nginx.conf
nginx -t -c /tmp/nginx.conf -g 'pid /tmp/nginx.pid;' || exit 1
nginx -c /tmp/nginx.conf -g 'daemon off; pid /tmp/nginx.pid;' &
NGINX_PID=$!

# --- redis -----------------------------------------------------------------
redis-server /app/redis.conf --protected-mode yes &
REDIS_PID=$!

# --- Next.js ---------------------------------------------------------------
# nginx proxies to 127.0.0.1:3000; the websocket server listens on 3001.
HOSTNAME=127.0.0.1
PORT=3000
export HOSTNAME PORT
NODE_OPTIONS="--max-semi-space-size=4 ${NODE_OPTIONS:-}"
export NODE_OPTIONS
node apps/nextjs/server.js &
NEXTJS_PID=$!

# --- shutdown --------------------------------------------------------------
SHUTTING_DOWN=false
shutdown() {
    SHUTTING_DOWN=true
    echo "Shutting down"
    kill -TERM "$NEXTJS_PID" "$REDIS_PID" "$NGINX_PID" 2>/dev/null || true
    wait 2>/dev/null || true
    exit 0
}
trap shutdown TERM INT

while true; do
    wait "$NEXTJS_PID"
    EXIT_CODE=$?
    if [ "$SHUTTING_DOWN" = true ]; then
        exit 0
    fi
    echo "Next.js exited with code $EXIT_CODE, restarting in 1s..."
    sleep 1
    node apps/nextjs/server.js &
    NEXTJS_PID=$!
done

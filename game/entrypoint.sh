#!/bin/bash
set -e

echo "============================================================"
echo "    Ragnarok M: Eternal Love - Game Container Startup       "
echo "============================================================"

DB_HOST=${DB_HOST:-db}
REDIS_HOST=${REDIS_HOST:-redis}

# 1. Start Localhost Bridges via socat
# The C++ binaries and trade-server connect to 127.0.0.1:3306 and 127.0.0.1:6379.
# We bridge 127.0.0.1 to the Docker container network.
echo "[*] Setting up internal 127.0.0.1 bridges to ${DB_HOST}:3306 and ${REDIS_HOST}:6379..."
socat TCP-LISTEN:3306,fork,reuseaddr,bind=127.0.0.1 TCP:${DB_HOST}:3306 &
SOCAT_DB_PID=$!

socat TCP-LISTEN:6379,fork,reuseaddr,bind=127.0.0.1 TCP:${REDIS_HOST}:6379 &
SOCAT_REDIS_PID=$!

# 2. Wait for MySQL to be ready
echo "[*] Waiting for MySQL (${DB_HOST}:3306) to be healthy..."
while ! timeout 1 bash -c "cat < /dev/null > /dev/tcp/${DB_HOST}/3306" 2>/dev/null; do
    sleep 1
done
echo "[+] MySQL is reachable!"

# 3. Wait for Redis to be ready
echo "[*] Waiting for Redis (${REDIS_HOST}:6379) to be healthy..."
while ! timeout 1 bash -c "cat < /dev/null > /dev/tcp/${REDIS_HOST}/6379" 2>/dev/null; do
    sleep 1
done
echo "[+] Redis is reachable!"

# 4. Verify Server Directory
if [ ! -d "/RoServercode/bin/Release" ]; then
    echo "[!] ERROR: /RoServercode/bin/Release not found!"
    echo "    Make sure ./server is mounted properly."
    exit 1
fi

cd /RoServercode/bin/Release
echo "/RoServercode/libso" > /etc/ld.so.conf.d/ro_libs.conf
echo "/RoServercode/bin/Release" >> /etc/ld.so.conf.d/ro_libs.conf
ldconfig 2>/dev/null || true
export LD_LIBRARY_PATH=/RoServercode/libso:/RoServercode/bin/Release:/usr/local/lib:$LD_LIBRARY_PATH

# Ensure permissions on binaries and scripts
chmod +x /RoServercode/bin/Release/go /RoServercode/bin/Release/*Server 2>/dev/null || true

# Ensure trade log directory exists
mkdir -p /RoServercode/bin/Release/trade/log

# Clean up previous temporary logs
rm -rf /RoServercode/bin/Release/log 2>/dev/null || true

# 5. Trap signals for graceful container shutdown
shutdown_servers() {
    echo ""
    echo "[*] Shutting down Ragnarok M Game Servers gracefully..."
    pkill -2 SuperServer 2>/dev/null || true
    sleep 2
    pkill -2 Server 2>/dev/null || true
    ps -ef | grep 'trade-server' | grep -v grep | awk '{print $2}' | xargs -r kill 2>/dev/null || true
    sleep 3
    echo "[+] Game servers stopped cleanly."
    kill $SOCAT_DB_PID 2>/dev/null || true
    kill $SOCAT_REDIS_PID 2>/dev/null || true
    exit 0
}

trap shutdown_servers SIGTERM SIGINT

# 6. Launch Game Servers & Trade Server
echo "[*] Launching 21 C++ Game Servers and PHP Trade Server daemon..."
./go xd r2 s1

echo "[+] Startup sequence initiated. Monitoring logs..."

# Stream TradeServer logs in background (non-blocking, won't crash container on Windows NTFS mount)
touch /RoServercode/bin/Release/trade/log/log.txt 2>/dev/null || true
tail -F -n 50 /RoServercode/bin/Release/trade/log/log.txt 2>/dev/null &

# Keep container running indefinitely and handle shutdown signals cleanly
while true; do
    sleep 3600 &
    wait $!
done

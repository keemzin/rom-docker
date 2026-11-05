#!/bin/bash
# ==============================================================================
# Ragnarok M: Eternal Love - One-Click Downloader & Extractor (Linux / VPS)
# Run this on your destination Linux machine to fetch exported data from rom-vm
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_ROM_DIR="$(dirname "$SCRIPT_DIR")"

SOURCE_HOST="${1:-rom-vm}"

echo "============================================================"
echo " Ragnarok M Docker Importer: $SOURCE_HOST -> docker-rom"
echo " Target Directory: $DOCKER_ROM_DIR"
echo "============================================================"

DB_INIT_DIR="$DOCKER_ROM_DIR/db/init"
WEB_DIR="$DOCKER_ROM_DIR/web/wwwroot"
SERVER_DIR="$DOCKER_ROM_DIR/server"

mkdir -p "$DB_INIT_DIR" "$WEB_DIR" "$SERVER_DIR"

TEMP_DOWNLOAD="$DOCKER_ROM_DIR/temp_export"
mkdir -p "$TEMP_DOWNLOAD"

echo ""
echo "[1/4] Downloading MySQL Dumps..."
scp "$SOURCE_HOST:/home/rom_export/01_ro_global.sql" "$DB_INIT_DIR/01_ro_global.sql"
scp "$SOURCE_HOST:/home/rom_export/02_ro_xd_r2.sql" "$DB_INIT_DIR/02_ro_xd_r2.sql"
echo "   [+] Database dumps copied into db/init"

echo ""
echo "[2/4] Downloading & Extracting Web Root (/www/wwwroot)..."
scp "$SOURCE_HOST:/home/rom_export/web_wwwroot.tar.gz" "$TEMP_DOWNLOAD/web_wwwroot.tar.gz"
tar -xzf "$TEMP_DOWNLOAD/web_wwwroot.tar.gz" -C "$WEB_DIR"
rm -f "$TEMP_DOWNLOAD/web_wwwroot.tar.gz"
echo "   [+] Web portal files extracted into web/wwwroot"

echo ""
echo "[3/4] Downloading & Extracting Server Code (/RoServercode)..."
scp "$SOURCE_HOST:/home/rom_export/server_code.tar.gz" "$TEMP_DOWNLOAD/server_code.tar.gz"
tar -xzf "$TEMP_DOWNLOAD/server_code.tar.gz" -C "$SERVER_DIR"
rm -f "$TEMP_DOWNLOAD/server_code.tar.gz"
echo "   [+] Server binaries & configs extracted into server/"

rm -rf "$TEMP_DOWNLOAD"

echo ""
echo "============================================================"
echo " SUCCESS: All files are now in place!"
echo " To start the docker stack on this machine:"
echo "   cd $DOCKER_ROM_DIR"
echo "   docker compose up -d"
echo "============================================================"

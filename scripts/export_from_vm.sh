#!/bin/bash
# ==============================================================================
# Ragnarok M: Eternal Love - One-Click Server Export Script
# Run this on your CentOS VM (rom-vm) to extract everything needed for Docker.
# ==============================================================================
set -e

# Use /home/rom_export because /home has 19GB free, whereas / only has ~5GB.
EXPORT_DIR="/home/rom_export"
mkdir -p "$EXPORT_DIR"

echo "============================================================"
echo "      Ragnarok M Export for Docker Setup                    "
echo "============================================================"
echo "Output Directory: $EXPORT_DIR"
echo ""

# 1. Dump MySQL Databases
echo "[1/3] Dumping MySQL databases (ro_global & ro_xd_r2)..."
mysqldump -uroot -p123456 \
    --single-transaction \
    --quick \
    --routines \
    --triggers \
    --databases ro_global > "$EXPORT_DIR/01_ro_global.sql"
echo "   [+] ro_global exported: $(du -h $EXPORT_DIR/01_ro_global.sql | awk '{print $1}')"

mysqldump -uroot -p123456 \
    --single-transaction \
    --quick \
    --routines \
    --triggers \
    --databases ro_xd_r2 > "$EXPORT_DIR/02_ro_xd_r2.sql"
echo "   [+] ro_xd_r2 exported: $(du -h $EXPORT_DIR/02_ro_xd_r2.sql | awk '{print $1}')"

# 2. Package Web Files (/www/wwwroot)
echo "[2/3] Archiving Web Portal and GM Tools (/www/wwwroot)..."
tar --exclude='*.tar.gz' --exclude='*.zip' \
    -czf "$EXPORT_DIR/web_wwwroot.tar.gz" -C /www/wwwroot .
echo "   [+] web_wwwroot.tar.gz created: $(du -h $EXPORT_DIR/web_wwwroot.tar.gz | awk '{print $1}')"

# 3. Package Game Server Code (/RoServercode)
# Exclude obj/ (2GB of intermediate compiler object files) and old logs to save space
echo "[3/3] Archiving Game Server Binaries & Tables (/RoServercode)..."
tar --exclude='obj' --exclude='log' --exclude='*.o' \
    -czf "$EXPORT_DIR/server_code.tar.gz" -C /RoServercode .
echo "   [+] server_code.tar.gz created: $(du -h $EXPORT_DIR/server_code.tar.gz | awk '{print $1}')"

echo ""
echo "============================================================"
echo "               EXPORT COMPLETE!                             "
echo "============================================================"
ls -lh "$EXPORT_DIR"
echo ""
echo "Next step: Copy these files to your new machine's docker-rom folder:"
echo "  1. Copy 01_ro_global.sql & 02_ro_xd_r2.sql -> docker-rom/db/init/"
echo "  2. Extract web_wwwroot.tar.gz              -> docker-rom/web/wwwroot/"
echo "  3. Extract server_code.tar.gz              -> docker-rom/server/"
echo "============================================================"

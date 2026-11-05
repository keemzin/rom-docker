# ==============================================================================
# Ragnarok M: Eternal Love - One-Click Downloader & Extractor
# Run this on your local Windows PC to fetch exported data from rom-vm
# ==============================================================================

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DOCKER_ROM_DIR = Split-Path -Parent $SCRIPT_DIR

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Ragnarok M Docker Importer: rom-vm -> docker-rom" -ForegroundColor Cyan
Write-Host " Target Directory: $DOCKER_ROM_DIR" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Ensure destination folders exist
$DB_INIT_DIR = Join-Path $DOCKER_ROM_DIR "db\init"
$WEB_DIR = Join-Path $DOCKER_ROM_DIR "web\wwwroot"
$SERVER_DIR = Join-Path $DOCKER_ROM_DIR "server"

New-Item -ItemType Directory -Force -Path $DB_INIT_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $WEB_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $SERVER_DIR | Out-Null

$TEMP_DOWNLOAD = Join-Path $DOCKER_ROM_DIR "temp_export"
New-Item -ItemType Directory -Force -Path $TEMP_DOWNLOAD | Out-Null

Write-Host "`n[1/4] Downloading MySQL Dumps..." -ForegroundColor Yellow
scp -o BatchMode=yes rom-vm:/home/rom_export/01_ro_global.sql "$DB_INIT_DIR\01_ro_global.sql"
scp -o BatchMode=yes rom-vm:/home/rom_export/02_ro_xd_r2.sql "$DB_INIT_DIR\02_ro_xd_r2.sql"
Write-Host "   [+] Database dumps copied into db\init" -ForegroundColor Green

Write-Host "`n[2/4] Downloading & Extracting Web Root (/www/wwwroot)..." -ForegroundColor Yellow
$WEB_ARCHIVE = Join-Path $TEMP_DOWNLOAD "web_wwwroot.tar.gz"
scp -o BatchMode=yes rom-vm:/home/rom_export/web_wwwroot.tar.gz "$WEB_ARCHIVE"
tar -xzf "$WEB_ARCHIVE" -C "$WEB_DIR"
Remove-Item -Force "$WEB_ARCHIVE"
Write-Host "   [+] Web portal files extracted into web\wwwroot" -ForegroundColor Green

Write-Host "`n[3/4] Downloading & Extracting Server Code (/RoServercode)..." -ForegroundColor Yellow
$SERVER_ARCHIVE = Join-Path $TEMP_DOWNLOAD "server_code.tar.gz"
scp -o BatchMode=yes rom-vm:/home/rom_export/server_code.tar.gz "$SERVER_ARCHIVE"
tar -xzf "$SERVER_ARCHIVE" -C "$SERVER_DIR"
Remove-Item -Force "$SERVER_ARCHIVE"
Write-Host "   [+] Server binaries & configs extracted into server\" -ForegroundColor Green

Remove-Item -Recurse -Force "$TEMP_DOWNLOAD"

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " SUCCESS: All files are now in place!" -ForegroundColor Green
Write-Host " To start the docker stack on this machine or target host:" -ForegroundColor White
Write-Host "   cd $DOCKER_ROM_DIR" -ForegroundColor White
Write-Host "   docker compose up -d" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

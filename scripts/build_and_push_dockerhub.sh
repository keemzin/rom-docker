#!/bin/bash
set -e

USERNAME=${1:-johnsdoes}

echo "============================================================"
echo "   Ragnarok M - Build & Push Base Images ($USERNAME)        "
echo "============================================================"

echo ""
echo "[*] Building Base Images..."
docker build -t "$USERNAME/rom-game:base" ./game
docker build -t "$USERNAME/rom-web:base" ./web

echo ""
echo "[*] Pushing Base Images to Docker Hub..."
docker push "$USERNAME/rom-game:base"
docker push "$USERNAME/rom-web:base"
echo "[+] Base Images Pushed Successfully!"

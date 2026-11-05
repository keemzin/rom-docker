#!/bin/bash
set -e

MODE=${1:-base}
USERNAME=${2:-johnsdoes}

echo "============================================================"
echo "   Ragnarok M - Build & Push to Docker Hub ($USERNAME)      "
echo "============================================================"

if [ "$MODE" = "base" ] || [ "$MODE" = "all" ]; then
    echo ""
    echo "[*] Building Base Images (Developer Mode)..."
    docker build -t "$USERNAME/rom-game:base" ./game
    docker build -t "$USERNAME/rom-web:base" ./web

    echo ""
    echo "[*] Pushing Base Images to Docker Hub..."
    docker push "$USERNAME/rom-game:base"
    docker push "$USERNAME/rom-web:base"
    echo "[+] Base Images Pushed Successfully!"
fi

if [ "$MODE" = "full" ] || [ "$MODE" = "all" ]; then
    echo ""
    echo "[*] Building Full Images (1-Click Play Mode)..."
    docker build -f game/Dockerfile.full -t "$USERNAME/rom-game:full" .
    docker build -f web/Dockerfile.full -t "$USERNAME/rom-web:full" .
    docker build -f db/Dockerfile.full -t "$USERNAME/rom-db:full" .

    echo ""
    echo "[*] Pushing Full Images to Docker Hub..."
    docker push "$USERNAME/rom-game:full"
    docker push "$USERNAME/rom-web:full"
    docker push "$USERNAME/rom-db:full"
    echo "[+] Full Images Pushed Successfully!"
fi

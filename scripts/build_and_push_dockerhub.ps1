param (
    [string]$Username = "johnsdoes"
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Ragnarok M - Build & Push Base Images ($Username)        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "`n[*] Building Base Images..." -ForegroundColor Yellow
docker build -t "$Username/rom-game:base" ./game
docker build -t "$Username/rom-web:base" ./web

Write-Host "`n[*] Pushing Base Images to Docker Hub..." -ForegroundColor Yellow
docker push "$Username/rom-game:base"
docker push "$Username/rom-web:base"
Write-Host "[+] Base Images Pushed Successfully!" -ForegroundColor Green

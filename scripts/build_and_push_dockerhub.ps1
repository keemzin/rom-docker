param (
    [ValidateSet("base", "full", "all")]
    [string]$Mode = "base",
    [string]$Username = "johnsdoes"
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Ragnarok M - Build & Push to Docker Hub ($Username)      " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if ($Mode -eq "base" -or $Mode -eq "all") {
    Write-Host "`n[*] Building Base Images (Developer Mode)..." -ForegroundColor Yellow
    docker build -t "$Username/rom-game:base" ./game
    docker build -t "$Username/rom-web:base" ./web

    Write-Host "`n[*] Pushing Base Images to Docker Hub..." -ForegroundColor Yellow
    docker push "$Username/rom-game:base"
    docker push "$Username/rom-web:base"
    Write-Host "[+] Base Images Pushed Successfully!" -ForegroundColor Green
}

if ($Mode -eq "full" -or $Mode -eq "all") {
    Write-Host "`n[*] Building Full Images (1-Click Play Mode)..." -ForegroundColor Yellow
    docker build -f game/Dockerfile.full -t "$Username/rom-game:full" .
    docker build -f web/Dockerfile.full -t "$Username/rom-web:full" .
    docker build -f db/Dockerfile.full -t "$Username/rom-db:full" .

    Write-Host "`n[*] Pushing Full Images to Docker Hub..." -ForegroundColor Yellow
    docker push "$Username/rom-game:full"
    docker push "$Username/rom-web:full"
    docker push "$Username/rom-db:full"
    Write-Host "[+] Full Images Pushed Successfully!" -ForegroundColor Green
}

# Build and Package Client-Ready Release Bundle
$ErrorActionPreference = "Stop"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   NextGen Billing Software - Client Package Builder     " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$rootDir = "E:\NG-Billing Software"
$distDir = "$rootDir\NextGen_Billing_App_v1.0"
$desktopZip = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "NextGen_Billing_Software_v1.0.zip")

Write-Host "`n[1/5] Updating distribution folder..." -ForegroundColor Yellow
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

# Copy Flutter binaries
Write-Host "[2/5] Copying compiled application files..." -ForegroundColor Yellow
Copy-Item "$rootDir\build\windows\x64\runner\Release\*" -Destination $distDir -Recurse -Force

# Copy database
Write-Host "[3/5] Pre-bundling database with categories and products..." -ForegroundColor Yellow
if (Test-Path "$rootDir\.dart_tool\sqflite_common_ffi\databases\nextgen_billing.db") {
    Copy-Item "$rootDir\.dart_tool\sqflite_common_ffi\databases\nextgen_billing.db" -Destination "$distDir\nextgen_billing.db" -Force
}

# Copy Python voice backend (excluding pycache)
Write-Host "[4/5] Copying Python AI Voice Server & Environment..." -ForegroundColor Yellow
if (-not (Test-Path "$distDir\python_voice_server")) {
    New-Item -ItemType Directory -Path "$distDir\python_voice_server" | Out-Null
}
Copy-Item "$rootDir\python_voice_server\*" -Destination "$distDir\python_voice_server" -Recurse -Force -Exclude "__pycache__"

# Copy Launchers and Manuals
Copy-Item "$rootDir\Launch_NextGen_Billing.vbs" -Destination "$distDir\Launch_NextGen_Billing.vbs" -Force
Copy-Item "$rootDir\Start_NextGen_Billing.bat" -Destination "$distDir\Start_NextGen_Billing.bat" -Force
Copy-Item "$rootDir\CLIENT_USER_MANUAL.txt" -Destination "$distDir\CLIENT_USER_MANUAL.txt" -Force

# Create Zip Archive on Desktop
Write-Host "[5/5] Creating 1-Click ZIP Package on Desktop..." -ForegroundColor Yellow
if (Test-Path $desktopZip) {
    Remove-Item $desktopZip -Force
}
Compress-Archive -Path "$distDir\*" -DestinationPath $desktopZip -CompressionLevel Optimal

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   SUCCESS! Package Created at:" -ForegroundColor Green
Write-Host "   $desktopZip" -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Green

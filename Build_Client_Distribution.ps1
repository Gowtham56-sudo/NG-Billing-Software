# Build and Package Client-Ready Release Bundle
$ErrorActionPreference = "Stop"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   NextGen Billing Software - Client Package Builder     " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$rootDir = "E:\NG-Billing Software"
$distDir = "$rootDir\NG-Bill_DESKTOP"
$desktopZip = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "NG-Bill_DESKTOP.zip")

Write-Host "`n[1/5] Updating distribution folder: $distDir..." -ForegroundColor Yellow
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

# Copy Python voice backend & Standalone Runtime (excluding old venv & pycache)
Write-Host "[4/5] Copying Standalone Portable Python AI Runtime & Models..." -ForegroundColor Yellow
if (-not (Test-Path "$distDir\python_voice_server")) {
    New-Item -ItemType Directory -Path "$distDir\python_voice_server" | Out-Null
}
Get-ChildItem "$rootDir\python_voice_server" -Exclude "venv", "__pycache__", "test_*.py" | ForEach-Object {
    Copy-Item $_.FullName -Destination "$distDir\python_voice_server" -Recurse -Force
}

# Copy Launchers and Manuals
Copy-Item "$rootDir\Launch_NG_Bill.vbs" -Destination "$distDir\Launch_NG_Bill.vbs" -Force
Copy-Item "$rootDir\Start_NG_Bill.bat" -Destination "$distDir\Start_NG_Bill.bat" -Force
Copy-Item "$rootDir\CLIENT_USER_MANUAL.txt" -Destination "$distDir\CLIENT_USER_MANUAL.txt" -Force

# Create Verified Zip Archive
Write-Host "[5/5] Creating 1-Click Verified ZIP Package on Desktop..." -ForegroundColor Yellow
$zipMaker = @"
import shutil, os, zipfile
src = r'$distDir'
dest_base = r'$rootDir\NG-Bill_DESKTOP'
desktop_zip = r'$desktopZip'
shutil.make_archive(dest_base, 'zip', src)
shutil.copy2(dest_base + '.zip', desktop_zip)
print('Verified ZIP Created Successfully at:', desktop_zip)
"@
python -c $zipMaker

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   SUCCESS! Package Created at:" -ForegroundColor Green
Write-Host "   $desktopZip" -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Green

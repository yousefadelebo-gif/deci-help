param(
  [switch]$SkipFlutter
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Starting backend..."
Set-Location (Join-Path $root "backend")

if (-not (Test-Path ".venv\Scripts\python.exe")) {
  python -m venv .venv
}

& ".venv\Scripts\python.exe" -m pip install -r requirements.txt
& ".venv\Scripts\python.exe" manage.py migrate

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd `"$PWD`"; .\.venv\Scripts\python.exe manage.py runserver"

if (-not $SkipFlutter) {
  Write-Host "Starting Flutter app..."
  Set-Location (Join-Path $root "App")
  flutter pub get
  Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd `"$PWD`"; flutter run"
}

Write-Host "System startup triggered."

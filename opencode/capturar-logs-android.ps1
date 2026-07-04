# Captura logs de Flutter en un dispositivo Android conectado.
# Uso: .\opencode\capturar-logs-android.ps1
# El archivo de salida se guarda en opencode/logs-android-<timestamp>.txt

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}
$outputFile = Join-Path $outDir "logs-android-$timestamp.txt"

Write-Host "Verificando dispositivo Android conectado..."
$devices = & adb devices | Select-String -Pattern "device$" | ForEach-Object { $_.ToString().Trim() }
if (-not $devices) {
    Write-Error "No se detecto ningun dispositivo Android. Conecta el telefono y habilita la depuracion USB."
    exit 1
}

Write-Host "Dispositivos detectados:"
$devices | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "Limpiando logs antiguos para tener una ventana limpia..."
& adb logcat -c

Write-Host ""
Write-Host "Capturando logs. Presiona Ctrl+C para detener."
Write-Host "Salida guardada en: $outputFile"
Write-Host ""

# Capturamos tanto flutter logs como adb logcat.
# flutter logs muestra los print() de Dart; adb logcat muestra logs nativos de Bluetooth, etc.
Start-Process -FilePath "flutter" -ArgumentList "logs" -NoNewWindow -RedirectStandardOutput $outputFile

# Despues de unos segundos, tambien empezamos a capturar logcat con filtro util.
Start-Sleep -Seconds 3
& adb logcat -v threadtime *:D | Tee-Object -FilePath ($outputFile -replace "\.txt$", "-logcat.txt")

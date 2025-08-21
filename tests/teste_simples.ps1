# Script simples para testar DIMEX
Write-Host "=== TESTE SIMPLES DIMEX ===" -ForegroundColor Green

# Compila o projeto
Write-Host "Compilando..." -ForegroundColor Yellow
go build -o dimex_test.exe useDIMEX-f.go

# Cria pasta logs se não existir
if (!(Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

# Inicia os 3 processos em background
Write-Host "Iniciando 3 processos..." -ForegroundColor Yellow

Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_test.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal
Start-Sleep 3
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_test.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal
Start-Sleep 3
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_test.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Write-Host "Processos iniciados! Aguardando 30 segundos..." -ForegroundColor Green
Start-Sleep 30

# Verifica resultados
Write-Host "Verificando resultados..." -ForegroundColor Yellow
if (Test-Path "logs/mxOUT.txt") {
    $content = Get-Content "logs/mxOUT.txt" -Raw
    Write-Host "mxOUT.txt tem $($content.Length) caracteres" -ForegroundColor Green
    Write-Host "Últimos 20 caracteres: $($content.Substring([Math]::Max(0, $content.Length - 20)))" -ForegroundColor Cyan
} else {
    Write-Host "mxOUT.txt não foi criado!" -ForegroundColor Red
}

$snapshots = Get-ChildItem "logs/snapshot_*.json" -ErrorAction SilentlyContinue
Write-Host "Encontrados $($snapshots.Count) snapshots" -ForegroundColor Green

# Para os processos
Write-Host "Parando processos..." -ForegroundColor Yellow
Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Teste concluído!" -ForegroundColor Green 
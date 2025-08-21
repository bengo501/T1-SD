# Script para executar DIMEX com snapshot e análise
Write-Host "=== SISTEMA DIMEX COM SNAPSHOT ===" -ForegroundColor Green
Write-Host ""

# Limpa logs anteriores
Write-Host "Limpando logs anteriores..." -ForegroundColor Yellow
if (Test-Path "logs") {
    Remove-Item "logs\*" -Force
}

# Compila o projeto
Write-Host "Compilando o projeto..." -ForegroundColor Yellow
go build -o bin/dimex_test.exe src/useDIMEX-f.go
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro na compilação!" -ForegroundColor Red
    exit 1
}
Write-Host "Compilação concluída!" -ForegroundColor Green

# Cria pasta logs se não existir
if (!(Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

Write-Host ""
Write-Host "Iniciando DIMEX com 3 processos + snapshot..." -ForegroundColor Cyan
Write-Host "O processo 0 irá iniciar snapshots a cada 2 segundos" -ForegroundColor Cyan
Write-Host ""

# Inicia os processos
Write-Host "Iniciando Terminal 0 (Processo 0 - Iniciador de Snapshots)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\bin\dimex_test.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 1 (Processo 1)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\bin\dimex_test.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 2 (Processo 2)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\bin\dimex_test.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Write-Host ""
Write-Host "3 processos iniciados!" -ForegroundColor Green
Write-Host ""

Write-Host "=== INSTRUÇÕES ===" -ForegroundColor Cyan
Write-Host "1. Aguarde alguns segundos para que os snapshots sejam gerados" -ForegroundColor White
Write-Host "2. Pressione qualquer tecla para parar os processos e analisar os snapshots" -ForegroundColor White
Write-Host "3. Os snapshots serão salvos em logs/snapshot_X_process_Y.json" -ForegroundColor White
Write-Host ""

Write-Host "Pressione qualquer tecla para parar e analisar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Para os processos
Write-Host ""
Write-Host "Parando processos..." -ForegroundColor Yellow
Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep 3

# Analisa os snapshots
Write-Host ""
Write-Host "=== ANÁLISE DE SNAPSHOTS ===" -ForegroundColor Green
Write-Host ""

# Verifica se há snapshots
$snapshotFiles = Get-ChildItem "logs" -Filter "snapshot_*.json" -ErrorAction SilentlyContinue
if ($snapshotFiles.Count -eq 0) {
    Write-Host "Nenhum snapshot encontrado!" -ForegroundColor Red
    Write-Host "Verifique se os processos estiveram rodando por tempo suficiente." -ForegroundColor Yellow
} else {
    Write-Host "Encontrados $($snapshotFiles.Count) arquivos de snapshot" -ForegroundColor Green
    Write-Host ""
    
    # Executa o analisador
    Write-Host "Executando análise de invariantes..." -ForegroundColor Cyan
    .\bin\snapshot_analyzer.exe
    
    Write-Host ""
    Write-Host "=== ARQUIVOS GERADOS ===" -ForegroundColor Cyan
    Get-ChildItem "logs" | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "=== SCRIPT CONCLUÍDO ===" -ForegroundColor Green

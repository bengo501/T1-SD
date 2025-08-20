# Script para testar Falha 1: Violação de Exclusão Mútua
Write-Host "=== TESTE FALHA 1: VIOLAÇÃO DE EXCLUSÃO MÚTUA ===" -ForegroundColor Red
Write-Host ""

# Limpa logs anteriores
Write-Host "Limpando logs anteriores..." -ForegroundColor Yellow
if (Test-Path "logs") {
    Remove-Item "logs\*" -Force
}

# Compila o projeto com a falha 1
Write-Host "Compilando o projeto com Falha 1..." -ForegroundColor Yellow
Copy-Item "falhas/DIMEX-Template-Falha1.go" "DIMEX/DIMEX-Template.go" -Force
go build -o dimex_falha1.exe useDIMEX-f.go
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
Write-Host "Iniciando DIMEX com Falha 1 (violação de exclusão mútua)..." -ForegroundColor Cyan
Write-Host "O processo 0 irá iniciar snapshots a cada 2 segundos" -ForegroundColor Cyan
Write-Host "ESPERADO: Múltiplos processos na seção crítica simultaneamente" -ForegroundColor Red
Write-Host ""

# Inicia os processos
Write-Host "Iniciando Terminal 0 (Processo 0 - Iniciador de Snapshots)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_falha1.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 1 (Processo 1)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_falha1.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 2 (Processo 2)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_falha1.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Write-Host ""
Write-Host "3 processos iniciados com Falha 1!" -ForegroundColor Green
Write-Host ""

Write-Host "=== INSTRUÇÕES ===" -ForegroundColor Cyan
Write-Host "1. Aguarde alguns segundos para que os snapshots sejam gerados" -ForegroundColor White
Write-Host "2. Pressione qualquer tecla para parar os processos e analisar os snapshots" -ForegroundColor White
Write-Host "3. A ferramenta deve detectar violação do Inv1 (múltiplos processos na SC)" -ForegroundColor Red
Write-Host ""

Write-Host "Pressione qualquer tecla para parar e analisar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Para os processos
Write-Host ""
Write-Host "Parando processos..." -ForegroundColor Yellow
Get-Process -Name "dimex_falha1" -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep 3

# Analisa os snapshots
Write-Host ""
Write-Host "=== ANÁLISE DE SNAPSHOTS - FALHA 1 ===" -ForegroundColor Green
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
    .\snapshot_analyzer.exe
    
    Write-Host ""
    Write-Host "=== RESULTADO ESPERADO ===" -ForegroundColor Cyan
    Write-Host "A ferramenta deve detectar violações do Inv1:" -ForegroundColor White
    Write-Host "- Múltiplos processos na seção crítica simultaneamente" -ForegroundColor Red
    Write-Host "- Isso confirma que a falha está funcionando corretamente" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== TESTE FALHA 1 CONCLUÍDO ===" -ForegroundColor Green

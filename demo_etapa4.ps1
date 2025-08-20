# Demonstração da Etapa 4: Inserir Falhas no DIMEX
Write-Host "=== DEMONSTRAÇÃO ETAPA 4: INSERIR FALHAS NO DIMEX ===" -ForegroundColor Green
Write-Host ""

Write-Host "Esta demonstração mostra como inserir falhas no DIMEX e detectá-las com snapshots." -ForegroundColor Cyan
Write-Host ""

# Limpa logs anteriores
Write-Host "Limpando logs anteriores..." -ForegroundColor Yellow
if (Test-Path "logs") {
    Remove-Item "logs\*" -Force
}

# Cria pasta logs se não existir
if (!(Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

Write-Host ""
Write-Host "=== FALHA 1: VIOLAÇÃO DE EXCLUSÃO MÚTUA ===" -ForegroundColor Red
Write-Host "Descrição: Permitir que múltiplos processos entrem na seção crítica simultaneamente" -ForegroundColor White
Write-Host "Localização: handleUponDeliverRespOk() - condição alterada de 'N-1' para '>=1'" -ForegroundColor White
Write-Host ""

# Compila com falha 1
Write-Host "Compilando com Falha 1..." -ForegroundColor Yellow
Copy-Item "falhas/DIMEX-Template-Falha1.go" "DIMEX/DIMEX-Template.go" -Force
go build -o dimex_falha1.exe useDIMEX-f.go
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro na compilação!" -ForegroundColor Red
    exit 1
}

Write-Host "Executando sistema com Falha 1 por 15 segundos..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_falha1.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Minimized
Start-Sleep 2
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_falha1.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Minimized
Start-Sleep 2
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_falha1.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Minimized

Start-Sleep 15

# Para processos
Get-Process -Name "dimex_falha1" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 3

# Analisa snapshots da falha 1
Write-Host ""
Write-Host "Analisando snapshots da Falha 1..." -ForegroundColor Cyan
$snapshotFiles1 = Get-ChildItem "logs" -Filter "snapshot_*.json" -ErrorAction SilentlyContinue
if ($snapshotFiles1.Count -gt 0) {
    Write-Host "Encontrados $($snapshotFiles1.Count) snapshots da Falha 1" -ForegroundColor Green
    .\snapshot_analyzer.exe
} else {
    Write-Host "Nenhum snapshot encontrado para Falha 1" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== FALHA 2: DEADLOCK ===" -ForegroundColor Red
Write-Host "Descrição: Nunca responder às requisições de outros processos" -ForegroundColor White
Write-Host "Localização: handleUponDeliverReqEntry() - condição alterada para 'false'" -ForegroundColor White
Write-Host ""

# Limpa logs para falha 2
Remove-Item "logs\*" -Force

# Compila com falha 2
Write-Host "Compilando com Falha 2..." -ForegroundColor Yellow
Copy-Item "falhas/DIMEX-Template-Falha2.go" "DIMEX/DIMEX-Template.go" -Force
go build -o dimex_falha2.exe useDIMEX-f.go
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro na compilação!" -ForegroundColor Red
    exit 1
}

Write-Host "Executando sistema com Falha 2 por 15 segundos..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_falha2.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Minimized
Start-Sleep 2
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_falha2.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Minimized
Start-Sleep 2
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_falha2.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Minimized

Start-Sleep 15

# Para processos
Get-Process -Name "dimex_falha2" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 3

# Analisa snapshots da falha 2
Write-Host ""
Write-Host "Analisando snapshots da Falha 2..." -ForegroundColor Cyan
$snapshotFiles2 = Get-ChildItem "logs" -Filter "snapshot_*.json" -ErrorAction SilentlyContinue
if ($snapshotFiles2.Count -gt 0) {
    Write-Host "Encontrados $($snapshotFiles2.Count) snapshots da Falha 2" -ForegroundColor Green
    .\snapshot_analyzer.exe
} else {
    Write-Host "Nenhum snapshot encontrado para Falha 2" -ForegroundColor Yellow
}

# Restaura DIMEX original
Write-Host ""
Write-Host "Restaurando DIMEX original..." -ForegroundColor Yellow
Copy-Item "falhas/DIMEX-Template-Original.go" "DIMEX/DIMEX-Template.go" -Force

Write-Host ""
Write-Host "=== RESUMO DA ETAPA 4 ===" -ForegroundColor Green
Write-Host "✅ Falha 1 implementada: Violação de exclusão mútua" -ForegroundColor Green
Write-Host "✅ Falha 2 implementada: Deadlock" -ForegroundColor Green
Write-Host "✅ Ferramenta de análise criada para detectar violações" -ForegroundColor Green
Write-Host "✅ Scripts de teste criados para validar falhas" -ForegroundColor Green
Write-Host ""
Write-Host "As falhas foram inseridas no DIMEX e podem ser detectadas através da análise de snapshots!" -ForegroundColor Cyan

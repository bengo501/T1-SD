# Script Simples para Executar DIMEX com 3 Terminais

Write-Host "Iniciando DIMEX com 3 processos..." -ForegroundColor Green

# Remove arquivos anteriores
if (Test-Path "logs/mxOUT.txt") { Remove-Item "logs/mxOUT.txt" -Force }
if (Test-Path "logs/terminal_0.log") { Remove-Item "logs/terminal_0.log" -Force }
if (Test-Path "logs/terminal_1.log") { Remove-Item "logs/terminal_1.log" -Force }
if (Test-Path "logs/terminal_2.log") { Remove-Item "logs/terminal_2.log" -Force }

Write-Host "Arquivos anteriores removidos" -ForegroundColor Cyan

# Define o diretório do projeto
$projectDir = Get-Location

# Comandos para cada terminal com títulos, formatação e logs
$terminal0Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 0 (Processo 0)'; Write-Host '==========================================' -ForegroundColor Green; Write-Host '           DIMEX - TERMINAL 0 (Processo 0)           ' -ForegroundColor Green; Write-Host '==========================================' -ForegroundColor Green; Write-Host ''; go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'logs/terminal_0.log'; Write-Host ''; Write-Host '==========================================' -ForegroundColor Green; Write-Host '           FIM - TERMINAL 0 (Processo 0)           ' -ForegroundColor Green; Write-Host '==========================================' -ForegroundColor Green"

$terminal1Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 1 (Processo 1)'; Write-Host '==========================================' -ForegroundColor Blue; Write-Host '           DIMEX - TERMINAL 1 (Processo 1)           ' -ForegroundColor Blue; Write-Host '==========================================' -ForegroundColor Blue; Write-Host ''; go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'logs/terminal_1.log'; Write-Host ''; Write-Host '==========================================' -ForegroundColor Blue; Write-Host '           FIM - TERMINAL 1 (Processo 1)           ' -ForegroundColor Blue; Write-Host '==========================================' -ForegroundColor Blue"

$terminal2Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 2 (Processo 2)'; Write-Host '==========================================' -ForegroundColor Magenta; Write-Host '           DIMEX - TERMINAL 2 (Processo 2)           ' -ForegroundColor Magenta; Write-Host '==========================================' -ForegroundColor Magenta; Write-Host ''; go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'logs/terminal_2.log'; Write-Host ''; Write-Host '==========================================' -ForegroundColor Magenta; Write-Host '           FIM - TERMINAL 2 (Processo 2)           ' -ForegroundColor Magenta; Write-Host '==========================================' -ForegroundColor Magenta"

# Abre os 3 terminais
Write-Host "Iniciando Terminal 0 (Processo 0)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-Command", $terminal0Cmd -WindowStyle Normal

Write-Host "Iniciando Terminal 1 (Processo 1)..." -ForegroundColor Blue
Start-Process powershell -ArgumentList "-Command", $terminal1Cmd -WindowStyle Normal

Write-Host "Iniciando Terminal 2 (Processo 2)..." -ForegroundColor Magenta
Start-Process powershell -ArgumentList "-Command", $terminal2Cmd -WindowStyle Normal

Write-Host "3 terminais iniciados!" -ForegroundColor Green
Write-Host "Logs sendo salvos em:" -ForegroundColor Yellow
Write-Host "  - logs/terminal_0.log (Processo 0)" -ForegroundColor Gray
Write-Host "  - logs/terminal_1.log (Processo 1)" -ForegroundColor Gray
Write-Host "  - logs/terminal_2.log (Processo 2)" -ForegroundColor Gray
Write-Host "  - logs/mxOUT.txt (Resultado do algoritmo)" -ForegroundColor Gray
Write-Host "Para monitorar mxOUT.txt em tempo real:" -ForegroundColor Cyan
Write-Host "Get-Content logs/mxOUT.txt -Wait -Tail 10" -ForegroundColor Gray
Write-Host "Para parar os processos:" -ForegroundColor White
Write-Host "Pressione Ctrl+C em cada terminal ou feche as janelas" -ForegroundColor Gray

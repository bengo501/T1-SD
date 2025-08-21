# Script para executar DIMEX com 3 terminais (sem monitor)
Write-Host "=== DIMEX - EXECUÇÃO SIMPLES (3 TERMINAIS) ===" -ForegroundColor Green
Write-Host ""

# Obtém o diretório do projeto (um nível acima)
$projectDir = Split-Path -Parent $PSScriptRoot

# Limpa logs anteriores
Write-Host "Limpando logs anteriores..." -ForegroundColor Yellow
if (Test-Path "$projectDir\logs") {
    Remove-Item "$projectDir\logs\*" -Force
}

# Compila o projeto primeiro
Write-Host "Compilando o projeto..." -ForegroundColor Yellow
Set-Location $projectDir
go build -o bin/dimex_test.exe src/useDIMEX-f.go
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro na compilação!" -ForegroundColor Red
    exit 1
}
Write-Host "Compilação concluída!" -ForegroundColor Green

# Cria pasta logs se não existir
if (!(Test-Path "$projectDir\logs")) {
    New-Item -ItemType Directory -Path "$projectDir\logs" | Out-Null
}

Write-Host ""
Write-Host "Iniciando DIMEX com 3 terminais..." -ForegroundColor Cyan
Write-Host ""

# Comandos para cada terminal
$terminal0Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 0 (Processo 0)'; Write-Host '==========================================' -ForegroundColor Green; Write-Host '           DIMEX - TERMINAL 0 (Processo 0)           ' -ForegroundColor Green; Write-Host '==========================================' -ForegroundColor Green; Write-Host ''; .\bin\dimex_test.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'logs/terminal_0.log'; Write-Host ''; Write-Host '==========================================' -ForegroundColor Green; Write-Host '           FIM - TERMINAL 0 (Processo 0)           ' -ForegroundColor Green; Write-Host '==========================================' -ForegroundColor Green"

$terminal1Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 1 (Processo 1)'; Write-Host '==========================================' -ForegroundColor Blue; Write-Host '           DIMEX - TERMINAL 1 (Processo 1)           ' -ForegroundColor Blue; Write-Host '==========================================' -ForegroundColor Blue; Write-Host ''; .\bin\dimex_test.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'logs/terminal_1.log'; Write-Host ''; Write-Host '==========================================' -ForegroundColor Blue; Write-Host '           FIM - TERMINAL 1 (Processo 1)           ' -ForegroundColor Blue; Write-Host '==========================================' -ForegroundColor Blue"

$terminal2Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 2 (Processo 2)'; Write-Host '==========================================' -ForegroundColor Magenta; Write-Host '           DIMEX - TERMINAL 2 (Processo 2)           ' -ForegroundColor Magenta; Write-Host '==========================================' -ForegroundColor Magenta; Write-Host ''; .\bin\dimex_test.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'logs/terminal_2.log'; Write-Host ''; Write-Host '==========================================' -ForegroundColor Magenta; Write-Host '           FIM - TERMINAL 2 (Processo 2)           ' -ForegroundColor Magenta; Write-Host '==========================================' -ForegroundColor Magenta"

# Inicia os terminais
Write-Host "Iniciando Terminal 0 (Processo 0)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", $terminal0Cmd -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 1 (Processo 1)..." -ForegroundColor White  
Start-Process powershell -ArgumentList "-Command", $terminal1Cmd -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 2 (Processo 2)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", $terminal2Cmd -WindowStyle Normal

Write-Host ""
Write-Host "Todos os 3 terminais foram iniciados!" -ForegroundColor Green
Write-Host ""

Write-Host "Logs sendo salvos em:" -ForegroundColor Cyan
Write-Host "  - logs/terminal_0.log (Processo 0)" -ForegroundColor White
Write-Host "  - logs/terminal_1.log (Processo 1)" -ForegroundColor White
Write-Host "  - logs/terminal_2.log (Processo 2)" -ForegroundColor White
Write-Host "  - logs/mxOUT.txt (Resultado do algoritmo)" -ForegroundColor White

Write-Host ""
Write-Host "Para parar os processos:" -ForegroundColor Yellow
Write-Host "  Pressione Ctrl+C em cada terminal ou feche as janelas" -ForegroundColor White

Write-Host ""
Write-Host "=== Script Concluído ===" -ForegroundColor Green

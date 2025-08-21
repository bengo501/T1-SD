# Script para executar DIMEX com 4 terminais (3 processos + monitor)
Write-Host "=== DIMEX - EXECUÇÃO COM MONITOR (4 TERMINAIS) ===" -ForegroundColor Green
Write-Host ""

# Obtém o diretório do projeto (um nível acima)
$projectDir = Split-Path -Parent $PSScriptRoot

Write-Host "Iniciando DIMEX com 3 processos + monitoramento..." -ForegroundColor Cyan

# Limpa logs anteriores
Write-Host "Limpando logs anteriores..." -ForegroundColor Yellow
if (Test-Path "$projectDir\logs") {
    Remove-Item "$projectDir\logs\*" -Force
}
Write-Host "Arquivos anteriores removidos" -ForegroundColor Cyan

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

# Comandos para cada terminal com títulos, formatação e logs
$terminal0Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 0 (Processo 0)'; Write-Host '==========================================' -ForegroundColor Green; Write-Host '           DIMEX - TERMINAL 0 (Processo 0)           ' -ForegroundColor Green; Write-Host '==========================================' -ForegroundColor Green; Write-Host ''; .\bin\dimex_test.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'logs/terminal_0.log'"

$terminal1Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 1 (Processo 1)'; Write-Host '==========================================' -ForegroundColor Blue; Write-Host '           DIMEX - TERMINAL 1 (Processo 1)           ' -ForegroundColor Blue; Write-Host '==========================================' -ForegroundColor Blue; Write-Host ''; .\bin\dimex_test.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'logs/terminal_1.log'"

$terminal2Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 2 (Processo 2)'; Write-Host '==========================================' -ForegroundColor Magenta; Write-Host '           DIMEX - TERMINAL 2 (Processo 2)           ' -ForegroundColor Magenta; Write-Host '==========================================' -ForegroundColor Magenta; Write-Host ''; .\bin\dimex_test.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'logs/terminal_2.log'"

$monitorCmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - MONITOR'; Write-Host '==========================================' -ForegroundColor Yellow; Write-Host '              DIMEX - MONITOR              ' -ForegroundColor Yellow; Write-Host '==========================================' -ForegroundColor Yellow; Write-Host ''; Write-Host 'Aguardando arquivo mxOUT.txt...' -ForegroundColor Cyan; while (!(Test-Path 'logs/mxOUT.txt')) { Start-Sleep 1 }; Write-Host 'Arquivo encontrado! Iniciando monitoramento...' -ForegroundColor Green; Write-Host ''; `$lastSize = 0; while (`$true) { if (Test-Path 'logs/mxOUT.txt') { `$content = Get-Content 'logs/mxOUT.txt' -Raw -ErrorAction SilentlyContinue; if (`$content) { `$currentSize = `$content.Length; if (`$currentSize -ne `$lastSize) { Clear-Host; Write-Host '==========================================' -ForegroundColor Yellow; Write-Host '              DIMEX - MONITOR              ' -ForegroundColor Yellow; Write-Host '==========================================' -ForegroundColor Yellow; Write-Host ''; Write-Host 'Conteúdo atual de mxOUT.txt:' -ForegroundColor Cyan; Write-Host `$content -ForegroundColor White; Write-Host ''; Write-Host 'Estatísticas:' -ForegroundColor Green; Write-Host ('  - Tamanho: ' + `$currentSize + ' caracteres') -ForegroundColor White; `$entradas = (`$content.ToCharArray() | Where-Object {`$_ -eq '|'}).Count; `$saidas = (`$content.ToCharArray() | Where-Object {`$_ -eq '.'}).Count; Write-Host ('  - Entradas: ' + `$entradas) -ForegroundColor White; Write-Host ('  - Saídas: ' + `$saidas) -ForegroundColor White; if (`$content.Contains('||')) { Write-Host '  - VIOLAÇÃO: || detectado!' -ForegroundColor Red } else { Write-Host '  - Sem violações ||' -ForegroundColor Green }; if (`$content.Contains('..')) { Write-Host '  - VIOLAÇÃO: .. detectado!' -ForegroundColor Red } else { Write-Host '  - Sem violações ..' -ForegroundColor Green }; Write-Host ''; Write-Host 'Pressione Ctrl+C para parar' -ForegroundColor Yellow; `$lastSize = `$currentSize } } }; Start-Sleep 1 }"

# Abre os 4 terminais
Write-Host "Iniciando Terminal 0 (Processo 0)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", $terminal0Cmd -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 1 (Processo 1)..." -ForegroundColor White  
Start-Process powershell -ArgumentList "-Command", $terminal1Cmd -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 2 (Processo 2)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", $terminal2Cmd -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal de Monitoramento..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", $monitorCmd -WindowStyle Normal

Write-Host ""
Write-Host "Todos os 4 terminais foram iniciados!" -ForegroundColor Green
Write-Host ""

Write-Host "Logs sendo salvos em:" -ForegroundColor Cyan
Write-Host "  - logs/terminal_0.log (Processo 0)" -ForegroundColor White
Write-Host "  - logs/terminal_1.log (Processo 1)" -ForegroundColor White
Write-Host "  - logs/terminal_2.log (Processo 2)" -ForegroundColor White
Write-Host "  - logs/mxOUT.txt (Resultado do algoritmo)" -ForegroundColor White

Write-Host ""
Write-Host "Terminal de Monitoramento:" -ForegroundColor Cyan
Write-Host "  - Mostra mxOUT.txt em tempo real" -ForegroundColor White
Write-Host "  - Valida o padrão automaticamente" -ForegroundColor White
Write-Host "  - Exibe estatísticas do arquivo" -ForegroundColor White

Write-Host ""
Write-Host "Para parar os processos:" -ForegroundColor Yellow
Write-Host "  Pressione Ctrl+C em cada terminal ou feche as janelas" -ForegroundColor White

Write-Host ""
Write-Host "=== Script Concluído ===" -ForegroundColor Green

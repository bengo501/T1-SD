# Script Completo para DIMEX com 3 Terminais + Monitoramento
# Todos os terminais têm logs em tempo real

Write-Host "Iniciando DIMEX Completo com 3 processos + monitoramento..." -ForegroundColor Green

# Remove arquivos anteriores
if (Test-Path "logs/mxOUT.txt") { Remove-Item "logs/mxOUT.txt" -Force -ErrorAction SilentlyContinue }
if (Test-Path "logs/terminal_0.log") { Remove-Item "logs/terminal_0.log" -Force -ErrorAction SilentlyContinue }
if (Test-Path "logs/terminal_1.log") { Remove-Item "logs/terminal_1.log" -Force -ErrorAction SilentlyContinue }
if (Test-Path "logs/terminal_2.log") { Remove-Item "logs/terminal_2.log" -Force -ErrorAction SilentlyContinue }

Write-Host "Arquivos anteriores removidos" -ForegroundColor Cyan

# Define o diretório do projeto
$projectDir = Get-Location

# Comandos para cada terminal com logs em tempo real
$terminal0Cmd = @"
cd '$projectDir'
`$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 0 (Processo 0)'
Write-Host '==========================================' -ForegroundColor Green
Write-Host '           DIMEX - TERMINAL 0 (Processo 0)           ' -ForegroundColor Green
Write-Host '==========================================' -ForegroundColor Green
Write-Host ''
Write-Host 'Iniciando processo 0...' -ForegroundColor Green
Write-Host 'Logs sendo salvos em tempo real em logs/terminal_0.log' -ForegroundColor Cyan
Write-Host ''

# Executa o processo e salva logs em tempo real
go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 2>&1 | Tee-Object -FilePath 'logs/terminal_0.log'
"@

$terminal1Cmd = @"
cd '$projectDir'
`$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 1 (Processo 1)'
Write-Host '==========================================' -ForegroundColor Blue
Write-Host '           DIMEX - TERMINAL 1 (Processo 1)           ' -ForegroundColor Blue
Write-Host '==========================================' -ForegroundColor Blue
Write-Host ''
Write-Host 'Iniciando processo 1...' -ForegroundColor Blue
Write-Host 'Logs sendo salvos em tempo real em logs/terminal_1.log' -ForegroundColor Cyan
Write-Host ''

# Executa o processo e salva logs em tempo real
go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 2>&1 | Tee-Object -FilePath 'logs/terminal_1.log'
"@

$terminal2Cmd = @"
cd '$projectDir'
`$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 2 (Processo 2)'
Write-Host '==========================================' -ForegroundColor Magenta
Write-Host '           DIMEX - TERMINAL 2 (Processo 2)           ' -ForegroundColor Magenta
Write-Host '==========================================' -ForegroundColor Magenta
Write-Host ''
Write-Host 'Iniciando processo 2...' -ForegroundColor Magenta
Write-Host 'Logs sendo salvos em tempo real em logs/terminal_2.log' -ForegroundColor Cyan
Write-Host ''

# Executa o processo e salva logs em tempo real
go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 2>&1 | Tee-Object -FilePath 'logs/terminal_2.log'
"@

$monitorCmd = @"
cd '$projectDir'
`$Host.UI.RawUI.WindowTitle = 'DIMEX - MONITOR (mxOUT.txt)'
Write-Host '==========================================' -ForegroundColor Yellow
Write-Host '           DIMEX - MONITOR (mxOUT.txt)           ' -ForegroundColor Yellow
Write-Host '==========================================' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Monitorando mxOUT.txt em tempo real...' -ForegroundColor Cyan
Write-Host 'Validando padrao automaticamente...' -ForegroundColor Cyan
Write-Host 'Exibindo estatisticas...' -ForegroundColor Cyan
Write-Host 'Pressione Ctrl+C para parar o monitoramento' -ForegroundColor Gray
Write-Host ''

while (`$true) {
    if (Test-Path 'logs/mxOUT.txt') {
        `$content = Get-Content 'logs/mxOUT.txt' -Raw
        if (`$content) {
            Clear-Host
            Write-Host '==========================================' -ForegroundColor Yellow
            Write-Host '           DIMEX - MONITOR (mxOUT.txt)           ' -ForegroundColor Yellow
            Write-Host '==========================================' -ForegroundColor Yellow
            Write-Host ''
            Write-Host 'Conteudo atual do mxOUT.txt:' -ForegroundColor Cyan
            Write-Host '-' * 60 -ForegroundColor Gray
            Write-Host `$content -ForegroundColor White
            Write-Host '-' * 60 -ForegroundColor Gray
            
            `$length = `$content.Length
            Write-Host "Tamanho: `$length caracteres" -ForegroundColor Green
            
            `$pattern = `$content -replace '[\r\n]', ''
            if (`$pattern -match '^(\|\.)+$') {
                Write-Host 'Padrao CORRETO detectado!' -ForegroundColor Green
            } else {
                Write-Host 'Padrao pode estar incorreto!' -ForegroundColor Yellow
            }
            
            Write-Host ''
            Write-Host 'Ultima atualizacao:' (Get-Date -Format 'HH:mm:ss') -ForegroundColor Gray
        } else {
            Write-Host 'Aguardando conteudo...' -ForegroundColor Gray
        }
    } else {
        Write-Host 'Aguardando criacao do arquivo...' -ForegroundColor Gray
    }
    Start-Sleep 1
}
"@

# Abre os 4 terminais
Write-Host "Iniciando Terminal 0 (Processo 0)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-Command", $terminal0Cmd -WindowStyle Normal

Write-Host "Iniciando Terminal 1 (Processo 1)..." -ForegroundColor Blue
Start-Process powershell -ArgumentList "-Command", $terminal1Cmd -WindowStyle Normal

Write-Host "Iniciando Terminal 2 (Processo 2)..." -ForegroundColor Magenta
Start-Process powershell -ArgumentList "-Command", $terminal2Cmd -WindowStyle Normal

Write-Host "Iniciando Terminal de Monitoramento..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-Command", $monitorCmd -WindowStyle Normal

Write-Host "Todos os 4 terminais foram iniciados!" -ForegroundColor Green
Write-Host "Logs sendo salvos em tempo real:" -ForegroundColor Yellow
Write-Host "  - logs/terminal_0.log (Processo 0)" -ForegroundColor Gray
Write-Host "  - logs/terminal_1.log (Processo 1)" -ForegroundColor Gray
Write-Host "  - logs/terminal_2.log (Processo 2)" -ForegroundColor Gray
Write-Host "  - logs/mxOUT.txt (Resultado do algoritmo)" -ForegroundColor Gray

Write-Host "Terminal de Monitoramento:" -ForegroundColor Cyan
Write-Host "  - Mostra mxOUT.txt em tempo real" -ForegroundColor Gray
Write-Host "  - Valida o padrao automaticamente" -ForegroundColor Gray
Write-Host "  - Exibe estatisticas do arquivo" -ForegroundColor Gray
Write-Host "  - Atualizacao a cada segundo" -ForegroundColor Gray

Write-Host "Para parar os processos:" -ForegroundColor White
Write-Host "  Pressione Ctrl+C em cada terminal ou feche as janelas" -ForegroundColor Gray

Write-Host "=== Sistema DIMEX Completo Iniciado ===" -ForegroundColor Green

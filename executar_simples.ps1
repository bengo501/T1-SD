# Script Simples para Executar DIMEX com 3 Terminais
# Salva o log de cada terminal em arquivos separados
# Melhor formatação e títulos nos terminais

Write-Host "🚀 Iniciando DIMEX com 3 processos..." -ForegroundColor Green

# Remove arquivos anteriores
if (Test-Path "mxOUT.txt") { Remove-Item "mxOUT.txt" -Force }
if (Test-Path "terminal_0.log") { Remove-Item "terminal_0.log" -Force }
if (Test-Path "terminal_1.log") { Remove-Item "terminal_1.log" -Force }
if (Test-Path "terminal_2.log") { Remove-Item "terminal_2.log" -Force }

Write-Host "📁 Arquivos anteriores removidos" -ForegroundColor Cyan

# Define o diretório do projeto
$projectDir = "C:\Users\joxto\Downloads\T1-SD"

# Comandos para cada terminal com formatação melhorada
$terminal0Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 0 (Processo 0)'; Write-Host '╔══════════════════════════════════════════════════════════════╗' -ForegroundColor Green; Write-Host '║                    DIMEX - TERMINAL 0 (Processo 0)                    ║' -ForegroundColor Green; Write-Host '╚══════════════════════════════════════════════════════════════╝' -ForegroundColor Green; Write-Host ''; go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'terminal_0.log'"

$terminal1Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 1 (Processo 1)'; Write-Host '╔══════════════════════════════════════════════════════════════╗' -ForegroundColor Blue; Write-Host '║                    DIMEX - TERMINAL 1 (Processo 1)                    ║' -ForegroundColor Blue; Write-Host '╚══════════════════════════════════════════════════════════════╝' -ForegroundColor Blue; Write-Host ''; go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'terminal_1.log'"

$terminal2Cmd = "cd '$projectDir'; `$Host.UI.RawUI.WindowTitle = 'DIMEX - TERMINAL 2 (Processo 2)'; Write-Host '╔══════════════════════════════════════════════════════════════╗' -ForegroundColor Magenta; Write-Host '║                    DIMEX - TERMINAL 2 (Processo 2)                    ║' -ForegroundColor Magenta; Write-Host '╚══════════════════════════════════════════════════════════════╝' -ForegroundColor Magenta; Write-Host ''; go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 *>&1 | Tee-Object -FilePath 'terminal_2.log'"

# Abre os 3 terminais com logs e formatação melhorada
Write-Host "🔄 Iniciando Terminal 0 (Processo 0)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-Command", $terminal0Cmd -WindowStyle Normal

Write-Host "🔄 Iniciando Terminal 1 (Processo 1)..." -ForegroundColor Blue
Start-Process powershell -ArgumentList "-Command", $terminal1Cmd -WindowStyle Normal

Write-Host "🔄 Iniciando Terminal 2 (Processo 2)..." -ForegroundColor Magenta
Start-Process powershell -ArgumentList "-Command", $terminal2Cmd -WindowStyle Normal

Write-Host "`n✅ 3 terminais iniciados!" -ForegroundColor Green
Write-Host "📁 Logs sendo salvos em:" -ForegroundColor Yellow
Write-Host "  - terminal_0.log (Processo 0)" -ForegroundColor Gray
Write-Host "  - terminal_1.log (Processo 1)" -ForegroundColor Gray
Write-Host "  - terminal_2.log (Processo 2)" -ForegroundColor Gray
Write-Host "  - mxOUT.txt (Resultado do algoritmo)" -ForegroundColor Gray

Write-Host "`n📊 Para monitorar mxOUT.txt em tempo real:" -ForegroundColor Cyan
Write-Host "  Get-Content mxOUT.txt -Wait -Tail 10" -ForegroundColor Gray

Write-Host "`n🎯 Para parar os processos:" -ForegroundColor White
Write-Host "  Pressione Ctrl+C em cada terminal ou feche as janelas" -ForegroundColor Gray

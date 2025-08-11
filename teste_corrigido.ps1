# Script para testar a versão corrigida do DIMEX
Write-Host "🧪 Testando versão corrigida do DIMEX..." -ForegroundColor Green

# Remove arquivos anteriores
if (Test-Path "logs/mxOUT.txt") { Remove-Item "logs/mxOUT.txt" -Force -ErrorAction SilentlyContinue }
if (Test-Path "logs/terminal_0.log") { Remove-Item "logs/terminal_0.log" -Force -ErrorAction SilentlyContinue }
if (Test-Path "logs/terminal_1.log") { Remove-Item "logs/terminal_1.log" -Force -ErrorAction SilentlyContinue }
if (Test-Path "logs/terminal_2.log") { Remove-Item "logs/terminal_2.log" -Force -ErrorAction SilentlyContinue }

Write-Host "📁 Arquivos anteriores removidos" -ForegroundColor Cyan

# Compila o projeto
Write-Host "🔨 Compilando projeto..." -ForegroundColor Yellow
go build -o dimex_test.exe useDIMEX-f.go

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro na compilação!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Compilação bem-sucedida!" -ForegroundColor Green

# Inicia os 3 processos
Write-Host "🚀 Iniciando 3 processos DIMEX..." -ForegroundColor Green

$process0 = Start-Process -FilePath ".\dimex_test.exe" -ArgumentList "0", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal -PassThru
$process1 = Start-Process -FilePath ".\dimex_test.exe" -ArgumentList "1", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal -PassThru
$process2 = Start-Process -FilePath ".\dimex_test.exe" -ArgumentList "2", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal -PassThru

Write-Host "⏳ Aguardando 10 segundos para execução..." -ForegroundColor Yellow
Start-Sleep 10

# Verifica se os processos ainda estão rodando
$p0Running = Get-Process -Id $process0.Id -ErrorAction SilentlyContinue
$p1Running = Get-Process -Id $process1.Id -ErrorAction SilentlyContinue
$p2Running = Get-Process -Id $process2.Id -ErrorAction SilentlyContinue

Write-Host "📊 Status dos processos:" -ForegroundColor Cyan
Write-Host "  Processo 0: $($p0Running ? 'Rodando' : 'Parado')" -ForegroundColor $(if($p0Running) { 'Green' } else { 'Red' })
Write-Host "  Processo 1: $($p1Running ? 'Rodando' : 'Parado')" -ForegroundColor $(if($p1Running) { 'Green' } else { 'Red' })
Write-Host "  Processo 2: $($p2Running ? 'Rodando' : 'Parado')" -ForegroundColor $(if($p2Running) { 'Green' } else { 'Red' })

# Verifica o conteúdo do mxOUT.txt
if (Test-Path "logs/mxOUT.txt") {
    $content = Get-Content "logs/mxOUT.txt" -Raw
    $length = if ($content) { $content.Length } else { 0 }
    
    Write-Host "`n📄 Conteúdo do mxOUT.txt:" -ForegroundColor Cyan
    Write-Host "  Tamanho: $length caracteres" -ForegroundColor Gray
    
    if ($content) {
        Write-Host "  Conteúdo: $content" -ForegroundColor White
        Write-Host "  Padrão correto: $(if($content -match '^(\|\.)+$') { '✅ SIM' } else { '❌ NÃO' })" -ForegroundColor $(if($content -match '^(\|\.)+$') { 'Green' } else { 'Red' })
    } else {
        Write-Host "  ❌ Arquivo vazio!" -ForegroundColor Red
    }
} else {
    Write-Host "`n❌ Arquivo mxOUT.txt não encontrado!" -ForegroundColor Red
}

# Para os processos
Write-Host "`n🛑 Parando processos..." -ForegroundColor Yellow
if ($p0Running) { Stop-Process -Id $process0.Id -Force -ErrorAction SilentlyContinue }
if ($p1Running) { Stop-Process -Id $process1.Id -Force -ErrorAction SilentlyContinue }
if ($p2Running) { Stop-Process -Id $process2.Id -Force -ErrorAction SilentlyContinue }

Write-Host "✅ Teste concluído!" -ForegroundColor Green

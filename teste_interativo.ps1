# Script para testar a versão corrigida do DIMEX com monitoramento interativo
Write-Host "🧪 Teste Interativo DIMEX - Pressione Ctrl+C para parar" -ForegroundColor Green

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

Write-Host "✅ 3 processos iniciados!" -ForegroundColor Green

# Inicia o terminal de monitoramento
Write-Host "📊 Iniciando terminal de monitoramento..." -ForegroundColor Cyan

$monitorCmd = @"
cd 'C:\Users\joxto\Downloads\T1-SD'
`$Host.UI.RawUI.WindowTitle = 'DIMEX - MONITOR (mxOUT.txt)'
Write-Host '╔══════════════════════════════════════════════════════════════╗' -ForegroundColor Yellow
Write-Host '║                    DIMEX - MONITOR (mxOUT.txt)                    ║' -ForegroundColor Yellow
Write-Host '╚══════════════════════════════════════════════════════════════╝' -ForegroundColor Yellow
Write-Host ''
Write-Host '📊 Monitorando mxOUT.txt em tempo real...' -ForegroundColor Cyan
Write-Host '🔍 Validando padrão automaticamente...' -ForegroundColor Cyan
Write-Host '📈 Exibindo estatísticas...' -ForegroundColor Cyan
Write-Host 'Pressione Ctrl+C para parar o monitoramento' -ForegroundColor Gray
Write-Host ''

while (`$true) {
    if (Test-Path 'logs/mxOUT.txt') {
        `$content = Get-Content 'logs/mxOUT.txt' -Raw
        if (`$content) {
            Clear-Host
            Write-Host '╔══════════════════════════════════════════════════════════════╗' -ForegroundColor Yellow
            Write-Host '║                    DIMEX - MONITOR (mxOUT.txt)                    ║' -ForegroundColor Yellow
            Write-Host '╚══════════════════════════════════════════════════════════════╝' -ForegroundColor Yellow
            Write-Host ''
            Write-Host '📊 Conteúdo atual do mxOUT.txt:' -ForegroundColor Cyan
            Write-Host '─' * 60 -ForegroundColor Gray
            Write-Host `$content -ForegroundColor White
            Write-Host '─' * 60 -ForegroundColor Gray
            
            `$length = `$content.Length
            Write-Host "📈 Tamanho: `$length caracteres" -ForegroundColor Green
            
            `$pattern = `$content -replace '[\r\n]', ''
            if (`$pattern -match '^(\|\.)+$') {
                Write-Host '✅ Padrão CORRETO detectado!' -ForegroundColor Green
            } else {
                Write-Host '⚠️  Padrão pode estar incorreto!' -ForegroundColor Yellow
            }
            
            Write-Host ''
            Write-Host '🕐 Última atualização:' (Get-Date -Format 'HH:mm:ss') -ForegroundColor Gray
        } else {
            Write-Host '⏳ Aguardando conteúdo...' -ForegroundColor Gray
        }
    } else {
        Write-Host '⏳ Aguardando criação do arquivo...' -ForegroundColor Gray
    }
    Start-Sleep 1
}
"@

$monitorProcess = Start-Process powershell -ArgumentList "-Command", $monitorCmd -WindowStyle Normal -PassThru

Write-Host "✅ Terminal de monitoramento iniciado!" -ForegroundColor Green

Write-Host "`n🎯 TESTE INTERATIVO INICIADO!" -ForegroundColor Green
Write-Host "📊 3 processos DIMEX rodando + 1 terminal de monitoramento" -ForegroundColor Cyan
Write-Host "⏹️  Pressione Ctrl+C para parar todos os processos" -ForegroundColor Yellow
Write-Host "📁 Arquivo mxOUT.txt sendo monitorado em tempo real" -ForegroundColor Gray

# Aguarda interrupção do usuário
try {
    while ($true) {
        # Verifica se os processos ainda estão rodando
        $p0Running = Get-Process -Id $process0.Id -ErrorAction SilentlyContinue
        $p1Running = Get-Process -Id $process1.Id -ErrorAction SilentlyContinue
        $p2Running = Get-Process -Id $process2.Id -ErrorAction SilentlyContinue
        
        if (-not $p0Running -or -not $p1Running -or -not $p2Running) {
            Write-Host "`n⚠️  Um ou mais processos pararam inesperadamente!" -ForegroundColor Yellow
            break
        }
        
        Start-Sleep 5
    }
}
catch {
    Write-Host "`n🛑 Interrupção detectada!" -ForegroundColor Yellow
}
finally {
    Write-Host "`n🛑 Parando todos os processos..." -ForegroundColor Yellow
    
    # Para os processos DIMEX
    if ($p0Running) { Stop-Process -Id $process0.Id -Force -ErrorAction SilentlyContinue }
    if ($p1Running) { Stop-Process -Id $process1.Id -Force -ErrorAction SilentlyContinue }
    if ($p2Running) { Stop-Process -Id $process2.Id -Force -ErrorAction SilentlyContinue }
    
    # Para o processo de monitoramento
    $monitorRunning = Get-Process -Id $monitorProcess.Id -ErrorAction SilentlyContinue
    if ($monitorRunning) { Stop-Process -Id $monitorProcess.Id -Force -ErrorAction SilentlyContinue }
    
    Write-Host "✅ Todos os processos parados!" -ForegroundColor Green
    
    # Mostra estatísticas finais
    if (Test-Path "logs/mxOUT.txt") {
        $finalContent = Get-Content "logs/mxOUT.txt" -Raw
        $finalLength = if ($finalContent) { $finalContent.Length } else { 0 }
        
        Write-Host "`n📊 ESTATÍSTICAS FINAIS:" -ForegroundColor Cyan
        Write-Host "  Tamanho final: $finalLength caracteres" -ForegroundColor Gray
        Write-Host "  Padrão correto: $(if($finalContent -and $finalContent -match '^(\|\.)+$') { '✅ SIM' } else { '❌ NÃO' })" -ForegroundColor $(if($finalContent -and $finalContent -match '^(\|\.)+$') { 'Green' } else { 'Red' })
        
        if ($finalContent) {
            Write-Host "  Últimas 50 caracteres: $($finalContent.Substring([Math]::Max(0, $finalContent.Length - 50)))" -ForegroundColor White
        }
    }
    
    Write-Host "`n✅ Teste interativo concluído!" -ForegroundColor Green
}

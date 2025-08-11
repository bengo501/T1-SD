# Script para testar a versão corrigida do DIMEX com monitoramento avançado
Write-Host "🧪 Teste Interativo Avançado DIMEX - Pressione Ctrl+C para parar" -ForegroundColor Green

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

# Inicia o terminal de monitoramento avançado
Write-Host "📊 Iniciando terminal de monitoramento avançado..." -ForegroundColor Cyan

$monitorCmd = @"
cd 'C:\Users\joxto\Downloads\T1-SD'
`$Host.UI.RawUI.WindowTitle = 'DIMEX - MONITOR AVANÇADO (mxOUT.txt)'
Write-Host '╔══════════════════════════════════════════════════════════════╗' -ForegroundColor Yellow
Write-Host '║                DIMEX - MONITOR AVANÇADO (mxOUT.txt)                ║' -ForegroundColor Yellow
Write-Host '╚══════════════════════════════════════════════════════════════╝' -ForegroundColor Yellow
Write-Host ''
Write-Host '📊 Monitorando mxOUT.txt em tempo real...' -ForegroundColor Cyan
Write-Host '🔍 Validando padrão automaticamente...' -ForegroundColor Cyan
Write-Host '📈 Exibindo estatísticas detalhadas...' -ForegroundColor Cyan
Write-Host '⏱️  Calculando taxa de escrita...' -ForegroundColor Cyan
Write-Host 'Pressione Ctrl+C para parar o monitoramento' -ForegroundColor Gray
Write-Host ''

`$lastSize = 0
`$lastTime = Get-Date
`$startTime = Get-Date

while (`$true) {
    if (Test-Path 'logs/mxOUT.txt') {
        `$content = Get-Content 'logs/mxOUT.txt' -Raw
        if (`$content) {
            Clear-Host
            Write-Host '╔══════════════════════════════════════════════════════════════╗' -ForegroundColor Yellow
            Write-Host '║                DIMEX - MONITOR AVANÇADO (mxOUT.txt)                ║' -ForegroundColor Yellow
            Write-Host '╚══════════════════════════════════════════════════════════════╝' -ForegroundColor Yellow
            Write-Host ''
            
            `$currentTime = Get-Date
            `$currentSize = `$content.Length
            `$timeDiff = (`$currentTime - `$lastTime).TotalSeconds
            `$sizeDiff = `$currentSize - `$lastSize
            `$totalTime = (`$currentTime - `$startTime).TotalSeconds
            
            Write-Host '📊 ESTATÍSTICAS EM TEMPO REAL:' -ForegroundColor Cyan
            Write-Host "  Tamanho atual: `$currentSize caracteres" -ForegroundColor Green
            Write-Host "  Tamanho anterior: `$lastSize caracteres" -ForegroundColor Gray
            Write-Host "  Crescimento: +`$sizeDiff caracteres" -ForegroundColor Blue
            
            if (`$timeDiff -gt 0) {
                `$rate = [math]::Round(`$sizeDiff / `$timeDiff, 2)
                Write-Host "  Taxa de escrita: `$rate caracteres/segundo" -ForegroundColor Magenta
            }
            
            Write-Host "  Tempo total: `$([math]::Round(`$totalTime, 1)) segundos" -ForegroundColor Gray
            Write-Host "  Taxa média: `$([math]::Round(`$currentSize / `$totalTime, 2)) caracteres/segundo" -ForegroundColor Cyan
            
            Write-Host ''
            Write-Host '📄 CONTEÚDO ATUAL:' -ForegroundColor Cyan
            Write-Host '─' * 60 -ForegroundColor Gray
            
            # Mostra apenas as últimas 200 caracteres para não sobrecarregar
            if (`$content.Length -gt 200) {
                Write-Host "...`$(`$content.Substring(`$content.Length - 200))" -ForegroundColor White
            } else {
                Write-Host `$content -ForegroundColor White
            }
            
            Write-Host '─' * 60 -ForegroundColor Gray
            
            `$pattern = `$content -replace '[\r\n]', ''
            if (`$pattern -match '^(\|\.)+$') {
                Write-Host '✅ Padrão CORRETO detectado!' -ForegroundColor Green
            } else {
                Write-Host '⚠️  Padrão pode estar incorreto!' -ForegroundColor Yellow
            }
            
            Write-Host ''
            Write-Host '🕐 Última atualização:' (Get-Date -Format 'HH:mm:ss') -ForegroundColor Gray
            
            `$lastSize = `$currentSize
            `$lastTime = `$currentTime
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

Write-Host "✅ Terminal de monitoramento avançado iniciado!" -ForegroundColor Green

Write-Host "`n🎯 TESTE INTERATIVO AVANÇADO INICIADO!" -ForegroundColor Green
Write-Host "📊 3 processos DIMEX rodando + 1 terminal de monitoramento avançado" -ForegroundColor Cyan
Write-Host "⏹️  Pressione Ctrl+C para parar todos os processos" -ForegroundColor Yellow
Write-Host "📁 Arquivo mxOUT.txt sendo monitorado com estatísticas detalhadas" -ForegroundColor Gray
Write-Host "📈 Taxa de escrita sendo calculada em tempo real" -ForegroundColor Gray

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
    
    # Mostra estatísticas finais detalhadas
    if (Test-Path "logs/mxOUT.txt") {
        $finalContent = Get-Content "logs/mxOUT.txt" -Raw
        $finalLength = if ($finalContent) { $finalContent.Length } else { 0 }
        
        Write-Host "`n📊 ESTATÍSTICAS FINAIS DETALHADAS:" -ForegroundColor Cyan
        Write-Host "  Tamanho final: $finalLength caracteres" -ForegroundColor Gray
        Write-Host "  Padrão correto: $(if($finalContent -and $finalContent -match '^(\|\.)+$') { '✅ SIM' } else { '❌ NÃO' })" -ForegroundColor $(if($finalContent -and $finalContent -match '^(\|\.)+$') { 'Green' } else { 'Red' })
        
        if ($finalContent) {
            $patternCount = ([regex]::Matches($finalContent, '\|\.')).Count
            Write-Host "  Acessos à seção crítica: $patternCount" -ForegroundColor Blue
            Write-Host "  Últimas 50 caracteres: $($finalContent.Substring([Math]::Max(0, $finalContent.Length - 50)))" -ForegroundColor White
        }
    }
    
    Write-Host "`n✅ Teste interativo avançado concluído!" -ForegroundColor Green
}

# Script para testar DIMEX puro sem snapshots
Write-Host "🧪 TESTE DIMEX PURO - SEM SNAPSHOTS" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Parar processos existentes
Write-Host "🛑 Parando processos existentes..." -ForegroundColor Yellow
taskkill /F /IM dimex_test.exe 2>$null
Start-Sleep -Seconds 2

# Limpar logs
Write-Host "🧹 Limpando logs anteriores..." -ForegroundColor Yellow
if (Test-Path "logs/mxOUT.txt") { Remove-Item "logs/mxOUT.txt" -Force }
if (Test-Path "logs/terminal_*.log") { Remove-Item "logs/terminal_*.log" -Force }

# Compilar versão simples
Write-Host "🔨 Compilando versão DIMEX pura..." -ForegroundColor Yellow

# Copiar versão debug para teste
Copy-Item "DIMEX/DIMEX-Template-Debug.go" "DIMEX/DIMEX-Template.go" -Force

# Compilar
go build -o dimex_puro.exe useDIMEX-f.go
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro na compilação!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Compilação concluída!" -ForegroundColor Green

# Criar diretório logs se não existir
if (!(Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

# Iniciar processos
Write-Host "🚀 Iniciando 3 processos DIMEX puro..." -ForegroundColor Yellow

# Processo 0
Start-Process -FilePath ".\dimex_puro.exe" -ArgumentList "0", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Minimized -RedirectStandardOutput "logs/terminal_0_puro.log" -RedirectStandardError "logs/terminal_0_puro.log"

# Processo 1
Start-Process -FilePath ".\dimex_puro.exe" -ArgumentList "1", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Minimized -RedirectStandardOutput "logs/terminal_1_puro.log" -RedirectStandardError "logs/terminal_1_puro.log"

# Processo 2
Start-Process -FilePath ".\dimex_puro.exe" -ArgumentList "2", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Minimized -RedirectStandardOutput "logs/terminal_2_puro.log" -RedirectStandardError "logs/terminal_2_puro.log"

Write-Host "✅ 3 processos iniciados!" -ForegroundColor Green
Write-Host "📊 Logs sendo salvos em:" -ForegroundColor Cyan
Write-Host "  - logs/terminal_0_puro.log (Processo 0)" -ForegroundColor White
Write-Host "  - logs/terminal_1_puro.log (Processo 1)" -ForegroundColor White
Write-Host "  - logs/terminal_2_puro.log (Processo 2)" -ForegroundColor White
Write-Host "  - logs/mxOUT.txt (Resultado do algoritmo)" -ForegroundColor White

Write-Host "`n⏱️  Aguardando 10 segundos para execução..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verificar resultado
Write-Host "`n📋 VERIFICANDO RESULTADO:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

if (Test-Path "logs/mxOUT.txt") {
    $content = Get-Content "logs/mxOUT.txt" -Raw
    $length = $content.Length
    Write-Host "📄 Arquivo mxOUT.txt encontrado!" -ForegroundColor Green
    Write-Host "📏 Tamanho: $length bytes" -ForegroundColor White
    
    if ($length -gt 0) {
        Write-Host "✅ CONTEÚDO:" -ForegroundColor Green
        Write-Host $content -ForegroundColor White
        
        # Verificar padrão
        if ($content -match "^\|\.(\|\.)*$") {
            Write-Host "✅ PADRÃO CORRETO: Sequência de |. sem sobreposições" -ForegroundColor Green
        } else {
            Write-Host "❌ PADRÃO INCORRETO: Possível violação de exclusão mútua" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Arquivo vazio - problema no algoritmo!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Arquivo mxOUT.txt não encontrado!" -ForegroundColor Red
}

# Mostrar logs dos processos
Write-Host "`n📊 ÚLTIMAS LINHAS DOS LOGS:" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

for ($i = 0; $i -lt 3; $i++) {
    $logFile = "logs/terminal_" + $i + "_puro.log"
    if (Test-Path $logFile) {
        Write-Host "`n🔍 Processo $($i):" -ForegroundColor Yellow
        Get-Content $logFile -Tail 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }
}

Write-Host "`n🎯 TESTE CONCLUÍDO!" -ForegroundColor Cyan
Write-Host "Para parar os processos, execute: taskkill /F /IM dimex_puro.exe" -ForegroundColor Yellow

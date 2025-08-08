# Script de Teste para DIMEX
# Verifica se o algoritmo está funcionando corretamente

Write-Host "=== TESTE DIMEX - EXCLUSÃO MÚTUA DISTRIBUÍDA ===" -ForegroundColor Green
Write-Host ""

# Remove arquivos anteriores
if (Test-Path "logs/mxOUT.txt") { Remove-Item "logs/mxOUT.txt" -Force }
Write-Host "Arquivo mxOUT.txt removido" -ForegroundColor Yellow

# Define o diretório do projeto
$projectDir = Get-Location

# Comandos para cada processo
$process0Cmd = "cd '$projectDir'; go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002"
$process1Cmd = "cd '$projectDir'; go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002"
$process2Cmd = "cd '$projectDir'; go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002"

Write-Host "Iniciando 3 processos DIMEX..." -ForegroundColor Cyan
Write-Host "Processo 0: 127.0.0.1:5000" -ForegroundColor Gray
Write-Host "Processo 1: 127.0.0.1:6001" -ForegroundColor Gray
Write-Host "Processo 2: 127.0.0.1:7002" -ForegroundColor Gray
Write-Host ""

# Inicia os processos
Start-Process powershell -ArgumentList "-Command", $process0Cmd -WindowStyle Normal
Start-Process powershell -ArgumentList "-Command", $process1Cmd -WindowStyle Normal
Start-Process powershell -ArgumentList "-Command", $process2Cmd -WindowStyle Normal

Write-Host "Processos iniciados!" -ForegroundColor Green
Write-Host "Aguardando 10 segundos para gerar dados..." -ForegroundColor Yellow

# Aguarda 10 segundos
Start-Sleep 10

# Verifica se o arquivo foi criado
if (Test-Path "logs/mxOUT.txt") {
    $content = Get-Content "logs/mxOUT.txt" -Raw
    $length = $content.Length
    
    Write-Host "`n=== RESULTADO DO TESTE ===" -ForegroundColor Green
    Write-Host "Arquivo mxOUT.txt criado com $length caracteres" -ForegroundColor Cyan
    
    # Verifica o padrão
    if ($content -match '^(\|\.)+$') {
        Write-Host "✅ PADRÃO CORRETO: Apenas sequências de '|.'" -ForegroundColor Green
    } else {
        Write-Host "❌ PADRÃO INCORRETO: Encontrados caracteres diferentes de '|.'" -ForegroundColor Red
    }
    
    # Verifica por "||" (duas entradas consecutivas)
    if ($content -match '\|\|') {
        Write-Host "❌ ERRO: Encontradas duas entradas consecutivas '||'" -ForegroundColor Red
    } else {
        Write-Host "✅ SEM ERRO: Não há duas entradas consecutivas" -ForegroundColor Green
    }
    
    # Verifica por ".." (duas saídas consecutivas)
    if ($content -match '\.\.') {
        Write-Host "❌ ERRO: Encontradas duas saídas consecutivas '..'" -ForegroundColor Red
    } else {
        Write-Host "✅ SEM ERRO: Não há duas saídas consecutivas" -ForegroundColor Green
    }
    
    # Mostra uma amostra do conteúdo
    Write-Host "`nAmostra do conteúdo (primeiros 50 caracteres):" -ForegroundColor Cyan
    Write-Host $content.Substring(0, [Math]::Min(50, $length)) -ForegroundColor White
    
} else {
    Write-Host "❌ ERRO: Arquivo mxOUT.txt não foi criado!" -ForegroundColor Red
}

Write-Host "`n=== TESTE CONCLUÍDO ===" -ForegroundColor Green
Write-Host "Para parar os processos, feche as janelas dos terminais" -ForegroundColor Gray 
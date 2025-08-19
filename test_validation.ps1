# Script para validar o arquivo mxOUT.txt
Write-Host "=== VALIDAÇÃO DO ARQUIVO mxOUT.txt ===" -ForegroundColor Green

$filePath = "logs/mxOUT.txt"

if (Test-Path $filePath) {
    $content = Get-Content $filePath -Raw
    $content = $content.Trim()
    
    Write-Host "Conteúdo do arquivo:" -ForegroundColor Yellow
    Write-Host $content -ForegroundColor White
    
    Write-Host "`n=== ANÁLISE ===" -ForegroundColor Cyan
    
    # Verifica se há "||" (duas entradas consecutivas)
    $doubleEntry = $content -match "\|\|"
    if ($doubleEntry) {
        Write-Host "❌ ERRO: Encontrado '||' (duas entradas consecutivas)" -ForegroundColor Red
    } else {
        Write-Host "✅ OK: Não há '||' (duas entradas consecutivas)" -ForegroundColor Green
    }
    
    # Verifica se há ".." (duas saídas consecutivas)
    $doubleExit = $content -match "\.\."
    if ($doubleExit) {
        Write-Host "❌ ERRO: Encontrado '..' (duas saídas consecutivas)" -ForegroundColor Red
    } else {
        Write-Host "✅ OK: Não há '..' (duas saídas consecutivas)" -ForegroundColor Green
    }
    
    # Verifica se o padrão é apenas "|."
    $validPattern = $content -match "^(\|\.)+$"
    if ($validPattern) {
        Write-Host "✅ OK: Padrão válido (apenas '|.')" -ForegroundColor Green
    } else {
        Write-Host "❌ ERRO: Padrão inválido" -ForegroundColor Red
    }
    
    # Conta quantas entradas/saídas
    $entries = ($content.ToCharArray() | Where-Object { $_ -eq '|' }).Count
    $exits = ($content.ToCharArray() | Where-Object { $_ -eq '.' }).Count
    
    Write-Host "`n=== ESTATÍSTICAS ===" -ForegroundColor Cyan
    Write-Host "Entradas (|): $entries" -ForegroundColor White
    Write-Host "Saídas (.): $exits" -ForegroundColor White
    Write-Host "Tamanho do arquivo: $($content.Length) caracteres" -ForegroundColor White
    
    if ($entries -eq $exits) {
        Write-Host "✅ OK: Número de entradas igual ao número de saídas" -ForegroundColor Green
    } else {
        Write-Host "❌ ERRO: Número de entradas diferente do número de saídas" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ ERRO: Arquivo $filePath não encontrado" -ForegroundColor Red
} 
# Script para validar o arquivo mxOUT.txt
Write-Host "=== VALIDAÇÃO DO ARQUIVO mxOUT.txt ===" -ForegroundColor Green

$filePath = "logs/mxOUT.txt"

if (Test-Path $filePath) {
    $content = Get-Content $filePath -Raw
    $content = $content.Trim()
    
    Write-Host "Conteudo do arquivo:" -ForegroundColor Yellow
    Write-Host $content -ForegroundColor White
    
    Write-Host "`n=== ANALISE ===" -ForegroundColor Cyan
    
    # Verifica se há "||" (duas entradas consecutivas)
    $doubleEntry = $content -match "\|\|"
    if ($doubleEntry) {
        Write-Host "ERRO: Encontrado '||' (duas entradas consecutivas)" -ForegroundColor Red
    } else {
        Write-Host "OK: Nao ha '||' (duas entradas consecutivas)" -ForegroundColor Green
    }
    
    # Verifica se há ".." (duas saídas consecutivas)
    $doubleExit = $content -match "\.\."
    if ($doubleExit) {
        Write-Host "ERRO: Encontrado '..' (duas saidas consecutivas)" -ForegroundColor Red
    } else {
        Write-Host "OK: Nao ha '..' (duas saidas consecutivas)" -ForegroundColor Green
    }
    
    # Verifica se o padrão é apenas "|."
    $validPattern = $content -match "^(\|\.)+$"
    if ($validPattern) {
        Write-Host "OK: Padrão valido (apenas '|.')" -ForegroundColor Green
    } else {
        Write-Host "ERRO: Padrao invalido" -ForegroundColor Red
    }
    
    # Conta quantas entradas/saídas
    $entries = ($content.ToCharArray() | Where-Object { $_ -eq '|' }).Count
    $exits = ($content.ToCharArray() | Where-Object { $_ -eq '.' }).Count
    
    Write-Host "`n=== ESTATISTICAS ===" -ForegroundColor Cyan
    Write-Host "Entradas (|): $entries" -ForegroundColor White
    Write-Host "Saidas (.): $exits" -ForegroundColor White
    Write-Host "Tamanho do arquivo: $($content.Length) caracteres" -ForegroundColor White
    
    if ($entries -eq $exits) {
        Write-Host "OK: Numero de entradas igual ao numero de saidas" -ForegroundColor Green
    } else {
        Write-Host "ERRO: Numero de entradas diferente do numero de saidas" -ForegroundColor Red
    }
    
} else {
    Write-Host "ERRO: Arquivo $filePath nao encontrado" -ForegroundColor Red
}
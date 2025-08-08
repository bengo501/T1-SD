# Teste Simples para DIMEX
Write-Host "=== TESTE SIMPLES DIMEX ===" -ForegroundColor Green

# Remove arquivo anterior
if (Test-Path "logs/mxOUT.txt") { Remove-Item "logs/mxOUT.txt" -Force }

# Inicia apenas 2 processos para teste
Write-Host "Iniciando 2 processos..." -ForegroundColor Cyan

$process0Cmd = "cd '$pwd'; go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001"
$process1Cmd = "cd '$pwd'; go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001"

Start-Process powershell -ArgumentList "-Command", $process0Cmd -WindowStyle Normal
Start-Process powershell -ArgumentList "-Command", $process1Cmd -WindowStyle Normal

Write-Host "Processos iniciados. Aguardando 15 segundos..." -ForegroundColor Yellow
Start-Sleep 15

# Verifica resultado
if (Test-Path "logs/mxOUT.txt") {
    $content = Get-Content "logs/mxOUT.txt" -Raw
    $length = $content.Length
    Write-Host "Arquivo criado com $length caracteres" -ForegroundColor Green
    
    if ($length -gt 0) {
        Write-Host "Conteúdo: $content" -ForegroundColor White
    } else {
        Write-Host "Arquivo vazio - problema na comunicação" -ForegroundColor Red
    }
} else {
    Write-Host "Arquivo não foi criado" -ForegroundColor Red
}

Write-Host "Teste concluído" -ForegroundColor Green 
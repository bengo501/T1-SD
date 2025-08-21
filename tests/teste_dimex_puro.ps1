# Script para testar DIMEX puro sem snapshots
Write-Host "=== TESTE DIMEX PURO - SEM SNAPSHOTS ===" -ForegroundColor Cyan

# Compila o projeto
Write-Host "Compilando..." -ForegroundColor Yellow
go build -o dimex_test.exe useDIMEX-puro.go

# Cria pasta logs se não existir
if (!(Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

# Limpa logs anteriores
Remove-Item "logs\*" -Force -ErrorAction SilentlyContinue

# Inicia os 3 processos em background
Write-Host "Iniciando 3 processos..." -ForegroundColor Yellow

Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_test.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal
Start-Sleep 3
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_test.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal
Start-Sleep 3
Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; .\dimex_test.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Write-Host "Processos iniciados! Aguardando 60 segundos..." -ForegroundColor Green
Start-Sleep 60

# Verifica resultados
Write-Host "Verificando resultados..." -ForegroundColor Yellow
if (Test-Path "logs/mxOUT.txt") {
    $content = Get-Content "logs/mxOUT.txt" -Raw
    Write-Host "mxOUT.txt tem $($content.Length) caracteres" -ForegroundColor Green
    if ($content.Length -gt 0) {
        Write-Host "Últimos 50 caracteres: $($content.Substring([Math]::Max(0, $content.Length - 50)))" -ForegroundColor Cyan
        
        # Verifica se há violações
        if ($content.Contains("||")) {
            Write-Host "❌ VIOLAÇÃO ENCONTRADA: '||' detectado!" -ForegroundColor Red
        } else {
            Write-Host "✅ Nenhuma violação '||' encontrada" -ForegroundColor Green
        }
        
        if ($content.Contains("..")) {
            Write-Host "❌ VIOLAÇÃO ENCONTRADA: '..' detectado!" -ForegroundColor Red
        } else {
            Write-Host "✅ Nenhuma violação '..' encontrada" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ Arquivo está vazio!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ mxOUT.txt não foi criado!" -ForegroundColor Red
}

# Para os processos
Write-Host "Parando processos..." -ForegroundColor Yellow
Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Teste concluído!" -ForegroundColor Green 
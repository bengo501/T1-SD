# Script para testar Falha 2: Deadlock
Write-Host "=== TESTE FALHA 2: DEADLOCK ===" -ForegroundColor Red
Write-Host ""

# Obtém o diretório do projeto (um nível acima)
$projectDir = Split-Path -Parent $PSScriptRoot

# Limpa logs anteriores
Write-Host "Limpando logs anteriores..." -ForegroundColor Yellow
if (Test-Path "$projectDir\logs") {
    Remove-Item "$projectDir\logs\*" -Force
}

Write-Host "Compilando o projeto com Falha 2..." -ForegroundColor Yellow
Set-Location $projectDir

# Copia a versão com falha para o diretório DIMEX
Copy-Item "src/falhas/DIMEX-Template-Falha2.go" "src/DIMEX/DIMEX-Template.go" -Force

# Compila o projeto
go build -o bin/dimex_test.exe src/useDIMEX-f.go
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro na compilação!" -ForegroundColor Red
    exit 1
}
Write-Host "Compilação concluída!" -ForegroundColor Green

# Cria pasta logs se não existir
if (!(Test-Path "$projectDir\logs")) {
    New-Item -ItemType Directory -Path "$projectDir\logs" | Out-Null
}

Write-Host ""
Write-Host "Iniciando DIMEX com Falha 2 (Deadlock)..." -ForegroundColor Cyan
Write-Host "Esta versão pode causar deadlock entre os processos" -ForegroundColor Red
Write-Host ""

# Inicia os processos
Write-Host "Iniciando Terminal 0 (Processo 0)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", "cd '$projectDir'; .\bin\dimex_test.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 1 (Processo 1)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", "cd '$projectDir'; .\bin\dimex_test.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Start-Sleep 2

Write-Host "Iniciando Terminal 2 (Processo 2)..." -ForegroundColor White
Start-Process powershell -ArgumentList "-Command", "cd '$projectDir'; .\bin\dimex_test.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -WindowStyle Normal

Write-Host ""
Write-Host "3 processos iniciados com Falha 2!" -ForegroundColor Green
Write-Host ""

Write-Host "=== INSTRUÇÕES ===" -ForegroundColor Cyan
Write-Host "1. Aguarde alguns segundos para verificar se há deadlock" -ForegroundColor White
Write-Host "2. Pressione qualquer tecla para parar os processos" -ForegroundColor White
Write-Host "3. Se houver deadlock, os processos podem ficar travados" -ForegroundColor Red
Write-Host ""

Write-Host "Pressione qualquer tecla para parar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Para os processos
Write-Host ""
Write-Host "Parando processos..." -ForegroundColor Yellow
Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep 3

# Verifica resultados
Write-Host ""
Write-Host "=== VERIFICAÇÃO DE DEADLOCK ===" -ForegroundColor Green
Write-Host ""

if (Test-Path "$projectDir\logs\mxOUT.txt") {
    $content = Get-Content "$projectDir\logs\mxOUT.txt" -Raw
    Write-Host "mxOUT.txt tem $($content.Length) caracteres" -ForegroundColor Green
    
    if ($content.Length -gt 0) {
        Write-Host "Últimos 50 caracteres: $($content.Substring([Math]::Max(0, $content.Length - 50)))" -ForegroundColor Cyan
        
        # Verifica se há pouca atividade (possível deadlock)
        if ($content.Length -lt 10) {
            Write-Host "⚠️  POSSÍVEL DEADLOCK: Pouca atividade detectada!" -ForegroundColor Red
            Write-Host "   Isso pode indicar que os processos estão travados" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Atividade normal detectada" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️  Arquivo vazio - possível deadlock!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ mxOUT.txt não foi criado!" -ForegroundColor Red
}

# Restaura a versão original
Write-Host ""
Write-Host "Restaurando versão original..." -ForegroundColor Yellow
Copy-Item "src/falhas/DIMEX-Template-Original.go" "src/DIMEX/DIMEX-Template.go" -Force

Write-Host ""
Write-Host "=== TESTE FALHA 2 CONCLUÍDO ===" -ForegroundColor Green

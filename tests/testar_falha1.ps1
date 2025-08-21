# Script para testar Falha 1: Violação de Exclusão Mútua
Write-Host "=== TESTE FALHA 1: VIOLAÇÃO DE EXCLUSÃO MÚTUA ===" -ForegroundColor Red
Write-Host ""

# Obtém o diretório do projeto (um nível acima)
$projectDir = Split-Path -Parent $PSScriptRoot

# Limpa logs anteriores
Write-Host "Limpando logs anteriores..." -ForegroundColor Yellow
if (Test-Path "$projectDir\logs") {
    Remove-Item "$projectDir\logs\*" -Force
}

Write-Host "Compilando o projeto com Falha 1..." -ForegroundColor Yellow
Set-Location $projectDir

# Copia a versão com falha para o diretório DIMEX
Copy-Item "src/falhas/DIMEX-Template-Falha1.go" "src/DIMEX/DIMEX-Template.go" -Force

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
Write-Host "Iniciando DIMEX com Falha 1 (Violação de Exclusão Mútua)..." -ForegroundColor Cyan
Write-Host "Esta versão viola a propriedade de exclusão mútua" -ForegroundColor Red
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
Write-Host "3 processos iniciados com Falha 1!" -ForegroundColor Green
Write-Host ""

Write-Host "=== INSTRUÇÕES ===" -ForegroundColor Cyan
Write-Host "1. Aguarde alguns segundos para que as violações apareçam" -ForegroundColor White
Write-Host "2. Pressione qualquer tecla para parar os processos e verificar violações" -ForegroundColor White
Write-Host "3. Verifique logs/mxOUT.txt para violações '||' ou '..'" -ForegroundColor White
Write-Host ""

Write-Host "Pressione qualquer tecla para parar e verificar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Para os processos
Write-Host ""
Write-Host "Parando processos..." -ForegroundColor Yellow
Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep 3

# Verifica resultados
Write-Host ""
Write-Host "=== VERIFICAÇÃO DE VIOLAÇÕES ===" -ForegroundColor Green
Write-Host ""

if (Test-Path "$projectDir\logs\mxOUT.txt") {
    $content = Get-Content "$projectDir\logs\mxOUT.txt" -Raw
    Write-Host "mxOUT.txt tem $($content.Length) caracteres" -ForegroundColor Green
    
    if ($content.Length -gt 0) {
        Write-Host "Últimos 50 caracteres: $($content.Substring([Math]::Max(0, $content.Length - 50)))" -ForegroundColor Cyan
        
        # Verifica violações
        if ($content.Contains("||")) {
            Write-Host "❌ VIOLAÇÃO ENCONTRADA: '||' detectado!" -ForegroundColor Red
            Write-Host "   Isso confirma que a Falha 1 está funcionando!" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Nenhuma violação '||' encontrada" -ForegroundColor Green
        }
        
        if ($content.Contains("..")) {
            Write-Host "❌ VIOLAÇÃO ENCONTRADA: '..' detectado!" -ForegroundColor Red
            Write-Host "   Isso confirma que a Falha 1 está funcionando!" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Nenhuma violação '..' encontrada" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ Arquivo está vazio!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ mxOUT.txt não foi criado!" -ForegroundColor Red
}

# Restaura a versão original
Write-Host ""
Write-Host "Restaurando versão original..." -ForegroundColor Yellow
Copy-Item "src/falhas/DIMEX-Template-Original.go" "src/DIMEX/DIMEX-Template.go" -Force

Write-Host ""
Write-Host "=== TESTE FALHA 1 CONCLUÍDO ===" -ForegroundColor Green

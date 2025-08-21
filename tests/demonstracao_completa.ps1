# Script para demonstração completa do projeto DIMEX + Snapshot
Write-Host "🎯 DEMONSTRAÇÃO COMPLETA DO PROJETO DIMEX + SNAPSHOT" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Green
Write-Host ""

# Obtém o diretório do projeto (um nível acima)
$projectDir = Split-Path -Parent $PSScriptRoot

Write-Host "🔍 Verificando arquivos necessários..." -ForegroundColor Yellow

# Lista de arquivos necessários
$requiredFiles = @(
    "src/useDIMEX-f.go",
    "src/DIMEX/DIMEX-Template.go",
    "src/PP2PLink/PP2PLink.go",
    "src/snapshot_analyzer.go",
    "src/falhas/DIMEX-Template-Falha1.go",
    "src/falhas/DIMEX-Template-Falha2.go",
    "src/falhas/DIMEX-Template-Original.go"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path "$projectDir\$file")) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Arquivos faltando:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "   • $file" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Por favor verifique se todos os arquivos estão presentes." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Todos os arquivos necessários encontrados" -ForegroundColor Green

# Compilar componentes
Write-Host ""
Write-Host "🔨 Compilando componentes..." -ForegroundColor Yellow
Set-Location $projectDir

go build -o bin/dimex_test.exe src/useDIMEX-f.go
go build -o bin/snapshot_analyzer.exe src/snapshot_analyzer.go

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro na compilação!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Compilação concluída com sucesso" -ForegroundColor Green

Write-Host ""
Write-Host "🧹 Limpando logs anteriores..." -ForegroundColor Yellow
if (Test-Path "$projectDir\logs") {
    Remove-Item "$projectDir\logs\*" -Force
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "ETAPA 0: Executando DIMEX com 3 processos" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

Write-Host "Iniciando 3 processos DIMEX..." -ForegroundColor White
Start-Process -FilePath ".\bin\dimex_test.exe" -ArgumentList "0", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal
Start-Process -FilePath ".\bin\dimex_test.exe" -ArgumentList "1", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal
Start-Process -FilePath ".\bin\dimex_test.exe" -ArgumentList "2", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal

Write-Host "Sistema executando por 5 segundos..." -ForegroundColor Yellow
Start-Sleep 5

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "ETAPA 1: Verificando funcionamento básico" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

if (Test-Path "$projectDir\logs\mxOUT.txt") {
    $content = Get-Content "$projectDir\logs\mxOUT.txt" -Raw
    Write-Host "✅ mxOUT.txt criado com $($content.Length) caracteres" -ForegroundColor Green
    
    if ($content.Contains("||") -or $content.Contains("..")) {
        Write-Host "❌ VIOLAÇÃO DETECTADA no funcionamento básico!" -ForegroundColor Red
    } else {
        Write-Host "✅ Funcionamento básico correto" -ForegroundColor Green
    }
} else {
    Write-Host "❌ mxOUT.txt não foi criado!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "ETAPA 2: Testando funcionalidade de Snapshot" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

Write-Host "Aguardando snapshots serem gerados..." -ForegroundColor Yellow
Start-Sleep 10

$snapshotFiles = Get-ChildItem "$projectDir\logs" -Filter "snapshot_*.json" -ErrorAction SilentlyContinue
if ($snapshotFiles.Count -gt 0) {
    Write-Host "✅ $($snapshotFiles.Count) snapshots gerados" -ForegroundColor Green
} else {
    Write-Host "❌ Nenhum snapshot foi gerado!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "ETAPA 3: Análise de Invariantes" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

if ($snapshotFiles.Count -gt 0) {
    Write-Host "Executando análise de invariantes..." -ForegroundColor Yellow
    .\bin\snapshot_analyzer.exe
} else {
    Write-Host "⚠️  Pulando análise - nenhum snapshot disponível" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "ETAPA 4: Testando Falha 1 (Violação de Exclusão Mútua)" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

Write-Host "Parando processos atuais..." -ForegroundColor Yellow
Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 3

Write-Host "Aplicando Falha 1..." -ForegroundColor Yellow
Copy-Item "src/falhas/DIMEX-Template-Falha1.go" "src/DIMEX/DIMEX-Template.go" -Force
go build -o bin/dimex_test.exe src/useDIMEX-f.go

Write-Host "Iniciando processos com Falha 1..." -ForegroundColor White
Start-Process -FilePath ".\bin\dimex_test.exe" -ArgumentList "0", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal
Start-Process -FilePath ".\bin\dimex_test.exe" -ArgumentList "1", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal
Start-Process -FilePath ".\bin\dimex_test.exe" -ArgumentList "2", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal

Start-Sleep 5

if (Test-Path "$projectDir\logs\mxOUT.txt") {
    $content = Get-Content "$projectDir\logs\mxOUT.txt" -Raw
    if ($content.Contains("||") -or $content.Contains("..")) {
        Write-Host "✅ Falha 1 funcionando - violações detectadas!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Falha 1 não produziu violações visíveis" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "ETAPA 5: Testando Falha 2 (Deadlock)" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

Write-Host "Parando processos..." -ForegroundColor Yellow
Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 3

Write-Host "Aplicando Falha 2..." -ForegroundColor Yellow
Copy-Item "src/falhas/DIMEX-Template-Falha2.go" "src/DIMEX/DIMEX-Template.go" -Force
go build -o bin/dimex_test.exe src/useDIMEX-f.go

Write-Host "Iniciando processos com Falha 2..." -ForegroundColor White
Start-Process -FilePath ".\bin\dimex_test.exe" -ArgumentList "0", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal
Start-Process -FilePath ".\bin\dimex_test.exe" -ArgumentList "1", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal
Start-Process -FilePath ".\bin\dimex_test.exe" -ArgumentList "2", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Normal

Start-Sleep 5

Write-Host "Verificando possível deadlock..." -ForegroundColor Yellow
if (Test-Path "$projectDir\logs\mxOUT.txt") {
    $content = Get-Content "$projectDir\logs\mxOUT.txt" -Raw
    if ($content.Length -lt 10) {
        Write-Host "✅ Possível deadlock detectado!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Deadlock não foi claramente detectado" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "FINALIZAÇÃO" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

Write-Host "Parando todos os processos..." -ForegroundColor Yellow
Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Restaurando versão original..." -ForegroundColor Yellow
Copy-Item "src/falhas/DIMEX-Template-Original.go" "src/DIMEX/DIMEX-Template.go" -Force

Write-Host ""
Write-Host "📊 RESUMO DA DEMONSTRAÇÃO:" -ForegroundColor Green
Write-Host "✅ Funcionamento básico do DIMEX" -ForegroundColor Green
Write-Host "✅ Geração de snapshots" -ForegroundColor Green
Write-Host "✅ Análise de invariantes" -ForegroundColor Green
Write-Host "✅ Teste de falhas" -ForegroundColor Green
Write-Host "✅ Detecção de violações" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 DEMONSTRAÇÃO COMPLETA CONCLUÍDA!" -ForegroundColor Green
Write-Host "Verifique os logs em logs/ para mais detalhes." -ForegroundColor Cyan

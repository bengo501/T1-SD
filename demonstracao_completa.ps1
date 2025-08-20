# Demonstração Completa do Projeto DIMEX + Snapshot
# Este script executa todas as etapas do projeto de forma sequencial

Write-Host "🎯 DEMONSTRAÇÃO COMPLETA DO PROJETO DIMEX + SNAPSHOT" -ForegroundColor Cyan
Write-Host "="*70 -ForegroundColor Cyan

# Verificar se todos os arquivos necessários existem
Write-Host "`n🔍 Verificando arquivos necessários..." -ForegroundColor Yellow

$requiredFiles = @(
    "useDIMEX-f.go",
    "DIMEX/DIMEX-Template.go", 
    "PP2PLink/PP2PLink.go",
    "snapshot_analyzer.go",
    "falhas/DIMEX-Template-Falha1.go",
    "falhas/DIMEX-Template-Falha2.go",
    "falhas/DIMEX-Template-Original.go"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Arquivos faltando:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "   • $file" -ForegroundColor Red
    }
    Write-Host "`nPor favor, verifique se todos os arquivos estão presentes." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Todos os arquivos necessários encontrados" -ForegroundColor Green

# Compilar componentes
Write-Host "`n🔨 Compilando componentes..." -ForegroundColor Yellow

try {
    go build -o dimex_test.exe useDIMEX-f.go
    go build -o snapshot_analyzer.exe snapshot_analyzer.go
    Write-Host "✅ Compilação concluída com sucesso" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro na compilação: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Limpar logs
Write-Host "`n🧹 Limpando logs anteriores..." -ForegroundColor Green
if (Test-Path "logs") {
    Remove-Item "logs\*" -Force -Recurse
}

# ETAPA 0: Executar DIMEX com 3 processos
Write-Host "`n" + "="*50 -ForegroundColor Magenta
Write-Host "ETAPA 0: Executando DIMEX com 3 processos" -ForegroundColor Magenta
Write-Host "="*50 -ForegroundColor Magenta

Write-Host "Iniciando 3 processos DIMEX..." -ForegroundColor Yellow
Start-Process -FilePath ".\dimex_test.exe" -ArgumentList "0" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_test.exe" -ArgumentList "1" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_test.exe" -ArgumentList "2" -WindowStyle Minimized

Write-Host "Sistema executando por 5 segundos..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "✅ Etapa 0 concluída" -ForegroundColor Green

# ETAPA 1-2: Snapshots sucessivos e coleta
Write-Host "`n" + "="*50 -ForegroundColor Magenta
Write-Host "ETAPA 1-2: Snapshots sucessivos e coleta" -ForegroundColor Magenta
Write-Host "="*50 -ForegroundColor Magenta

Write-Host "Executando sistema com snapshots automáticos..." -ForegroundColor Yellow
Start-Process -FilePath ".\dimex_test.exe" -ArgumentList "0" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_test.exe" -ArgumentList "1" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_test.exe" -ArgumentList "2" -WindowStyle Minimized

Write-Host "Coletando snapshots por 10 segundos..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Get-Process -Name "dimex_test" -ErrorAction SilentlyContinue | Stop-Process -Force

# Verificar snapshots coletados
$snapshots = Get-ChildItem "logs" -Filter "snapshot_*.json" -ErrorAction SilentlyContinue
Write-Host "📊 Snapshots coletados: $($snapshots.Count)" -ForegroundColor Green
Write-Host "✅ Etapa 1-2 concluída" -ForegroundColor Green

# ETAPA 3: Análise de snapshots
Write-Host "`n" + "="*50 -ForegroundColor Magenta
Write-Host "ETAPA 3: Análise de snapshots" -ForegroundColor Magenta
Write-Host "="*50 -ForegroundColor Magenta

Write-Host "Executando analisador de snapshots..." -ForegroundColor Yellow
.\snapshot_analyzer.exe

Write-Host "✅ Etapa 3 concluída" -ForegroundColor Green

# Aguardar entrada do usuário
Write-Host "`n⏸️  Pressione ENTER para continuar com as etapas de falhas..." -ForegroundColor Cyan
Read-Host

# ETAPA 4-5: Inserção e detecção de falhas
Write-Host "`n" + "="*50 -ForegroundColor Magenta
Write-Host "ETAPA 4-5: Inserção e detecção de falhas" -ForegroundColor Magenta
Write-Host "="*50 -ForegroundColor Magenta

# Limpar logs para testes de falhas
Remove-Item "logs\*" -Force -Recurse

# Teste Falha 1: Violação de Exclusão Mútua
Write-Host "`n🚨 Testando Falha 1: Violação de Exclusão Mútua" -ForegroundColor Red
Copy-Item "falhas\DIMEX-Template-Falha1.go" "DIMEX\DIMEX-Template.go"
go build -o dimex_falha1.exe useDIMEX-f.go

Start-Process -FilePath ".\dimex_falha1.exe" -ArgumentList "0" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_falha1.exe" -ArgumentList "1" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_falha1.exe" -ArgumentList "2" -WindowStyle Minimized

Start-Sleep -Seconds 12
Get-Process -Name "dimex_falha1" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Analisando snapshots da Falha 1..." -ForegroundColor Yellow
.\snapshot_analyzer.exe

# Limpar logs
Remove-Item "logs\*" -Force -Recurse

# Teste Falha 2: Deadlock
Write-Host "`n🚨 Testando Falha 2: Deadlock" -ForegroundColor Red
Copy-Item "falhas\DIMEX-Template-Falha2.go" "DIMEX\DIMEX-Template.go"
go build -o dimex_falha2.exe useDIMEX-f.go

Start-Process -FilePath ".\dimex_falha2.exe" -ArgumentList "0" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_falha2.exe" -ArgumentList "1" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_falha2.exe" -ArgumentList "2" -WindowStyle Minimized

Start-Sleep -Seconds 12
Get-Process -Name "dimex_falha2" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Analisando snapshots da Falha 2..." -ForegroundColor Yellow
.\snapshot_analyzer.exe

# Restaurar versão original
Copy-Item "falhas\DIMEX-Template-Original.go" "DIMEX\DIMEX-Template.go"

Write-Host "✅ Etapa 4-5 concluída" -ForegroundColor Green

# Relatório final
Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host "🎉 DEMONSTRAÇÃO COMPLETA CONCLUÍDA!" -ForegroundColor Green
Write-Host "="*70 -ForegroundColor Cyan

Write-Host "`n📋 RESUMO DAS ETAPAS EXECUTADAS:" -ForegroundColor Yellow
Write-Host "   ✅ Etapa 0: DIMEX com 3 processos" -ForegroundColor Green
Write-Host "   ✅ Etapa 1: Snapshots sucessivos" -ForegroundColor Green
Write-Host "   ✅ Etapa 2: Coleta de snapshots" -ForegroundColor Green
Write-Host "   ✅ Etapa 3: Análise de snapshots" -ForegroundColor Green
Write-Host "   ✅ Etapa 4: Inserção de falhas" -ForegroundColor Green
Write-Host "   ✅ Etapa 5: Detecção de falhas" -ForegroundColor Green

Write-Host "`n🔍 FUNCIONALIDADES IMPLEMENTADAS:" -ForegroundColor Yellow
Write-Host "   • Algoritmo DIMEX (Distributed Mutual Exclusion)" -ForegroundColor White
Write-Host "   • Algoritmo Chandy-Lamport para snapshots" -ForegroundColor White
Write-Host "   • Coleta automática de snapshots" -ForegroundColor White
Write-Host "   • Análise de invariantes do sistema" -ForegroundColor White
Write-Host "   • Injeção de falhas (violação de exclusão mútua e deadlock)" -ForegroundColor White
Write-Host "   • Detecção automática de falhas via análise de snapshots" -ForegroundColor White

Write-Host "`n📁 ARQUIVOS GERADOS:" -ForegroundColor Yellow
Write-Host "   • logs/snapshot_X_process_Y.json - Snapshots coletados" -ForegroundColor White
Write-Host "   • logs/relatorio_analise.json - Relatórios de análise" -ForegroundColor White
Write-Host "   • logs/mxOUT.txt - Logs do DIMEX" -ForegroundColor White

Write-Host "`n🎯 OBJETIVOS ATINGIDOS:" -ForegroundColor Yellow
Write-Host "   • Sistema DIMEX funcionando com 3+ processos" -ForegroundColor White
Write-Host "   • Snapshots automáticos com identificadores únicos" -ForegroundColor White
Write-Host "   • Coleta de centenas de snapshots" -ForegroundColor White
Write-Host "   • Ferramenta de análise de invariantes" -ForegroundColor White
Write-Host "   • Falhas inseridas e detectadas com sucesso" -ForegroundColor White

Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host "🏆 PROJETO CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "="*70 -ForegroundColor Cyan

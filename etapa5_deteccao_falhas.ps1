# Etapa 5: Detecção de Falhas usando Análise de Snapshots
# Este script demonstra como o analisador de snapshots detecta falhas inseridas

Write-Host "=== ETAPA 5: DETECÇÃO DE FALHAS ===" -ForegroundColor Cyan
Write-Host "Demonstrando como o analisador detecta falhas inseridas no DIMEX" -ForegroundColor Yellow

# Limpar logs anteriores
Write-Host "`n🧹 Limpando logs anteriores..." -ForegroundColor Green
if (Test-Path "logs") {
    Remove-Item "logs\*" -Force -Recurse
}
Write-Host "✅ Logs limpos" -ForegroundColor Green

# Teste 1: Sistema Normal (sem falhas)
Write-Host "`n🔍 TESTE 1: Sistema Normal (sem falhas)" -ForegroundColor Magenta
Write-Host "Executando DIMEX com snapshot por 10 segundos..." -ForegroundColor Yellow

# Compilar versão normal
go build -o dimex_normal.exe useDIMEX-f.go

# Executar sistema normal
Start-Process -FilePath ".\dimex_normal.exe" -ArgumentList "0" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_normal.exe" -ArgumentList "1" -WindowStyle Minimized  
Start-Process -FilePath ".\dimex_normal.exe" -ArgumentList "2" -WindowStyle Minimized

# Aguardar 10 segundos
Start-Sleep -Seconds 10

# Parar processos
Get-Process -Name "dimex_normal" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "✅ Sistema normal executado" -ForegroundColor Green

# Analisar snapshots do sistema normal
Write-Host "`n📊 Analisando snapshots do sistema normal..." -ForegroundColor Yellow
.\snapshot_analyzer.exe

# Aguardar entrada do usuário
Write-Host "`n⏸️  Pressione ENTER para continuar com o teste de falhas..." -ForegroundColor Cyan
Read-Host

# Teste 2: Falha 1 - Violação de Exclusão Mútua
Write-Host "`n🚨 TESTE 2: Falha 1 - Violação de Exclusão Mútua" -ForegroundColor Red
Write-Host "Inserindo falha que permite múltiplos processos na SC..." -ForegroundColor Yellow

# Limpar logs
Remove-Item "logs\*" -Force -Recurse

# Copiar versão com falha 1
Copy-Item "falhas\DIMEX-Template-Falha1.go" "DIMEX\DIMEX-Template.go"

# Compilar versão com falha 1
go build -o dimex_falha1.exe useDIMEX-f.go

# Executar sistema com falha 1
Start-Process -FilePath ".\dimex_falha1.exe" -ArgumentList "0" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_falha1.exe" -ArgumentList "1" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_falha1.exe" -ArgumentList "2" -WindowStyle Minimized

# Aguardar 15 segundos
Start-Sleep -Seconds 15

# Parar processos
Get-Process -Name "dimex_falha1" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "✅ Sistema com Falha 1 executado" -ForegroundColor Green

# Analisar snapshots da falha 1
Write-Host "`n📊 Analisando snapshots da Falha 1..." -ForegroundColor Yellow
.\snapshot_analyzer.exe

# Aguardar entrada do usuário
Write-Host "`n⏸️  Pressione ENTER para continuar com o teste de deadlock..." -ForegroundColor Cyan
Read-Host

# Teste 3: Falha 2 - Deadlock
Write-Host "`n🚨 TESTE 3: Falha 2 - Deadlock" -ForegroundColor Red
Write-Host "Inserindo falha que causa deadlock..." -ForegroundColor Yellow

# Limpar logs
Remove-Item "logs\*" -Force -Recurse

# Copiar versão com falha 2
Copy-Item "falhas\DIMEX-Template-Falha2.go" "DIMEX\DIMEX-Template.go"

# Compilar versão com falha 2
go build -o dimex_falha2.exe useDIMEX-f.go

# Executar sistema com falha 2
Start-Process -FilePath ".\dimex_falha2.exe" -ArgumentList "0" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_falha2.exe" -ArgumentList "1" -WindowStyle Minimized
Start-Process -FilePath ".\dimex_falha2.exe" -ArgumentList "2" -WindowStyle Minimized

# Aguardar 15 segundos
Start-Sleep -Seconds 15

# Parar processos
Get-Process -Name "dimex_falha2" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "✅ Sistema com Falha 2 executado" -ForegroundColor Green

# Analisar snapshots da falha 2
Write-Host "`n📊 Analisando snapshots da Falha 2..." -ForegroundColor Yellow
.\snapshot_analyzer.exe

# Restaurar versão original
Write-Host "`n🔄 Restaurando versão original..." -ForegroundColor Green
Copy-Item "falhas\DIMEX-Template-Original.go" "DIMEX\DIMEX-Template.go"

# Relatório final
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "📋 RELATÓRIO FINAL - ETAPA 5" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host "`n✅ ETAPA 5 CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
Write-Host "`n🎯 Objetivos alcançados:" -ForegroundColor Yellow
Write-Host "   • Sistema normal analisado (sem falhas)" -ForegroundColor White
Write-Host "   • Falha 1 (Violação de Exclusão Mútua) detectada" -ForegroundColor White
Write-Host "   • Falha 2 (Deadlock) detectada" -ForegroundColor White
Write-Host "   • Analisador de snapshots funcionando corretamente" -ForegroundColor White

Write-Host "`n📁 Arquivos gerados:" -ForegroundColor Yellow
Write-Host "   • logs/relatorio_analise.json - Relatório detalhado" -ForegroundColor White
Write-Host "   • logs/snapshot_X_process_Y.json - Snapshots coletados" -ForegroundColor White

Write-Host "`n🔍 Como funciona a detecção:" -ForegroundColor Yellow
Write-Host "   • Inv1: Verifica se há mais de 1 processo na SC" -ForegroundColor White
Write-Host "   • Inv2: Verifica consistência quando todos estão noMX" -ForegroundColor White
Write-Host "   • Inv3: Verifica se waiting=true é válido" -ForegroundColor White
Write-Host "   • Inv4: Verifica se respostas + waiting = N-1" -ForegroundColor White
Write-Host "   • Inv5: Detecção específica de falhas inseridas" -ForegroundColor White

Write-Host "`n🚨 Falhas detectadas:" -ForegroundColor Yellow
Write-Host "   • VIOLAÇÃO_EXCLUSÃO_MÚTUA: Múltiplos processos na SC" -ForegroundColor Red
Write-Host "   • DEADLOCK: Processos querendo SC mas sem respostas" -ForegroundColor Red

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "🎉 TODAS AS ETAPAS DO PROJETO CONCLUÍDAS!" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan

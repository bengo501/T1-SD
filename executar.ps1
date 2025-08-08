# Script Principal para Executar DIMEX
# Facilita a execução dos scripts organizados na pasta scripts/

Write-Host "=== DIMEX - SISTEMA DE EXCLUSÃO MÚTUA DISTRIBUÍDA ===" -ForegroundColor Green
Write-Host ""

Write-Host "Escolha uma opção:" -ForegroundColor Cyan
Write-Host "1 - Executar DIMEX Simples (3 terminais)" -ForegroundColor White
Write-Host "2 - Executar DIMEX com Monitoramento (4 terminais)" -ForegroundColor White
Write-Host "3 - Executar DIMEX Completo (versão avançada)" -ForegroundColor White
Write-Host "4 - Visualizar Logs (menu interativo)" -ForegroundColor White
Write-Host "5 - Visualizar Logs em Tempo Real" -ForegroundColor White
Write-Host "6 - Limpar Logs Anteriores" -ForegroundColor White
Write-Host "7 - Sair" -ForegroundColor Red

Write-Host ""
$choice = Read-Host "Digite sua escolha (1-7)"

switch ($choice) {
    "1" {
        Write-Host "`nExecutando DIMEX Simples..." -ForegroundColor Green
        & ".\scripts\executar_simples.ps1"
    }
    "2" {
        Write-Host "`nExecutando DIMEX com Monitoramento..." -ForegroundColor Green
        & ".\scripts\executar_com_monitor.ps1"
    }
    "3" {
        Write-Host "`nExecutando DIMEX Completo..." -ForegroundColor Green
        & ".\scripts\executar_completo.ps1"
    }
    "4" {
        Write-Host "`nAbrindo Visualizador de Logs..." -ForegroundColor Green
        & ".\scripts\ver_logs.ps1"
    }
    "5" {
        Write-Host "`nAbrindo Visualizador de Logs em Tempo Real..." -ForegroundColor Green
        & ".\scripts\ver_logs_tempo_real.ps1"
    }
    "6" {
        Write-Host "`nLimpando logs anteriores..." -ForegroundColor Yellow
        if (Test-Path "logs/mxOUT.txt") { Remove-Item "logs/mxOUT.txt" -Force }
        if (Test-Path "logs/terminal_0.log") { Remove-Item "logs/terminal_0.log" -Force }
        if (Test-Path "logs/terminal_1.log") { Remove-Item "logs/terminal_1.log" -Force }
        if (Test-Path "logs/terminal_2.log") { Remove-Item "logs/terminal_2.log" -Force }
        Write-Host "Logs removidos com sucesso!" -ForegroundColor Green
    }
    "7" {
        Write-Host "`nSaindo..." -ForegroundColor Red
        exit
    }
    default {
        Write-Host "`nOpção inválida!" -ForegroundColor Red
        Write-Host "Execute o script novamente e escolha uma opção válida." -ForegroundColor Yellow
    }
}

Write-Host "`n=== Script Concluído ===" -ForegroundColor Green 
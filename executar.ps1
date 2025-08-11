# Menu Principal - Sistema DIMEX
Write-Host "=== SISTEMA DIMEX - MENU PRINCIPAL ===" -ForegroundColor Green
Write-Host ""

Write-Host "Escolha uma opcao:" -ForegroundColor Cyan
Write-Host "1. Execucao Simples (3 processos)" -ForegroundColor White
Write-Host "2. Execucao com Monitor" -ForegroundColor White
Write-Host "3. Execucao Completa (com logs detalhados)" -ForegroundColor White
Write-Host "4. Teste Final (validacao completa)" -ForegroundColor White
Write-Host "5. Visualizar Logs" -ForegroundColor White
Write-Host "6. Visualizar Logs em Tempo Real" -ForegroundColor White
Write-Host "7. Limpar Logs" -ForegroundColor White
Write-Host "8. Sair" -ForegroundColor White
Write-Host ""

$opcao = Read-Host "Digite sua opcao (1-8)"

switch ($opcao) {
    "1" {
        Write-Host "`nExecutando DIMEX Simples..." -ForegroundColor Yellow
        & ".\scripts\executar_simples.ps1"
    }
    "2" {
        Write-Host "`nExecutando DIMEX com Monitor..." -ForegroundColor Yellow
        & ".\scripts\executar_com_monitor.ps1"
    }
    "3" {
        Write-Host "`nExecutando DIMEX Completo..." -ForegroundColor Yellow
        & ".\scripts\executar_completo.ps1"
    }
    "4" {
        Write-Host "`nExecutando Teste Final..." -ForegroundColor Yellow
        & ".\scripts\test_final.ps1"
    }
    "5" {
        Write-Host "`nAbrindo Visualizador de Logs..." -ForegroundColor Yellow
        & ".\scripts\ver_logs.ps1"
    }
    "6" {
        Write-Host "`nAbrindo Visualizador de Logs em Tempo Real..." -ForegroundColor Yellow
        & ".\scripts\ver_logs_tempo_real.ps1"
    }
    "7" {
        Write-Host "`nLimpando logs..." -ForegroundColor Yellow
        if (Test-Path "logs") {
            Remove-Item "logs\*" -Force -Recurse
            Write-Host "Logs limpos com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "Pasta logs nao existe." -ForegroundColor Gray
        }
    }
    "8" {
        Write-Host "`nSaindo..." -ForegroundColor Yellow
        exit
    }
    default {
        Write-Host "`nOpcao invalida!" -ForegroundColor Red
        Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Write-Host ""
        & ".\executar.ps1"
    }
} 
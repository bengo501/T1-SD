# Menu Principal - Sistema DIMEX
Write-Host "=== SISTEMA DIMEX - MENU PRINCIPAL ===" -ForegroundColor Green
Write-Host ""

Write-Host "Escolha uma opcao:" -ForegroundColor Cyan
Write-Host "1. Executar com 3 Terminais (Processos DIMEX)" -ForegroundColor White
Write-Host "2. Executar com 4 Terminais (3 Processos + Monitor)" -ForegroundColor White
Write-Host "3. Sair" -ForegroundColor White
Write-Host ""

$opcao = Read-Host "Digite sua opcao (1-3)"

switch ($opcao) {
    "1" {
        Write-Host "`nExecutando DIMEX com 3 terminais..." -ForegroundColor Yellow
        & ".\scripts\executar_simples.ps1"
    }
    "2" {
        Write-Host "`nExecutando DIMEX com 4 terminais (3 processos + monitor)..." -ForegroundColor Yellow
        & ".\scripts\executar_com_monitor.ps1"
    }
    "3" {
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
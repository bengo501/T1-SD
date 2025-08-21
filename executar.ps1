# Menu Principal - Sistema DIMEX + Snapshot
Write-Host "=== SISTEMA DIMEX + SNAPSHOT - MENU PRINCIPAL ===" -ForegroundColor Green
Write-Host ""

do {
    Write-Host "`nEscolha uma opção:" -ForegroundColor Yellow
    Write-Host "1. Executar com 3 Terminais" -ForegroundColor White
    Write-Host "2. Executar com 4 Terminais (3 Processos + Monitor)" -ForegroundColor White
    Write-Host "3. Executar com Snapshot" -ForegroundColor White
    Write-Host "4. Testar Falha 1 (Violação de Exclusão Mútua)" -ForegroundColor White
    Write-Host "5. Testar Falha 2 (Deadlock)" -ForegroundColor White
    Write-Host "6. Demonstração Completa (Todas as Etapas)" -ForegroundColor White
    Write-Host "7. Sair" -ForegroundColor White
    
    $opcao = Read-Host "`nDigite sua opção (1-7)"
    
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
            Write-Host "`nExecutando DIMEX com funcionalidade de snapshot..." -ForegroundColor Yellow
            & ".\executar_com_snapshot.ps1"
        }
        "4" {
            Write-Host "`nTestando Falha 1: Violação de Exclusão Mútua..." -ForegroundColor Yellow
            & ".\tests\testar_falha1.ps1"
        }
        "5" {
            Write-Host "`nTestando Falha 2: Deadlock..." -ForegroundColor Yellow
            & ".\tests\testar_falha2.ps1"
        }
        "6" {
            Write-Host "`nExecutando demonstração completa..." -ForegroundColor Yellow
            & ".\tests\demonstracao_completa.ps1"
        }
        "7" {
            Write-Host "`nSaindo..." -ForegroundColor Green
            break
        }
        default {
            Write-Host "`nOpção inválida! Digite um número de 1 a 7." -ForegroundColor Red
        }
    }
} while ($opcao -ne "7") 
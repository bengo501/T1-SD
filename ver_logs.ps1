# Script para visualizar os logs dos terminais

Write-Host "=== Visualizador de Logs DIMEX ===" -ForegroundColor Green

# Verifica se os arquivos de log existem
$logs = @("terminal_0.log", "terminal_1.log", "terminal_2.log", "mxOUT.txt")
$existingLogs = @()

foreach ($log in $logs) {
    if (Test-Path $log) {
        $existingLogs += $log
        $size = (Get-Item $log).Length
        Write-Host "✅ $log ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "❌ $log (não encontrado)" -ForegroundColor Red
    }
}

if ($existingLogs.Count -eq 0) {
    Write-Host "`nNenhum log encontrado. Execute primeiro o script de execução." -ForegroundColor Yellow
    exit
}

Write-Host "`nEscolha uma opção:" -ForegroundColor Cyan
Write-Host "1 - Ver mxOUT.txt (resultado do algoritmo)" -ForegroundColor White
Write-Host "2 - Ver terminal_0.log (Processo 0)" -ForegroundColor White
Write-Host "3 - Ver terminal_1.log (Processo 1)" -ForegroundColor White
Write-Host "4 - Ver terminal_2.log (Processo 2)" -ForegroundColor White
Write-Host "5 - Ver todos os logs" -ForegroundColor White
Write-Host "6 - Monitorar mxOUT.txt em tempo real" -ForegroundColor White

$choice = Read-Host "`nDigite sua escolha (1-6)"

switch ($choice) {
    "1" {
        if (Test-Path "mxOUT.txt") {
            Write-Host "`n=== mxOUT.txt ===" -ForegroundColor Green
            Get-Content "mxOUT.txt"
        }
    }
    "2" {
        if (Test-Path "terminal_0.log") {
            Write-Host "`n=== terminal_0.log (Processo 0) ===" -ForegroundColor Green
            Get-Content "terminal_0.log"
        }
    }
    "3" {
        if (Test-Path "terminal_1.log") {
            Write-Host "`n=== terminal_1.log (Processo 1) ===" -ForegroundColor Green
            Get-Content "terminal_1.log"
        }
    }
    "4" {
        if (Test-Path "terminal_2.log") {
            Write-Host "`n=== terminal_2.log (Processo 2) ===" -ForegroundColor Green
            Get-Content "terminal_2.log"
        }
    }
    "5" {
        Write-Host "`n=== TODOS OS LOGS ===" -ForegroundColor Green
        foreach ($log in $existingLogs) {
            Write-Host "`n--- $log ---" -ForegroundColor Yellow
            Get-Content $log
        }
    }
    "6" {
        if (Test-Path "mxOUT.txt") {
            Write-Host "`n=== Monitorando mxOUT.txt (Ctrl+C para parar) ===" -ForegroundColor Green
            Get-Content "mxOUT.txt" -Wait -Tail 10
        }
    }
    default {
        Write-Host "Opção inválida!" -ForegroundColor Red
    }
}

Write-Host "`n=== Visualizador Concluído ===" -ForegroundColor Green

# Script para visualizar logs em tempo real com identificação dos terminais

Write-Host "Visualizador de Logs em Tempo Real - DIMEX" -ForegroundColor Green
Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Yellow
Write-Host ""

while ($true) {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "     LOGS EM TEMPO REAL - DIMEX" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Verifica se os arquivos de log existem
    if (Test-Path "logs/terminal_0.log") {
        Write-Host "--- TERMINAL 0 (Processo 0) ---" -ForegroundColor Green
        $content0 = Get-Content "logs/terminal_0.log" -Tail 5
        foreach ($line in $content0) {
            Write-Host "  $line" -ForegroundColor Green
        }
        Write-Host ""
    }
    
    if (Test-Path "logs/terminal_1.log") {
        Write-Host "--- TERMINAL 1 (Processo 1) ---" -ForegroundColor Blue
        $content1 = Get-Content "logs/terminal_1.log" -Tail 5
        foreach ($line in $content1) {
            Write-Host "  $line" -ForegroundColor Blue
        }
        Write-Host ""
    }
    
    if (Test-Path "logs/terminal_2.log") {
        Write-Host "--- TERMINAL 2 (Processo 2) ---" -ForegroundColor Magenta
        $content2 = Get-Content "logs/terminal_2.log" -Tail 5
        foreach ($line in $content2) {
            Write-Host "  $line" -ForegroundColor Magenta
        }
        Write-Host ""
    }
    
    # Mostra o resultado do algoritmo
    if (Test-Path "logs/mxOUT.txt") {
        Write-Host "--- RESULTADO DO ALGORITMO (mxOUT.txt) ---" -ForegroundColor Yellow
        $mxContent = Get-Content "logs/mxOUT.txt" -Tail 3
        foreach ($line in $mxContent) {
            Write-Host "  $line" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Atualizado em: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
    Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor Cyan
    
    Start-Sleep 2
}

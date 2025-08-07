# Script para visualizar logs dos 3 terminais em tempo real
# Mostra os logs de todos os processos simultaneamente

Write-Host "📊 Visualizador de Logs em Tempo Real - DIMEX" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

Write-Host "`nEscolha uma opção:" -ForegroundColor Yellow
Write-Host "1. Ver log do Terminal 0 (Processo 0)" -ForegroundColor Green
Write-Host "2. Ver log do Terminal 1 (Processo 1)" -ForegroundColor Blue
Write-Host "3. Ver log do Terminal 2 (Processo 2)" -ForegroundColor Magenta
Write-Host "4. Ver todos os logs simultaneamente" -ForegroundColor Yellow
Write-Host "5. Ver mxOUT.txt em tempo real" -ForegroundColor Cyan
Write-Host "6. Sair" -ForegroundColor Red

Write-Host "`nDigite sua escolha (1-6): " -ForegroundColor White -NoNewline
$choice = Read-Host

switch ($choice) {
    "1" {
        Write-Host "`n📊 Visualizando log do Terminal 0 (Processo 0)..." -ForegroundColor Green
        Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Gray
        Write-Host "─" * 60 -ForegroundColor Gray
        Get-Content "terminal_0.log" -Wait -Tail 20 -ErrorAction SilentlyContinue
    }
    "2" {
        Write-Host "`n📊 Visualizando log do Terminal 1 (Processo 1)..." -ForegroundColor Blue
        Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Gray
        Write-Host "─" * 60 -ForegroundColor Gray
        Get-Content "terminal_1.log" -Wait -Tail 20 -ErrorAction SilentlyContinue
    }
    "3" {
        Write-Host "`n📊 Visualizando log do Terminal 2 (Processo 2)..." -ForegroundColor Magenta
        Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Gray
        Write-Host "─" * 60 -ForegroundColor Gray
        Get-Content "terminal_2.log" -Wait -Tail 20 -ErrorAction SilentlyContinue
    }
    "4" {
        Write-Host "`n📊 Visualizando todos os logs simultaneamente..." -ForegroundColor Yellow
        Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Gray
        Write-Host "─" * 60 -ForegroundColor Gray
        
        # Inicia jobs para monitorar todos os logs
        $job0 = Start-Job -ScriptBlock { Get-Content "terminal_0.log" -Wait -Tail 5 -ErrorAction SilentlyContinue }
        $job1 = Start-Job -ScriptBlock { Get-Content "terminal_1.log" -Wait -Tail 5 -ErrorAction SilentlyContinue }
        $job2 = Start-Job -ScriptBlock { Get-Content "terminal_2.log" -Wait -Tail 5 -ErrorAction SilentlyContinue }
        
        try {
            while ($true) {
                Clear-Host
                Write-Host "📊 LOGS EM TEMPO REAL - DIMEX" -ForegroundColor Cyan
                Write-Host "=" * 60 -ForegroundColor Gray
                
                # Terminal 0
                Write-Host "`n🟢 TERMINAL 0 (Processo 0):" -ForegroundColor Green
                Write-Host "─" * 40 -ForegroundColor Gray
                $log0 = Receive-Job $job0 -Keep
                if ($log0) { $log0 | Select-Object -Last 3 }
                
                # Terminal 1
                Write-Host "`n🔵 TERMINAL 1 (Processo 1):" -ForegroundColor Blue
                Write-Host "─" * 40 -ForegroundColor Gray
                $log1 = Receive-Job $job1 -Keep
                if ($log1) { $log1 | Select-Object -Last 3 }
                
                # Terminal 2
                Write-Host "`n🟣 TERMINAL 2 (Processo 2):" -ForegroundColor Magenta
                Write-Host "─" * 40 -ForegroundColor Gray
                $log2 = Receive-Job $job2 -Keep
                if ($log2) { $log2 | Select-Object -Last 3 }
                
                Write-Host "`n🕐 Última atualização:" (Get-Date -Format 'HH:mm:ss') -ForegroundColor Gray
                Start-Sleep 2
            }
        }
        finally {
            Stop-Job $job0, $job1, $job2 -ErrorAction SilentlyContinue
            Remove-Job $job0, $job1, $job2 -ErrorAction SilentlyContinue
        }
    }
    "5" {
        Write-Host "`n📊 Visualizando mxOUT.txt em tempo real..." -ForegroundColor Cyan
        Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Gray
        Write-Host "─" * 60 -ForegroundColor Gray
        Get-Content "mxOUT.txt" -Wait -Tail 10 -ErrorAction SilentlyContinue
    }
    "6" {
        Write-Host "`n👋 Saindo..." -ForegroundColor Red
        exit
    }
    default {
        Write-Host "`n❌ Opção inválida!" -ForegroundColor Red
        Write-Host "Execute o script novamente e escolha uma opção válida." -ForegroundColor Yellow
    }
}

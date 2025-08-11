# Teste Final DIMEX - Sistema Completo
Write-Host "=== TESTE FINAL DIMEX - SISTEMA COMPLETO ===" -ForegroundColor Green

# Remove arquivo anterior
if (Test-Path "logs/mxOUT.txt") { Remove-Item "logs/mxOUT.txt" -Force }

Write-Host "Iniciando teste com 3 processos..." -ForegroundColor Cyan
Write-Host "Processo 0: 127.0.0.1:5000" -ForegroundColor Gray
Write-Host "Processo 1: 127.0.0.1:6001" -ForegroundColor Gray
Write-Host "Processo 2: 127.0.0.1:7002" -ForegroundColor Gray

# Executa três processos
$process0Cmd = "cd '$pwd'; go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002"
$process1Cmd = "cd '$pwd'; go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002"
$process2Cmd = "cd '$pwd'; go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002"

Write-Host "`nIniciando processos com intervalo de 2 segundos..." -ForegroundColor Yellow

$process0 = Start-Process powershell -ArgumentList "-Command", $process0Cmd -WindowStyle Normal -PassThru
Start-Sleep 2

$process1 = Start-Process powershell -ArgumentList "-Command", $process1Cmd -WindowStyle Normal -PassThru
Start-Sleep 2

$process2 = Start-Process powershell -ArgumentList "-Command", $process2Cmd -WindowStyle Normal -PassThru

Write-Host "Todos os processos iniciados. Aguardando 20 segundos para comunicação..." -ForegroundColor Yellow
Start-Sleep 20

# Verifica status dos processos
Write-Host "`n=== STATUS DOS PROCESSOS ===" -ForegroundColor Cyan
if (!$process0.HasExited) {
    Write-Host "Processo 0 ainda está rodando" -ForegroundColor Green
} else {
    Write-Host "Processo 0 terminou (código: $($process0.ExitCode))" -ForegroundColor Red
}

if (!$process1.HasExited) {
    Write-Host "Processo 1 ainda está rodando" -ForegroundColor Green
} else {
    Write-Host "Processo 1 terminou (código: $($process1.ExitCode))" -ForegroundColor Red
}

if (!$process2.HasExited) {
    Write-Host "Processo 2 ainda está rodando" -ForegroundColor Green
} else {
    Write-Host "Processo 2 terminou (código: $($process2.ExitCode))" -ForegroundColor Red
}

# Verifica resultado
Write-Host "`n=== RESULTADO DO ALGORITMO ===" -ForegroundColor Cyan
if (Test-Path "logs/mxOUT.txt") {
    $content = Get-Content "logs/mxOUT.txt" -Raw
    $length = $content.Length
    Write-Host "Arquivo mxOUT.txt criado com $length caracteres" -ForegroundColor Green
    
    if ($length -gt 0) {
        Write-Host "Conteúdo (primeiros 200 caracteres):" -ForegroundColor White
        Write-Host $content.Substring(0, [Math]::Min(200, $length)) -ForegroundColor Yellow
        Write-Host ""
        
        # Verifica o padrão
        $pattern = $content -replace '[\r\n]', ''
        if ($pattern -match '^(\|\.)+$') {
            Write-Host "PADRÃO CORRETO: Apenas sequências de '|.'" -ForegroundColor Green
        } else {
            Write-Host "PADRÃO INCORRETO: Encontrados caracteres diferentes de '|.'" -ForegroundColor Red
        }
        
        # Verifica por "||" (duas entradas consecutivas)
        if ($pattern -match '\|\|') {
            Write-Host "ERRO: Encontradas duas entradas consecutivas '||'" -ForegroundColor Red
        } else {
            Write-Host "SEM ERRO: Não há duas entradas consecutivas" -ForegroundColor Green
        }
        
        # Verifica por ".." (duas saídas consecutivas)
        if ($pattern -match '\.\.') {
            Write-Host "ERRO: Encontradas duas saídas consecutivas '..'" -ForegroundColor Red
        } else {
            Write-Host "SEM ERRO: Não há duas saídas consecutivas" -ForegroundColor Green
        }
        
        # Estatísticas
        $entradas = ($pattern.ToCharArray() | Where-Object { $_ -eq '|' }).Count
        $saidas = ($pattern.ToCharArray() | Where-Object { $_ -eq '.' }).Count
        Write-Host "`nEstatísticas:" -ForegroundColor Cyan
        Write-Host "   Entradas na SC: $entradas" -ForegroundColor Gray
        Write-Host "   Saídas da SC: $saidas" -ForegroundColor Gray
        
        if ($entradas -eq $saidas) {
            Write-Host "BALANCEAMENTO CORRETO: Entradas = Saídas" -ForegroundColor Green
        } else {
            Write-Host "DESBALANCEAMENTO: Entradas ≠ Saídas (pode ser normal se processos ainda estão rodando)" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "Arquivo vazio - problema na comunicação ou execução" -ForegroundColor Red
    }
} else {
    Write-Host "Arquivo não foi criado - problema na inicialização" -ForegroundColor Red
}

Write-Host "`n=== TESTE FINAL CONCLUÍDO ===" -ForegroundColor Green
Write-Host "Para parar os processos, feche as janelas dos terminais ou pressione Ctrl+C" -ForegroundColor Gray 
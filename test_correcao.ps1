# Teste da Correção - Sistema DIMEX
Write-Host "=== TESTE DA CORREÇÃO DIMEX ===" -ForegroundColor Green

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

Write-Host "`nIniciando processos com intervalo de 3 segundos..." -ForegroundColor Yellow

$process0 = Start-Process powershell -ArgumentList "-Command", $process0Cmd -WindowStyle Normal -PassThru
Start-Sleep 3

$process1 = Start-Process powershell -ArgumentList "-Command", $process1Cmd -WindowStyle Normal -PassThru
Start-Sleep 3

$process2 = Start-Process powershell -ArgumentList "-Command", $process2Cmd -WindowStyle Normal -PassThru

Write-Host "Todos os processos iniciados. Aguardando 30 segundos para comunicação..." -ForegroundColor Yellow
Start-Sleep 30

# Verifica resultado
Write-Host "`n=== RESULTADO DO ALGORITMO ===" -ForegroundColor Cyan
if (Test-Path "logs/mxOUT.txt") {
    $content = Get-Content "logs/mxOUT.txt" -Raw
    $length = $content.Length
    Write-Host "📄 Arquivo mxOUT.txt criado com $length caracteres" -ForegroundColor Green
    
    if ($length -gt 0) {
        Write-Host "📝 Conteúdo (primeiros 200 caracteres):" -ForegroundColor White
        Write-Host $content.Substring(0, [Math]::Min(200, $length)) -ForegroundColor Yellow
        Write-Host ""
        
        # Verifica o padrão
        $pattern = $content -replace '[\r\n]', ''
        if ($pattern -match '^(\|\.)+$') {
            Write-Host "✅ PADRÃO CORRETO: Apenas sequências de '|.'" -ForegroundColor Green
        } else {
            Write-Host "❌ PADRÃO INCORRETO: Encontrados caracteres diferentes de '|.'" -ForegroundColor Red
        }
        
        # Verifica por "||" (duas entradas consecutivas)
        if ($pattern -match '\|\|') {
            Write-Host "❌ ERRO: Encontradas duas entradas consecutivas '||'" -ForegroundColor Red
        } else {
            Write-Host "✅ SEM ERRO: Não há duas entradas consecutivas" -ForegroundColor Green
        }
        
        # Verifica por ".." (duas saídas consecutivas)
        if ($pattern -match '\.\.') {
            Write-Host "❌ ERRO: Encontradas duas saídas consecutivas '..'" -ForegroundColor Red
        } else {
            Write-Host "✅ SEM ERRO: Não há duas saídas consecutivas" -ForegroundColor Green
        }
        
        # Estatísticas
        $entradas = ($pattern.ToCharArray() | Where-Object { $_ -eq '|' }).Count
        $saidas = ($pattern.ToCharArray() | Where-Object { $_ -eq '.' }).Count
        Write-Host "`n📊 Estatísticas:" -ForegroundColor Cyan
        Write-Host "   Entradas na SC: $entradas" -ForegroundColor Gray
        Write-Host "   Saídas da SC: $saidas" -ForegroundColor Gray
        
        if ($entradas -eq $saidas) {
            Write-Host "✅ BALANCEAMENTO CORRETO: Entradas = Saídas" -ForegroundColor Green
        } else {
            Write-Host "⚠️ DESBALANCEAMENTO: Entradas ≠ Saídas (pode ser normal se processos ainda estão rodando)" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "❌ Arquivo vazio - problema na comunicação ainda persiste" -ForegroundColor Red
        Write-Host "Verifique os logs dos terminais para mais detalhes" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Arquivo não foi criado - problema na inicialização" -ForegroundColor Red
}

Write-Host "`n=== TESTE CONCLUÍDO ===" -ForegroundColor Green
Write-Host "Para parar os processos, feche as janelas dos terminais" -ForegroundColor Gray 
Write-Host "🧪 TESTE RÁPIDO DIMEX CORRIGIDO" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Limpar
taskkill /F /IM dimex_corrigido.exe 2>$null
if (Test-Path "logs/mxOUT.txt") { Remove-Item "logs/mxOUT.txt" -Force }

# Executar processo 0
Write-Host "🚀 Iniciando processo 0..." -ForegroundColor Yellow
Start-Process -FilePath ".\dimex_corrigido.exe" -ArgumentList "0", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Minimized

Start-Sleep -Seconds 2

# Executar processo 1
Write-Host "🚀 Iniciando processo 1..." -ForegroundColor Yellow
Start-Process -FilePath ".\dimex_corrigido.exe" -ArgumentList "1", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Minimized

Start-Sleep -Seconds 2

# Executar processo 2
Write-Host "🚀 Iniciando processo 2..." -ForegroundColor Yellow
Start-Process -FilePath ".\dimex_corrigido.exe" -ArgumentList "2", "127.0.0.1:5000", "127.0.0.1:6001", "127.0.0.1:7002" -WindowStyle Minimized

Write-Host "⏱️  Aguardando 15 segundos..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Verificar resultado
Write-Host "`n📋 RESULTADO:" -ForegroundColor Cyan
if (Test-Path "logs/mxOUT.txt") {
    $content = Get-Content "logs/mxOUT.txt" -Raw
    $length = $content.Length
    Write-Host "📄 Arquivo mxOUT.txt: $length bytes" -ForegroundColor Green
    if ($length -gt 0) {
        Write-Host "✅ CONTEÚDO: $content" -ForegroundColor Green
        if ($content -match "^\|\.(\|\.)*$") {
            Write-Host "🎉 SUCESSO: Padrão correto!" -ForegroundColor Green
        } else {
            Write-Host "❌ PROBLEMA: Padrão incorreto" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ PROBLEMA: Arquivo vazio" -ForegroundColor Red
    }
} else {
    Write-Host "❌ PROBLEMA: Arquivo não encontrado" -ForegroundColor Red
}

# Parar processos
taskkill /F /IM dimex_corrigido.exe
Write-Host "`n🎯 TESTE CONCLUÍDO!" -ForegroundColor Cyan

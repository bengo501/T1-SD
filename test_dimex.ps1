# Script de teste para o projeto DiMeX
# Testa a compilação e execução do algoritmo de exclusão mútua distribuída

Write-Host "=== Teste do Projeto DiMeX ===" -ForegroundColor Green

# Verifica se o Go está instalado
try {
    $goVersion = go version
    Write-Host "✓ Go encontrado: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Go não encontrado. Por favor, instale o Go primeiro." -ForegroundColor Red
    Write-Host "Instruções: https://golang.org/doc/install" -ForegroundColor Yellow
    exit 1
}

# Verifica a estrutura do projeto
Write-Host "`n=== Verificando estrutura do projeto ===" -ForegroundColor Cyan

$requiredFiles = @(
    "go.mod",
    "DIMEX/DIMEX-Template.go",
    "PP2PLink/PP2PLink.go",
    "useDIMEX.go",
    "useDIMEX-f.go"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file (não encontrado)" -ForegroundColor Red
    }
}

# Tenta compilar o projeto
Write-Host "`n=== Testando compilação ===" -ForegroundColor Cyan

try {
    go mod tidy
    Write-Host "✓ go mod tidy executado com sucesso" -ForegroundColor Green
} catch {
    Write-Host "✗ Erro ao executar go mod tidy" -ForegroundColor Red
}

try {
    go build useDIMEX.go
    Write-Host "✓ useDIMEX.go compilado com sucesso" -ForegroundColor Green
    Remove-Item "useDIMEX.exe" -ErrorAction SilentlyContinue
} catch {
    Write-Host "✗ Erro ao compilar useDIMEX.go" -ForegroundColor Red
}

try {
    go build useDIMEX-f.go
    Write-Host "✓ useDIMEX-f.go compilado com sucesso" -ForegroundColor Green
    Remove-Item "useDIMEX-f.exe" -ErrorAction SilentlyContinue
} catch {
    Write-Host "✗ Erro ao compilar useDIMEX-f.go" -ForegroundColor Red
}

Write-Host "`n=== Instruções de Execução ===" -ForegroundColor Cyan
Write-Host "Para testar o algoritmo com 3 processos:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Terminal 1: go run useDIMEX.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -ForegroundColor White
Write-Host "Terminal 2: go run useDIMEX.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -ForegroundColor White
Write-Host "Terminal 3: go run useDIMEX.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -ForegroundColor White
Write-Host ""
Write-Host "Para testar com arquivo compartilhado:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Terminal 1: go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -ForegroundColor White
Write-Host "Terminal 2: go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -ForegroundColor White
Write-Host "Terminal 3: go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002" -ForegroundColor White
Write-Host ""
Write-Host "Após executar, verifique o arquivo mxOUT.txt para confirmar a corretude do algoritmo." -ForegroundColor Yellow

Write-Host "`n=== Teste Concluído ===" -ForegroundColor Green 
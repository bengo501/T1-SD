# Trabalho 1 - Sistemas Distribuídos 2025/2
## Sistema DIMEX - Exclusao Mutua Distribuida

## Descricao
Implementacao do algoritmo de **Exclusao Mutua Distribuida (DiMeX)** em Go, conforme especificacao do Trabalho 1 de Sistemas Distribuidos.

## Estrutura do Projeto
```
T1-SD/
├── DIMEX/                    # Algoritmo DiMeX
│   └── DIMEX-Template.go
├── PP2PLink/                 # Camada de comunicacao
│   └── PP2PLink.go
├── scripts/                  # Scripts de execucao
│   ├── executar_simples.ps1
│   ├── executar_com_monitor.ps1
│   ├── executar_completo.ps1
│   ├── test_final.ps1
│   ├── ver_logs.ps1
│   └── ver_logs_tempo_real.ps1
├── logs/                     # Logs gerados
├── executar.ps1              # Menu principal
├── useDIMEX-f.go             # Aplicacao principal
└── go.mod                    # Dependencias Go
```

## Como Executar

### 1. Menu Principal (Recomendado)
```powershell
.\executar.ps1
```

### 2. Execucao Direta
```powershell
# Execucao simples
.\scripts\executar_simples.ps1

# Teste final com validacao
.\scripts\test_final.ps1
```

## Validacao
O sistema gera o arquivo `logs/mxOUT.txt` com o padrao:
- `|` = Entrada na Secao Critica
- `.` = Saida da Secao Critica
- **Padrao correto**: `|.|.|.|.|.|.`
- **Sem violacoes**: Nao deve conter `||` ou `..`

## Requisitos
- **Go 1.18+**
- **PowerShell 5.0+**
- **Windows 10/11**

## Funcionalidades
- Algoritmo DiMeX implementado
- Comunicacao PP2PLink funcional
- Multiplos processos simultaneos
- Logs detalhados
- Validacao automatica
- Interface amigavel

## Resultado Esperado
Sistema de exclusao mutua distribuida funcionando corretamente, garantindo que apenas um processo acesse a secao critica por vez.

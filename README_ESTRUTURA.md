# Estrutura do Projeto DIMEX

```
T1-SD/
├── scripts/           # Scripts PowerShell
│   ├── executar_simples.ps1
│   ├── executar_com_monitor.ps1
│   ├── ver_logs.ps1
│   └── ver_logs_tempo_real.ps1
├── logs/              # Logs gerados
│   ├── terminal_0.log
│   ├── terminal_1.log
│   ├── terminal_2.log
│   └── mxOUT.txt
├── DIMEX/             # Algoritmo de exclusão mútua
├── PP2PLink/          # Comunicação ponto-a-ponto
├── executar.ps1       # Script principal
├── useDIMEX-f.go      # Programa principal
└── README.md          # Documentação
```

## Como Usar

### Opção 1: Script Principal
```powershell
.\executar.ps1
```
Menu interativo com todas as opções.

### Opção 2: Execução Direta
```powershell
# Executar DIMEX Simples
.\scripts\executar_simples.ps1

# Executar com Monitoramento
.\scripts\executar_com_monitor.ps1

# Visualizar Logs
.\scripts\ver_logs.ps1

# Visualizar Logs em Tempo Real
.\scripts\ver_logs_tempo_real.ps1
```

## Scripts Disponíveis

### Scripts de Execução
- `executar_simples.ps1` - 3 terminais básicos
- `executar_com_monitor.ps1` - 3 terminais + monitoramento

### Scripts de Visualização
- `ver_logs.ps1` - Menu para visualizar logs
- `ver_logs_tempo_real.ps1` - Visualização em tempo real

## Arquivos de Log

Todos os logs são salvos na pasta `logs/`:
- `logs/terminal_0.log` - Log do Processo 0
- `logs/terminal_1.log` - Log do Processo 1
- `logs/terminal_2.log` - Log do Processo 2
- `logs/mxOUT.txt` - Resultado do algoritmo DIMEX

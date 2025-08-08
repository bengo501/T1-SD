# Estrutura Organizada do Projeto DIMEX

```
T1-SD/
├── scripts/           # Todos os scripts PowerShell
│   ├── executar_simples.ps1
│   ├── executar_com_monitor.ps1
│   ├── executar_completo.ps1
│   ├── ver_logs.ps1
│   └── ver_logs_tempo_real.ps1
├── logs/              # Todos os logs gerados
│   ├── terminal_0.log
│   ├── terminal_1.log
│   ├── terminal_2.log
│   └── mxOUT.txt
├── DIMEX/             # Implementação do algoritmo
├── PP2PLink/          # Camada de comunicação
├── executar.ps1          # Script principal (menu)
├── useDIMEX-f.go         # Programa principal
└── README.md             # Documentação original
```

## **Como Usar**

### **Opção 1: Script Principal**
```powershell
.\executar.ps1
```
- Menu interativo com todas as opções
- Facilita a execução dos scripts organizados

### **Opção 2: Execução Direta**
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

## **Scripts Disponíveis**

### **Scripts de Execução**
- **`executar_simples.ps1`** - 3 terminais básicos
- **`executar_com_monitor.ps1`** - 3 terminais + monitoramento
- **`executar_completo.ps1`** - Versão avançada

### **Scripts de Visualização**
- **`ver_logs.ps1`** - Menu interativo para visualizar logs
- **`ver_logs_tempo_real.ps1`** - Visualização em tempo real

## **Arquivos de Log**

Todos os logs são salvos na pasta `logs/`:
- `logs/terminal_0.log` - Log do Processo 0
- `logs/terminal_1.log` - Log do Processo 1
- `logs/terminal_2.log` - Log do Processo 2
- `logs/mxOUT.txt` - Resultado do algoritmo DIMEX

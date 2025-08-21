# Sistema DIMEX + Snapshot (Chandy-Lamport)

Implementação do algoritmo de Exclusão Mútua Distribuída (Ricart/Agrawalla) com funcionalidade de Snapshot (Chandy-Lamport) em Go.

## Estrutura do Projeto

```
T1-SD/
├── src/                          # Código fonte
│   ├── DIMEX/                    # Módulo de exclusão mútua
│   ├── PP2PLink/                 # Módulo de comunicação
│   ├── falhas/                   # Versões com falhas para teste
│   ├── useDIMEX-f.go            # Aplicação principal (com snapshot)
│   ├── useDIMEX-puro.go         # Aplicação sem snapshot
│   └── snapshot_analyzer.go     # Analisador de invariantes
├── bin/                          # Executáveis compilados
├── scripts/                      # Scripts de execução básicos
├── tests/                        # Scripts de teste e demonstração
├── logs/                         # Logs e snapshots gerados
├── docs/                         # Documentação
└── executar.ps1                  # Script principal com menu
```

## Como Usar

### Execução Principal
```powershell
.\executar.ps1
```

O menu oferece as seguintes opções:
1. **Executar com 3 Terminais** - DIMEX básico
2. **Executar com 4 Terminais** - DIMEX + Monitor em tempo real
3. **Executar com Snapshot** - DIMEX + Funcionalidade de Snapshot
4. **Testar Falha 1** - Violação de exclusão mútua
5. **Testar Falha 2** - Deadlock
6. **Demonstração Completa** - Todas as etapas do enunciado
7. **Sair**

### Execução Direta
```powershell
# Compilar
go build -o bin/dimex_test.exe src/useDIMEX-f.go
go build -o bin/snapshot_analyzer.exe src/snapshot_analyzer.go

# Executar 3 processos
.\bin\dimex_test.exe 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
.\bin\dimex_test.exe 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
.\bin\dimex_test.exe 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

## Funcionalidades

### Parte 1 - Exclusão Mútua Distribuída
- ✅ Algoritmo Ricart/Agrawalla
- ✅ Relógios Lógicos de Lamport
- ✅ Propriedades DMX1 e DMX2
- ✅ Comunicação via PP2PLink

### Parte 2 - Snapshot (Chandy-Lamport)
- ✅ Identificadores únicos para snapshots
- ✅ Gravação de estado local e canais
- ✅ Algoritmo de marcadores
- ✅ Análise de invariantes

### Análise de Invariantes
- **Inv1**: Máximo um processo na SC
- **Inv2**: Estados consistentes quando não querem SC
- **Inv3**: Relação waiting ↔ estado
- **Inv4**: Contagem de mensagens
- **Inv5**: Detecção de falhas

## Arquivos Importantes

- `src/DIMEX/DIMEX-Template.go` - Implementação principal do algoritmo
- `src/PP2PLink/PP2PLink.go` - Comunicação ponto-a-ponto
- `src/snapshot_analyzer.go` - Analisador de invariantes
- `logs/mxOUT.txt` - Resultado da exclusão mútua
- `logs/snapshot_*.json` - Estados dos snapshots

## Requisitos

- Go 1.21+
- PowerShell (Windows)
- Portas 5000-7002 disponíveis

## Desenvolvimento

Este projeto foi desenvolvido como parte da disciplina de Sistemas Distribuídos, implementando os algoritmos de Ricart/Agrawalla para exclusão mútua distribuída e Chandy-Lamport para snapshots distribuídos. 
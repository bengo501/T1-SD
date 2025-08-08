# Instruções - DIMEX com 3 Terminais

## Problema Resolvido
O erro de **concurrent map writes** foi corrigido com sucesso! O sistema agora funciona com múltiplos processos simultâneos.


### Opção 1: Script Simples (3 Terminais)
```powershell
.\executar_simples.ps1
```
- Abre 3 terminais com formatação melhorada
- Títulos nos terminais identificando cada processo
- Logs salvos automaticamente

### Opção 2: Script com Monitoramento (4 Terminais)
```powershell
.\executar_com_monitor.ps1
```
- Abre 3 terminais para os processos
- **+ 1 terminal de monitoramento** mostrando mxOUT.txt em tempo real
- Validação automática do padrão
- Estatísticas em tempo real

### Opção 3: Manual (3 Terminais Separados)

**Terminal 1:**
```powershell
cd "C:\Users\joxto\Downloads\T1-SD"
go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

**Terminal 2:**
```powershell
cd "C:\Users\joxto\Downloads\T1-SD"
go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

**Terminal 3:**
```powershell
cd "C:\Users\joxto\Downloads\T1-SD"
go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

## Resultado Esperado

- Arquivo `mxOUT.txt` será criado automaticamente
- Conteúdo deve ser: `|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.`
- **NUNCA** deve haver `||` ou `..` (indicaria falha na exclusão mútua)

## Como Verificar

### Verificar o Arquivo:
```powershell
Get-Content mxOUT.txt
```

### Monitorar em Tempo Real:
```powershell
Get-Content mxOUT.txt -Wait -Tail 10
```

### Visualizar Logs:
```powershell
.\ver_logs.ps1
```

## Para Parar
Pressione **Ctrl+C** em cada terminal.

## Arquivos Principais
- `PP2PLink/PP2PLink.go` - Corrigido com mutex
- `DIMEX/DIMEX-Template.go` - Algoritmo de exclusão mútua
- `useDIMEX-f.go` - Programa principal
- `executar_simples.ps1` - Script básico
- `executar_com_monitor.ps1` - Script com monitoramento 
- `ver_logs.ps1` - Visualizador de log


### Melhorias Implementadas:
- **Títulos nos terminais** - Identificação clara de cada processo
- **Formatação melhorada** - Logs mais organizados e legíveis
- **Terminal de monitoramento** - Visualização em tempo real do mxOUT.txt
- **Validação automática** - Verificação do padrão correto
- **Estatísticas em tempo real** - Tamanho do arquivo e status

### Terminal de Monitoramento:
- Mostra conteúdo do mxOUT.txt em tempo real
- Valida automaticamente se o padrão está correto
- Exibe estatísticas (tamanho, status)
- Atualização a cada segundo


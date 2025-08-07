# 📁 Sistema de Logs DIMEX

## ✅ Funcionalidade Implementada

O sistema agora salva o log de cada terminal em arquivos separados, permitindo análise detalhada do comportamento de cada processo.

## 🚀 Scripts Disponíveis

### 1. `executar_3_terminais.ps1` - Script Completo
- Abre 3 terminais com identificação colorida
- Remove logs anteriores automaticamente
- Salva logs em arquivos separados
- Mostra instruções detalhadas

### 2. `executar_simples.ps1` - Script Simples
- Versão mais direta e rápida
- Remove logs anteriores
- Salva logs automaticamente

### 3. `ver_logs.ps1` - Visualizador de Logs
- Menu interativo para visualizar logs
- Opções para ver logs individuais ou todos
- Monitoramento em tempo real

## 📁 Arquivos de Log Gerados

### Logs dos Terminais:
- **`terminal_0.log`** - Log do Processo 0 (ID: 0)
- **`terminal_1.log`** - Log do Processo 1 (ID: 1)  
- **`terminal_2.log`** - Log do Processo 2 (ID: 2)

### Log do Algoritmo:
- **`mxOUT.txt`** - Resultado do algoritmo de exclusão mútua

## 🔍 Como Usar

### Executar com Logs:
```powershell
# Script completo
.\executar_3_terminais.ps1

# Script simples
.\executar_simples.ps1
```

### Visualizar Logs:
```powershell
.\ver_logs.ps1
```

### Verificar Logs Manualmente:
```powershell
# Ver resultado do algoritmo
Get-Content mxOUT.txt

# Ver log do processo 0
Get-Content terminal_0.log

# Ver log do processo 1
Get-Content terminal_1.log

# Ver log do processo 2
Get-Content terminal_2.log

# Monitorar em tempo real
Get-Content mxOUT.txt -Wait -Tail 10
```

## 📊 Conteúdo dos Logs

### Logs dos Terminais (`terminal_X.log`):
- Mensagens de inicialização
- Debug do módulo DIMEX
- Comunicação entre processos
- Erros e avisos
- Comportamento do algoritmo

### Log do Algoritmo (`mxOUT.txt`):
- Padrão `|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.
- **NUNCA** deve conter `||` ou `..`
- Indica se a exclusão mútua está funcionando

## ✅ Vantagens do Sistema de Logs

1. **Análise Individual**: Cada processo tem seu log separado
2. **Debug Facilitado**: Identificação rápida de problemas
3. **Monitoramento**: Acompanhamento em tempo real
4. **Documentação**: Registro completo da execução
5. **Validação**: Verificação da corretude do algoritmo

## 🎯 Validação do Algoritmo

### Padrão Correto:
```
|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.
```

### Padrões Incorretos (indicam falha):
```
|| (duas entradas consecutivas)
.. (duas saídas consecutivas)
|.|.||.|. (entrelaçamento)
```

## 📈 Exemplo de Uso

1. **Execute o script**: `.\executar_simples.ps1`
2. **Aguarde alguns segundos** para os processos inicializarem
3. **Verifique os logs**: `.\ver_logs.ps1`
4. **Monitore o resultado**: `Get-Content mxOUT.txt -Wait`
5. **Pare os processos**: Ctrl+C em cada terminal

**🎉 Sistema de logs funcionando perfeitamente!**

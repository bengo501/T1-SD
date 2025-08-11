# 🧪 Scripts de Teste DIMEX

Este documento descreve os diferentes scripts de teste disponíveis para o algoritmo DIMEX.

## 📋 Scripts Disponíveis

### 1. `teste_corrigido.ps1`
**Descrição**: Teste básico que executa por 10 segundos
- ✅ Compila o projeto
- ✅ Inicia 3 processos DIMEX
- ✅ Aguarda 10 segundos
- ✅ Mostra estatísticas finais
- ✅ Para automaticamente

**Uso**: `.\teste_corrigido.ps1`

### 2. `teste_interativo.ps1`
**Descrição**: Teste interativo com monitoramento em tempo real
- ✅ Compila o projeto
- ✅ Inicia 3 processos DIMEX
- ✅ Abre terminal de monitoramento do mxOUT.txt
- ✅ Roda até Ctrl+C
- ✅ Mostra estatísticas finais

**Uso**: `.\teste_interativo.ps1`

### 3. `teste_interativo_avancado.ps1`
**Descrição**: Teste avançado com estatísticas detalhadas
- ✅ Compila o projeto
- ✅ Inicia 3 processos DIMEX
- ✅ Abre terminal de monitoramento avançado
- ✅ Calcula taxa de escrita em tempo real
- ✅ Mostra estatísticas detalhadas
- ✅ Roda até Ctrl+C

**Uso**: `.\teste_interativo_avancado.ps1`

## 🎯 Como Usar

1. **Teste Rápido**: Use `teste_corrigido.ps1` para verificar se tudo funciona
2. **Teste Interativo**: Use `teste_interativo.ps1` para monitoramento básico
3. **Teste Avançado**: Use `teste_interativo_avancado.ps1` para análise detalhada

## 📊 O que Monitorar

### ✅ Padrão Correto
O arquivo `mxOUT.txt` deve conter apenas o padrão: `|.|.|.|.|.`

### ❌ Padrões Incorretos
- `||..` (dois pipes seguidos)
- `..||` (dois pontos seguidos)
- Qualquer outro padrão

### 📈 Estatísticas Importantes
- **Tamanho do arquivo**: Deve crescer continuamente
- **Taxa de escrita**: Caracteres por segundo
- **Acessos à SC**: Número de `|.` no arquivo
- **Padrão**: Deve ser sempre correto

## 🛑 Como Parar

- **Teste básico**: Para automaticamente após 10 segundos
- **Testes interativos**: Pressione `Ctrl+C` no terminal principal

## 📁 Arquivos Gerados

- `logs/mxOUT.txt`: Arquivo de saída do algoritmo
- `logs/terminal_X.log`: Logs dos processos (se aplicável)
- `dimex_test.exe`: Executável compilado

## 🎉 Resultado Esperado

Quando o algoritmo está funcionando corretamente:
- ✅ Padrão correto no mxOUT.txt
- ✅ Todos os 3 processos rodando
- ✅ Taxa de escrita constante
- ✅ Sem deadlocks ou erros

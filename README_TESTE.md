# 🧪 Guia de Teste - Algoritmo de Exclusão Mútua Distribuída

## 📋 Visão Geral

Este guia explica passo a passo como testar a implementação do algoritmo de exclusão mútua distribuída (DiMeX). O teste verifica se o algoritmo garante que apenas um processo por vez possa acessar a seção crítica.

## 🎯 Objetivo dos Testes

Verificar se o algoritmo implementado garante:
- ✅ **Exclusão Mútua**: Nunca dois processos na SC simultaneamente
- ✅ **Liveness**: Processos que querem entrar na SC eventualmente conseguem
- ✅ **Fairness**: Processos com timestamps menores têm prioridade

## 📋 Pré-requisitos

### **1. Instalação do Go**
```bash
# Verificar se o Go está instalado
go version

# Se não estiver instalado, baixe em: https://golang.org/doc/install
```

### **2. Estrutura do Projeto**
Certifique-se de que o projeto está organizado assim:
```
T1-SD/
├── DIMEX/
│   └── DIMEX-Template.go
├── PP2PLink/
│   └── PP2PLink.go
├── useDIMEX.go
├── useDIMEX-f.go
├── go.mod
└── README.md
```

## 🚀 Passo a Passo para Testar

### **Passo 1: Preparação do Ambiente**

1. **Abra 3 terminais diferentes** (PowerShell, CMD, ou terminal do seu IDE)
2. **Navegue para o diretório do projeto** em todos os terminais:
```bash
cd F:\TrabFacul\T1-SD
```

### **Passo 2: Compilação e Verificação**

1. **Verifique se o projeto compila**:
```bash
go mod tidy
go build useDIMEX-f.go
```

2. **Se houver erros**, verifique:
   - Go está instalado corretamente
   - Todos os arquivos estão no lugar certo
   - `go.mod` está configurado

### **Passo 3: Execução dos Processos**

**IMPORTANTE**: Execute os comandos em **terminais separados** e **simultaneamente**.

#### **Terminal 1 - Processo 0:**
```bash
go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

#### **Terminal 2 - Processo 1:**
```bash
go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

#### **Terminal 3 - Processo 2:**
```bash
go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

### **Passo 4: Observação do Comportamento**

#### **O que você deve ver nos terminais:**

```
[ APP id: 0 PEDE   MX ]
[ APP id: 0 *EM*   MX ]
[ APP id: 0 FORA   MX ]
[ APP id: 0 PEDE   MX ]
...

[ APP id: 1 PEDE   MX ]
[ APP id: 1 *EM*   MX ]
[ APP id: 1 FORA   MX ]
...

[ APP id: 2 PEDE   MX ]
[ APP id: 2 *EM*   MX ]
[ APP id: 2 FORA   MX ]
...
```

#### **Comportamento Esperado:**
- ✅ Processos pedem acesso à SC (`PEDE MX`)
- ✅ Processos entram na SC (`*EM* MX`)
- ✅ Processos saem da SC (`FORA MX`)
- ✅ **NUNCA** dois processos devem estar `*EM* MX` ao mesmo tempo

### **Passo 5: Verificação do Arquivo de Log**

1. **Aguarde alguns segundos** para que os processos gerem logs
2. **Verifique o arquivo `mxOUT.txt`** que será criado no diretório:
```bash
# No Windows (PowerShell)
Get-Content mxOUT.txt

# Ou abra o arquivo em um editor de texto
notepad mxOUT.txt
```

#### **Conteúdo Esperado do Arquivo:**
```
|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.
|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.
|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.
...
```

### **Passo 6: Verificação da Corretude**

#### **Teste 1: Verificar Padrão Correto**
```bash
# Procurar por padrões INCORRETOS (deve retornar 0 ocorrências)
findstr "||" mxOUT.txt
findstr ".." mxOUT.txt

# No PowerShell:
Select-String "||" mxOUT.txt
Select-String ".." mxOUT.txt
```

#### **Teste 2: Contar Entradas e Saídas**
```bash
# Contar quantos "|" (entradas) e "." (saídas)
findstr /c:"|" mxOUT.txt | find /c /v ""
findstr /c:"." mxOUT.txt | find /c /v ""

# No PowerShell:
(Get-Content mxOUT.txt -Raw | Select-String "|" -AllMatches).Matches.Count
(Get-Content mxOUT.txt -Raw | Select-String "\." -AllMatches).Matches.Count
```

**Resultado Esperado**: Número de `|` deve ser igual ao número de `.`

## 🔍 Análise dos Resultados

### **✅ Teste Passou Se:**
- Arquivo `mxOUT.txt` contém apenas sequências `|.`
- Nenhuma ocorrência de `||` ou `..`
- Número de entradas (`|`) = número de saídas (`.`)
- Nos terminais, nunca dois processos estão `*EM* MX` simultaneamente

### **❌ Teste Falhou Se:**
- Arquivo contém `||` (duas entradas consecutivas)
- Arquivo contém `..` (duas saídas consecutivas)
- Número de entradas ≠ número de saídas
- Dois processos aparecem `*EM* MX` ao mesmo tempo

## 🐛 Solução de Problemas

### **Problema 1: "Address already in use"**
```bash
# Solução: Aguarde alguns segundos ou mude as portas
go run useDIMEX-f.go 0 127.0.0.1:5001 127.0.0.1:6002 127.0.0.1:7003
go run useDIMEX-f.go 1 127.0.0.1:5001 127.0.0.1:6002 127.0.0.1:7003
go run useDIMEX-f.go 2 127.0.0.1:5001 127.0.0.1:6002 127.0.0.1:7003
```

### **Problema 2: "go: command not found"**
```bash
# Instale o Go: https://golang.org/doc/install
# Ou adicione ao PATH do sistema
```

### **Problema 3: Erros de compilação**
```bash
# Verifique se todos os arquivos estão presentes
dir DIMEX
dir PP2PLink
dir *.go

# Execute go mod tidy
go mod tidy
```

### **Problema 4: Arquivo mxOUT.txt não é criado**
- Verifique se os processos estão rodando
- Aguarde alguns segundos
- Verifique permissões de escrita no diretório

## 📊 Testes Adicionais

### **Teste com Mais Processos (4 processos):**
```bash
# Terminal 1
go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 127.0.0.1:8003

# Terminal 2
go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 127.0.0.1:8003

# Terminal 3
go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 127.0.0.1:8003

# Terminal 4
go run useDIMEX-f.go 3 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002 127.0.0.1:8003
```

### **Teste de Stress (Executar por mais tempo):**
```bash
# Deixe rodando por 5-10 minutos
# Verifique se o padrão permanece correto
```

## 📈 Interpretação dos Resultados

### **Logs de Debug (se dbg=true):**
```
. . . . . . . . . . . . [ DIMEX : app pede mx ]
. . . . . . . . . . . . [ DIMEX :     ---->>>>   to: 127.0.0.1:6001     msg: reqEntry ]
. . . . . . . . . . . . [ DIMEX :     ---->>>>   to: 127.0.0.1:7002     msg: reqEntry ]
. . . . . . . . . . . . [ DIMEX :          <<<---- pede??  reqEntry ]
. . . . . . . . . . . . [ DIMEX :         <<<---- responde! respOK ]
```

### **Significado dos Logs:**
- `app pede mx`: Processo solicitou entrada na SC
- `---->>>>`: Enviando mensagem para outro processo
- `<<<----`: Recebendo mensagem de outro processo
- `reqEntry`: Requisição de entrada na SC
- `respOK`: Resposta permitindo entrada na SC

## 🎯 Critérios de Sucesso

### **✅ Teste Passou Completamente Se:**
1. **Exclusão Mútua**: Nunca dois processos na SC simultaneamente
2. **Liveness**: Todos os processos conseguem entrar na SC
3. **Fairness**: Processos com timestamps menores têm prioridade
4. **Arquivo Correto**: `mxOUT.txt` com padrão `|.|.|.|.`
5. **Logs Consistentes**: Mensagens de debug fazem sentido

### **📊 Métricas de Qualidade:**
- **Tempo de resposta**: Quanto tempo leva para entrar na SC
- **Throughput**: Quantas entradas/saídas por segundo
- **Fairness**: Distribuição justa de acesso entre processos

## 🔄 Repetindo os Testes

Para garantir robustez, execute os testes múltiplas vezes:

```bash
# Limpe o arquivo anterior
del mxOUT.txt

# Execute novamente os 3 processos
# Verifique os resultados
# Repita 3-5 vezes para confirmar consistência
```

## 📝 Relatório de Teste

Após executar os testes, documente:

1. **Data e hora** do teste
2. **Número de processos** testados
3. **Tempo de execução** total
4. **Resultado do arquivo** `mxOUT.txt`
5. **Problemas encontrados** (se houver)
6. **Conclusão**: ✅ Passou ou ❌ Falhou

---

**🎉 Parabéns!** Se todos os testes passaram, sua implementação do algoritmo de exclusão mútua distribuída está funcionando corretamente! 
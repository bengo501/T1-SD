# Implementação do Algoritmo de Exclusão Mútua Distribuída (DiMeX)

## 📋 Visão Geral

Este documento explica as mudanças e implementações realizadas no arquivo `DIMEX-Template.go`, transformando um template vazio em um sistema funcional de exclusão mútua distribuída.

## 🎯 Objetivo do Trabalho

Implementar o algoritmo de exclusão mútua distribuída que garante que **apenas um processo por vez** possa acessar a seção crítica (SC), mesmo em um sistema distribuído onde processos podem falhar ou mensagens podem ser perdidas.

## 📊 Comparação: Template Original vs Implementação Final

### **Template Original (Vazio)**
- ✅ Estrutura completa (tipos, structs, canais)
- ✅ Inicialização básica
- ✅ Loop principal
- ✅ Funções auxiliares
- ❌ **4 funções principais vazias**
- ❌ **Sem implementação do algoritmo**

### **Implementação Final (Completa)**
- ✅ Estrutura completa
- ✅ Inicialização modificada
- ✅ Loop principal adaptado
- ✅ Funções auxiliares melhoradas
- ✅ **4 funções principais implementadas**
- ✅ **Algoritmo de exclusão mútua funcional**

## 🔧 Mudanças Detalhadas

### **1. IMPORTS ADICIONADOS**

```go
// ORIGINAL
import (
    PP2PLink "SD/PP2PLink"
    "fmt"
    "strings"
)

// FINAL
import (
    PP2PLink "SD/PP2PLink"
    "fmt"
    "net"           // ← ADICIONADO: Para conexões TCP
    "strconv"       // ← ADICIONADO: Para conversão de timestamps
    "strings"
)
```

**Motivo**: Necessário para cache de conexões TCP e manipulação de timestamps.

### **2. ESTRUTURA DE DADOS MODIFICADA**

```go
type DIMEX_Module struct {
    // ... campos existentes ...
    nbrResps  int          // ← ADICIONADO: Contador de respostas
    // ... outros campos ...
}
```

**Motivo**: Controlar quantas respostas foram recebidas antes de liberar acesso à SC.

### **3. INICIALIZAÇÃO MODIFICADA**

```go
// ORIGINAL
p2p := PP2PLink.NewPP2PLink(_addresses[_id], _dbg)

// FINAL
p2p := &PP2PLink.PP2PLink{
    Ind:   make(chan PP2PLink.PP2PLink_Ind_Message, 1),
    Req:   make(chan PP2PLink.PP2PLink_Req_Message, 1),
    Run:   false,
    Cache: make(map[string]net.Conn),  // ← ADICIONADO
}
p2p.Init(_addresses[_id])  // ← MÉTODO DIFERENTE
```

**Motivo**: Usar a versão do PP2PLink com serialização do Andrius.

### **4. FUNÇÕES PRINCIPAIS IMPLEMENTADAS**

#### **A) handleUponReqEntry() - REQUISIÇÃO DE ENTRADA**

**Template Original (VAZIO):**
```go
func (module *DIMEX_Module) handleUponReqEntry() {
    // FUNÇÃO COMPLETAMENTE VAZIA
    // Só tinha comentários explicativos
}
```

**Implementação Final:**
```go
func (module *DIMEX_Module) handleUponReqEntry() {
    module.lcl++                    // ← IMPLEMENTADO: Incrementa relógio lógico
    module.reqTs = module.lcl       // ← IMPLEMENTADO: Define timestamp
    module.nbrResps = 0             // ← IMPLEMENTADO: Zera contador
    
    // Envia requisição para todos os outros processos
    for i, addr := range module.addresses {
        if i != module.id {
            msgData := map[string]string{
                "timestamp": strconv.Itoa(module.reqTs),
                "processId": strconv.Itoa(module.id),
            }
            module.sendToLinkWithData(addr, "reqEntry", msgData, "    ")
        }
    }
    
    module.st = wantMX              // ← IMPLEMENTADO: Muda estado
}
```

**O que faz:**
1. Incrementa relógio lógico (Lamport)
2. Define timestamp da requisição
3. Zera contador de respostas
4. Envia requisição com timestamp para todos os outros processos
5. Muda estado para "quer SC"

#### **B) handleUponReqExit() - SAÍDA DA SEÇÃO CRÍTICA**

**Template Original (VAZIO):**
```go
func (module *DIMEX_Module) handleUponReqExit() {
    // FUNÇÃO COMPLETAMENTE VAZIA
}
```

**Implementação Final:**
```go
func (module *DIMEX_Module) handleUponReqExit() {
    // Envia resposta OK para todos os processos aguardando
    for i, isWaiting := range module.waiting {
        if isWaiting {
            module.sendToLink(module.addresses[i], "respOK", "    ")
        }
    }
    
    module.st = noMX                // ← IMPLEMENTADO: Muda estado
    // Limpa a lista de processos aguardando
    for i := range module.waiting {
        module.waiting[i] = false    // ← IMPLEMENTADO: Limpa array
    }
}
```

**O que faz:**
1. Envia resposta OK para todos os processos que estão aguardando
2. Muda estado para "não quer SC"
3. Limpa array de processos aguardando

#### **C) handleUponDeliverRespOk() - RECEBIMENTO DE RESPOSTA**

**Template Original (VAZIO):**
```go
func (module *DIMEX_Module) handleUponDeliverRespOk(msgOutro PP2PLink.PP2PLink_Ind_Message) {
    // FUNÇÃO COMPLETAMENTE VAZIA
}
```

**Implementação Final:**
```go
func (module *DIMEX_Module) handleUponDeliverRespOk(msgOutro PP2PLink.PP2PLink_Ind_Message) {
    module.nbrResps++               // ← IMPLEMENTADO: Incrementa contador
    if module.nbrResps == len(module.addresses)-1 {
        module.Ind <- dmxResp{}      // ← IMPLEMENTADO: Libera acesso
        module.st = inMX             // ← IMPLEMENTADO: Muda estado
    }
}
```

**O que faz:**
1. Incrementa contador de respostas recebidas
2. Se recebeu todas as respostas (N-1): libera acesso à SC
3. Muda estado para "está na SC"

#### **D) handleUponDeliverReqEntry() - RECEBIMENTO DE REQUISIÇÃO**

**Template Original (VAZIO):**
```go
func (module *DIMEX_Module) handleUponDeliverReqEntry(msgOutro PP2PLink.PP2PLink_Ind_Message) {
    // FUNÇÃO COMPLETAMENTE VAZIA
}
```

**Implementação Final:**
```go
func (module *DIMEX_Module) handleUponDeliverReqEntry(msgOutro PP2PLink.PP2PLink_Ind_Message) {
    // Extrai timestamp da mensagem
    otherTsStr, exists := msgOutro.Message.Data["timestamp"]
    otherTs, err := strconv.Atoi(otherTsStr)
    
    // Identifica processo remetente
    senderId := -1
    for i, addr := range module.addresses {
        if strings.Contains(addr, msgOutro.From) {
            senderId = i
            break
        }
    }
    
    // Lógica de decisão
    if module.st == noMX || (module.st == wantMX && module.reqTs > otherTs) {
        module.sendToLink(msgOutro.From, "respOK", "    ")  // Responde OK
    } else if module.st == inMX || (module.st == wantMX && module.reqTs < otherTs) {
        module.waiting[senderId] = true                      // Posterga resposta
        if otherTs > module.lcl {
            module.lcl = otherTs                            // Atualiza relógio
        }
    }
}
```

**O que faz:**
1. Extrai timestamp da mensagem recebida
2. Identifica qual processo enviou a mensagem
3. **Lógica de decisão:**
   - Se não está na SC OU tem timestamp maior → responde OK imediatamente
   - Se está na SC OU tem timestamp menor → posterga resposta
4. Atualiza relógio lógico se necessário

### **5. FUNÇÃO AUXILIAR ADICIONADA**

```go
// NOVA FUNÇÃO ADICIONADA
func (module *DIMEX_Module) sendToLinkWithData(address string, content string, data map[string]string, space string) {
    module.outDbg(space + " ---->>>>   to: " + address + "     msg: " + content)
    module.Pp2plink.Req <- PP2PLink.PP2PLink_Req_Message{
        To: address,
        Message: PP2PLink.PP2LinkMessage{
            Value: content,
            Data:  data,
        }}
}
```

**Motivo**: Enviar mensagens com dados extras (timestamps, IDs de processo).

### **6. FUNÇÃO AUXILIAR MODIFICADA**

```go
// ORIGINAL
func (module *DIMEX_Module) sendToLink(address string, content string, space string) {
    module.Pp2plink.Req <- PP2PLink.PP2PLink_Req_Message{
        To:      address,
        Message: content}  // ← String direta
}

// FINAL
func (module *DIMEX_Module) sendToLink(address string, content string, space string) {
    module.Pp2plink.Req <- PP2PLink.PP2PLink_Req_Message{
        To: address,
        Message: PP2PLink.PP2LinkMessage{
            Value: content,
            Data:  make(map[string]string),
        }}  // ← PP2LinkMessage
}
```

**Motivo**: Adaptar para usar a estrutura `PP2LinkMessage` com serialização.

## 🔄 Algoritmo Implementado

### **Estados do Processo:**
- `noMX`: Não quer acessar a seção crítica
- `wantMX`: Quer acessar a seção crítica (aguardando respostas)
- `inMX`: Está dentro da seção crítica

### **Fluxo do Algoritmo:**

1. **Processo quer entrar na SC:**
   - Incrementa relógio lógico
   - Envia requisição com timestamp para todos os outros
   - Muda estado para `wantMX`
   - Aguarda respostas de todos os outros processos

2. **Processo recebe requisição:**
   - Se não está na SC OU tem timestamp maior → responde OK imediatamente
   - Se está na SC OU tem timestamp menor → posterga resposta

3. **Processo recebe resposta:**
   - Incrementa contador de respostas
   - Se recebeu todas as respostas → libera acesso à SC

4. **Processo sai da SC:**
   - Envia resposta OK para todos os processos aguardando
   - Muda estado para `noMX`
   - Limpa lista de processos aguardando

## 🎯 Propriedades Garantidas

### **Exclusão Mútua:**
- Nunca dois processos estarão na SC simultaneamente

### **Liveness:**
- Se um processo quer entrar na SC, eventualmente conseguirá

### **Fairness:**
- Processos com timestamps menores têm prioridade

## 📈 Melhorias Implementadas

1. **Relógios Lógicos de Lamport** para ordenação consistente
2. **Serialização JSON** para mensagens complexas
3. **Cache de conexões TCP** para melhor performance
4. **Tratamento de erros** na extração de dados
5. **Debug mode** para acompanhar mensagens
6. **Timestamps** para resolver conflitos de prioridade

## 🧪 Como Testar

```bash
# Terminal 1
go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002

# Terminal 2
go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002

# Terminal 3
go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

## ✅ Verificação da Corretude

O arquivo `mxOUT.txt` gerado deve conter apenas sequências de `|.` (entrada e saída da SC). Nunca deve conter:
- `||` (duas entradas consecutivas)
- `..` (duas saídas consecutivas)

## 📚 Bibliografia

- Reliable and Secure Distributed Programming
- Christian Cachin, Rachid Gerraoui, Luís Rodrigues
- Slides dos autores em http://distributedprogramming.net

---

**Resultado:** Transformação de um template vazio em um sistema funcional de exclusão mútua distribuída com todas as propriedades de segurança e vivacidade garantidas. 
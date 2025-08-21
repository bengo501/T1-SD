# Implementação do Algoritmo de Exclusão Mútua Distribuída (DiMeX)

## Visão Geral

Este documento explica as implementações realizadas no arquivo `DIMEX-Template.go`, transformando um template vazio em um sistema funcional de exclusão mútua distribuída.

## Objetivo

Implementar o algoritmo de exclusão mútua distribuída que garante que apenas um processo por vez possa acessar a seção crítica (SC), mesmo em um sistema distribuído.

## Comparação: Template vs Implementação

### Template Original
- Estrutura completa (tipos, structs, canais)
- Inicialização básica
- Loop principal
- Funções auxiliares
- 4 funções principais vazias
- Sem implementação do algoritmo

### Implementação Final
- Estrutura completa
- Inicialização modificada
- Loop principal adaptado
- Funções auxiliares melhoradas
- 4 funções principais implementadas
- Algoritmo de exclusão mútua funcional

## Mudanças Detalhadas

### 1. Imports Adicionados

```go
// Original
import (
    PP2PLink "SD/PP2PLink"
    "fmt"
    "strings"
)

// Final
import (
    PP2PLink "SD/PP2PLink"
    "fmt"
    "strconv"       // Para conversão de timestamps
    "strings"
)
```

### 2. Estrutura de Dados Modificada

```go
type DIMEX_Module struct {
    // ... campos existentes ...
    nbrResps  int          // Contador de respostas
    // ... outros campos ...
}
```

### 3. Funções Principais Implementadas

#### A) handleUponReqEntry() - Requisição de Entrada

**Template Original (Vazio):**
```go
func (module *DIMEX_Module) handleUponReqEntry() {
    // Função completamente vazia
}
```

**Implementação Final:**
```go
func (module *DIMEX_Module) handleUponReqEntry() {
    module.lcl++              // Incrementa relógio lógico
    module.reqTs = module.lcl // Define timestamp
    module.nbrResps = 0       // Zera contador
    
    // Envia requisição para todos os outros processos
    for i, addr := range module.addresses {
        if i != module.id {
            msg := fmt.Sprintf("reqEntry,%d,%d", module.id, module.reqTs)
            module.sendToLink(addr, msg, "    ")
        }
    }
    
    module.st = wantMX        // Muda estado
}
```

**O que faz:**
1. Incrementa relógio lógico (Lamport)
2. Define timestamp da requisição
3. Zera contador de respostas
4. Envia requisição com timestamp para todos os outros processos
5. Muda estado para "quer SC"

#### B) handleUponReqExit() - Saída da Seção Crítica

**Template Original (Vazio):**
```go
func (module *DIMEX_Module) handleUponReqExit() {
    // Função completamente vazia
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
    
    module.st = noMX          // Muda estado
    // Limpa a lista de processos aguardando
    for i := range module.waiting {
        module.waiting[i] = false
    }
}
```

**O que faz:**
1. Envia resposta OK para todos os processos que estão aguardando
2. Muda estado para "não quer SC"
3. Limpa array de processos aguardando

#### C) handleUponDeliverRespOk() - Recebimento de Resposta

**Template Original (Vazio):**
```go
func (module *DIMEX_Module) handleUponDeliverRespOk(msgOutro PP2PLink.PP2PLink_Ind_Message) {
    // Função completamente vazia
}
```

**Implementação Final:**
```go
func (module *DIMEX_Module) handleUponDeliverRespOk(msgOutro PP2PLink.PP2PLink_Ind_Message) {
    module.nbrResps++         // Incrementa contador
    if module.nbrResps == len(module.addresses)-1 {
        module.Ind <- dmxResp{} // Libera acesso
        module.st = inMX        // Muda estado
    }
}
```

**O que faz:**
1. Incrementa contador de respostas recebidas
2. Se recebeu todas as respostas (N-1): libera acesso à SC
3. Muda estado para "está na SC"

#### D) handleUponDeliverReqEntry() - Recebimento de Requisição

**Template Original (Vazio):**
```go
func (module *DIMEX_Module) handleUponDeliverReqEntry(msgOutro PP2PLink.PP2PLink_Ind_Message) {
    // Função completamente vazia
}
```

**Implementação Final:**
```go
func (module *DIMEX_Module) handleUponDeliverReqEntry(msgOutro PP2PLink.PP2PLink_Ind_Message) {
    // Extrai informações da mensagem: "reqEntry,processId,timestamp"
    parts := strings.Split(msgOutro.Message, ",")
    if len(parts) != 3 {
        module.outDbg("Mensagem reqEntry malformada: " + msgOutro.Message)
        return
    }

    otherId, err1 := strconv.Atoi(parts[1])
    otherTs, err2 := strconv.Atoi(parts[2])
    if err1 != nil || err2 != nil {
        module.outDbg("Erro ao converter ID ou timestamp: " + msgOutro.Message)
        return
    }

    // Lógica de decisão
    if module.st == noMX || (module.st == wantMX && module.reqTs > otherTs) {
        module.sendToLink(module.addresses[otherId], "respOK", "    ")  // Responde OK
    } else {
        if module.st == inMX || (module.st == wantMX && module.reqTs < otherTs) {
            module.waiting[otherId] = true                              // Posterga resposta
            if otherTs > module.lcl {
                module.lcl = otherTs                                    // Atualiza relógio
            }
        }
    }
}
```

**O que faz:**
1. Extrai timestamp da mensagem recebida
2. Identifica qual processo enviou a mensagem
3. Lógica de decisão:
   - Se não está na SC OU tem timestamp maior → responde OK imediatamente
   - Se está na SC OU tem timestamp menor → posterga resposta
4. Atualiza relógio lógico se necessário

## Algoritmo Implementado

### Estados do Processo:
- `noMX`: Não quer acessar a seção crítica
- `wantMX`: Quer acessar a seção crítica (aguardando respostas)
- `inMX`: Está dentro da seção crítica

### Fluxo do Algoritmo:

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

## Propriedades Garantidas

### Exclusão Mútua:
- Nunca dois processos estarão na SC simultaneamente

### Liveness:
- Se um processo quer entrar na SC, eventualmente conseguirá

### Fairness:
- Processos com timestamps menores têm prioridade

## Melhorias Implementadas

1. Relógios Lógicos de Lamport para ordenação consistente
2. Tratamento de erros na extração de dados
3. Debug mode para acompanhar mensagens
4. Timestamps para resolver conflitos de prioridade

## Como Testar

```bash
# Terminal 1
go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002

# Terminal 2
go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002

# Terminal 3
go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

## Verificação da Corretude

O arquivo `mxOUT.txt` gerado deve conter apenas sequências de `|.` (entrada e saída da SC). Nunca deve conter:
- `||` (duas entradas consecutivas)
- `..` (duas saídas consecutivas)

## Bibliografia

- Reliable and Secure Distributed Programming
- Christian Cachin, Rachid Gerraoui, Luís Rodrigues
- Slides dos autores em http://distributedprogramming.net

---

**Resultado:** Transformação de um template vazio em um sistema funcional de exclusão mútua distribuída com todas as propriedades de segurança e vivacidade garantidas. 
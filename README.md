# Trabalho 1 - Parte 1 - DiMeX (Exclusão Mútua Distribuída)

## Descrição

Este projeto implementa o algoritmo de exclusão mútua distribuída (DiMeX) conforme definido nos slides da disciplina de Sistemas Distribuídos. O algoritmo garante que apenas um processo por vez possa acessar a seção crítica.

## Estrutura do Projeto

```
T1-SD/
├── DIMEX/
│   └── DIMEX-Template.go    # Implementação do algoritmo DiMeX
├── PP2PLink/
│   └── PP2PLink.go          # Camada de comunicação ponto-a-ponto
├── useDIMEX.go              # Aplicação de teste básica
├── useDIMEX-f.go            # Aplicação de teste com arquivo compartilhado
├── go.mod                   # Configuração do módulo Go
└── README.md                # Este arquivo
```

## Como Executar

### Pré-requisitos
- Go 1.18 ou superior

### Execução Básica
Para testar o algoritmo com 3 processos:

1. **Terminal 1:**
```bash
go run useDIMEX.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

2. **Terminal 2:**
```bash
go run useDIMEX.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

3. **Terminal 3:**
```bash
go run useDIMEX.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

### Teste com Arquivo Compartilhado
Para testar com escrita em arquivo compartilhado (mxOUT.txt):

1. **Terminal 1:**
```bash
go run useDIMEX-f.go 0 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

2. **Terminal 2:**
```bash
go run useDIMEX-f.go 1 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

3. **Terminal 3:**
```bash
go run useDIMEX-f.go 2 127.0.0.1:5000 127.0.0.1:6001 127.0.0.1:7002
```

## Algoritmo Implementado

O algoritmo implementado segue o padrão de exclusão mútua distribuída com relógios lógicos:

### Estados do Processo
- `noMX`: Processo não está interessado na seção crítica
- `wantMX`: Processo quer entrar na seção crítica
- `inMX`: Processo está na seção crítica

### Funcionamento

1. **Requisição de Entrada (`handleUponReqEntry`):**
   - Incrementa relógio lógico local
   - Envia mensagem `reqEntry` com timestamp para todos os outros processos
   - Muda estado para `wantMX`

2. **Recebimento de Requisição (`handleUponDeliverReqEntry`):**
   - Se processo não está na SC ou tem timestamp maior: responde OK imediatamente
   - Se processo está na SC ou tem timestamp menor: posterga resposta

3. **Recebimento de Resposta (`handleUponDeliverRespOk`):**
   - Incrementa contador de respostas
   - Se recebeu todas as respostas: libera acesso à SC

4. **Saída da SC (`handleUponReqExit`):**
   - Envia resposta OK para todos os processos aguardando
   - Muda estado para `noMX`
   - Limpa lista de processos aguardando

## Verificação da Corretude

### Teste com Arquivo Compartilhado
O arquivo `mxOUT.txt` gerado deve conter apenas sequências de `|.` (entrada e saída da SC). 
Nunca deve conter `||` (duas entradas consecutivas) ou `..` (duas saídas consecutivas).

Para verificar:
```bash
# Procurar por padrões incorretos
grep -n "||" mxOUT.txt
grep -n ".." mxOUT.txt
```

## Características Técnicas

- **Serialização**: Usa a versão do PP2PLink com serialização de estruturas JSON
- **Relógios Lógicos**: Implementa relógios lógicos de Lamport
- **Comunicação TCP**: Usa conexões TCP persistentes entre processos
- **Debug**: Modo debug disponível para acompanhar mensagens

## Autores

- **Professor**: Fernando Dotti (https://fldotti.github.io/)
- **Disciplina**: Sistemas Distribuídos - PUCRS
- **Semestre**: 2023/1

## Bibliografia

- Reliable and Secure Distributed Programming
- Christian Cachin, Rachid Gerraoui, Luís Rodrigues
- Slides dos autores em http://distributedprogramming.net , "teaching" 
/*  Construido como parte da disciplina: FPPD - PUCRS - Escola Politecnica
    Professor: Fernando Dotti  (https://fldotti.github.io/)
    Modulo representando Algoritmo de Exclusão Mútua Distribuída:
    Semestre 2023/1
	Aspectos a observar:
	   mapeamento de módulo para estrutura
	   inicializacao
	   semantica de concorrência: cada evento é atômico
	   							  módulo trata 1 por vez
	Q U E S T A O
	   Além de obviamente entender a estrutura ...
	   Implementar o núcleo do algoritmo ja descrito, ou seja, o corpo das
	   funcoes reativas a cada entrada possível:
	   			handleUponReqEntry()  // recebe do nivel de cima (app)
				handleUponReqExit()   // recebe do nivel de cima (app)
				handleUponDeliverRespOk(msgOutro)   // recebe do nivel de baixo
				handleUponDeliverReqEntry(msgOutro) // recebe do nivel de baixo
*/

package DIMEX

import (
	PP2PLink "SD/PP2PLink" // Módulo de comunicação ponto-a-ponto confiável
	"fmt"                  // Para impressão de debug e formatação de strings
	"strconv"              // Para conversão de strings para inteiros (timestamps)
	"strings"              // Para manipulação de strings (Contains, Split)
)

// ------------------------------------------------------------------------------------
// ------- principais tipos
// ------------------------------------------------------------------------------------

type State int // enumeracao dos estados possiveis de um processo
const (
	noMX   State = iota // Estado: processo não quer acessar a seção crítica
	wantMX              // Estado: processo quer acessar a seção crítica (aguardando respostas)
	inMX                // Estado: processo está dentro da seção crítica
)

type dmxReq int // enumeracao dos tipos de requisições que a aplicação pode fazer
const (
	ENTER dmxReq = iota // Requisição para entrar na seção crítica
	EXIT                // Requisição para sair da seção crítica
)

type dmxResp struct { // mensagem do módulo DIMEX infrmando que pode acessar - pode ser somente um sinal (vazio)
	// mensagem para aplicacao indicando que pode prosseguir
}

// DIMEX_Module: Estrutura principal do módulo de exclusão mútua distribuída
// Implementa o algoritmo de Lamport para exclusão mútua distribuída
type DIMEX_Module struct {
	Req       chan dmxReq  // canal para receber pedidos da aplicacao (REQ e EXIT)
	Ind       chan dmxResp // canal para informar aplicacao que pode acessar
	addresses []string     // endereco de todos, na mesma ordem
	id        int          // identificador do processo - é o indice no array de enderecos acima
	st        State        // estado deste processo na exclusao mutua distribuida
	waiting   []bool       // processos aguardando tem flag true
	lcl       int          // relogio logico local (Lamport)
	reqTs     int          // timestamp local da ultima requisicao deste processo
	nbrResps  int          // contador de respostas recebidas de outros processos
	dbg       bool         // flag para ativar/desativar debug

	Pp2plink *PP2PLink.PP2PLink // acesso aa comunicacao enviar por PP2PLinq.Req  e receber por PP2PLinq.Ind
}

// ------------------------------------------------------------------------------------
// ------- inicializacao
// ------------------------------------------------------------------------------------

// NewDIMEX: Construtor do módulo DIMEX
// Inicializa o módulo com os endereços dos processos, ID e flag de debug
func NewDIMEX(_addresses []string, _id int, _dbg bool) *DIMEX_Module {

	// Cria o módulo PP2PLink para comunicação ponto-a-ponto
	p2p := PP2PLink.NewPP2PLink(_addresses[_id], _dbg)

	// Cria a estrutura principal do módulo DIMEX
	dmx := &DIMEX_Module{
		Req: make(chan dmxReq, 1),  // Canal com buffer de 1 para requisições
		Ind: make(chan dmxResp, 1), // Canal com buffer de 1 para indicações

		addresses: _addresses,                    // Lista de endereços de todos os processos
		id:        _id,                           // ID deste processo
		st:        noMX,                          // Estado inicial: não quer acessar SC
		waiting:   make([]bool, len(_addresses)), // Array de processos aguardando
		lcl:       0,                             // Relógio lógico inicial: 0
		reqTs:     0,                             // Timestamp inicial: 0
		nbrResps:  0,                             // Contador de respostas inicial: 0
		dbg:       _dbg,                          // Flag de debug

		Pp2plink: p2p} // Módulo de comunicação

	// Inicializa o array de processos aguardando com false
	for i := 0; i < len(dmx.waiting); i++ {
		dmx.waiting[i] = false
	}
	dmx.Start() // Inicia o loop principal do módulo
	dmx.outDbg("Init DIMEX!")
	return dmx
}

// ------------------------------------------------------------------------------------
// ------- nucleo do funcionamento
// ------------------------------------------------------------------------------------

// Start: Loop principal que processa eventos de forma atômica
// Cada evento é processado um por vez, garantindo a semântica de concorrência
func (module *DIMEX_Module) Start() {

	go func() {
		for {
			select {
			case dmxR := <-module.Req: // vindo da  aplicação
				if dmxR == ENTER {
					module.outDbg("app pede mx")
					module.handleUponReqEntry() // ENTRADA DO ALGORITMO

				} else if dmxR == EXIT {
					module.outDbg("app libera mx")
					module.handleUponReqExit() // ENTRADA DO ALGORITMO
				}

			case msgOutro := <-module.Pp2plink.Ind: // vindo de outro processo
				//fmt.Printf("dimex recebe da rede: ", msgOutro)
				if strings.Contains(msgOutro.Message, "respOK") {
					module.outDbg("         <<<---- responde! " + msgOutro.Message)
					module.handleUponDeliverRespOk(msgOutro) // ENTRADA DO ALGORITMO

				} else if strings.Contains(msgOutro.Message, "reqEntry") {
					module.outDbg("          <<<---- pede??  " + msgOutro.Message)
					module.handleUponDeliverReqEntry(msgOutro) // ENTRADA DO ALGORITMO

				}
			}
		}
	}()
}

// ------------------------------------------------------------------------------------
// ------- tratamento de pedidos vindos da aplicacao
// ------- UPON ENTRY
// ------- UPON EXIT
// ------------------------------------------------------------------------------------

// handleUponReqEntry: IMPLEMENTADO - Processa requisição de entrada na seção crítica
// Esta função implementa o algoritmo de Lamport para solicitar acesso à SC
func (module *DIMEX_Module) handleUponReqEntry() {
	/*
					upon event [ dmx, Entry  |  r ]  do
		    			lts.ts++
		    			myTs := lts
		    			resps := 0
		    			para todo processo p
							trigger [ pl , Send | [ reqEntry, r, myTs ]
		    			estado := queroSC
	*/
	module.lcl++              // lts.ts++ - Incrementa relógio lógico local
	module.reqTs = module.lcl // myTs := lts - Define timestamp da requisição atual
	module.nbrResps = 0       // resps := 0 - Zera contador de respostas recebidas

	// para todo processo p - Envia requisição para todos os outros processos
	for i, addr := range module.addresses {
		if i != module.id { // Não envia para si mesmo
			// trigger [ pl , Send | [ reqEntry, r, myTs ] - Envia requisição com timestamp
			msg := fmt.Sprintf("reqEntry,%d,%d", module.id, module.reqTs) // Formato: "reqEntry,processId,timestamp"
			module.sendToLink(addr, msg, "    ")                          // Envia mensagem via PP2PLink
		}
	}

	module.st = wantMX // estado := queroSC - Muda estado para "quer acessar SC"
}

// handleUponReqExit: IMPLEMENTADO - Processa saída da seção crítica
// Esta função implementa a liberação da SC e notificação de processos aguardando
func (module *DIMEX_Module) handleUponReqExit() {
	/*
						upon event [ dmx, Exit  |  r  ]  do
		       				para todo [p, r, ts ] em waiting
		          				trigger [ pl, Send | p , [ respOk, r ]  ]
		    				estado := naoQueroSC
							waiting := {}
	*/
	// para todo [p, r, ts ] em waiting - Para cada processo aguardando resposta
	for i, isWaiting := range module.waiting {
		if isWaiting { // Se o processo está aguardando
			// trigger [ pl, Send | p , [ respOk, r ]  ] - Envia resposta OK
			module.sendToLink(module.addresses[i], "respOK", "    ") // Notifica que pode acessar SC
		}
	}

	module.st = noMX // estado := naoQueroSC - Muda estado para "não quer SC"
	// waiting := {} - Limpa a lista de processos aguardando
	for i := range module.waiting {
		module.waiting[i] = false // Marca todos como não aguardando
	}
}

// ------------------------------------------------------------------------------------
// ------- tratamento de mensagens de outros processos
// ------- UPON respOK
// ------- UPON reqEntry
// ------------------------------------------------------------------------------------

// handleUponDeliverRespOk: IMPLEMENTADO - Processa resposta de outro processo
// Esta função implementa o recebimento de respostas e verificação se pode acessar SC
func (module *DIMEX_Module) handleUponDeliverRespOk(msgOutro PP2PLink.PP2PLink_Ind_Message) {
	/*
						upon event [ pl, Deliver | p, [ respOk, r ] ]
		      				resps++
		      				se resps = N
		    				então trigger [ dmx, Deliver | free2Access ]
		  					    estado := estouNaSC

	*/
	module.nbrResps++ // resps++ - Incrementa contador de respostas recebidas

	// se resps = N (N = número total de processos - 1) - Se recebeu todas as respostas
	if module.nbrResps == len(module.addresses)-1 {
		// então trigger [ dmx, Deliver | free2Access ] - Libera acesso à SC
		module.Ind <- dmxResp{} // Envia sinal para aplicação indicando que pode acessar
		// estado := estouNaSC - Muda estado para "está na SC"
		module.st = inMX
	}
}

// handleUponDeliverReqEntry: IMPLEMENTADO - Processa requisição de outro processo
// Esta função implementa a lógica de decisão do algoritmo de Lamport
// Decide se responde OK imediatamente ou posterga a resposta
func (module *DIMEX_Module) handleUponDeliverReqEntry(msgOutro PP2PLink.PP2PLink_Ind_Message) {
	// outro processo quer entrar na SC
	/*
						upon event [ pl, Deliver | p, [ reqEntry, r, rts ]  do
		     				se (estado == naoQueroSC)   OR
		        				 (estado == QueroSC AND  myTs >  ts)
							então  trigger [ pl, Send | p , [ respOk, r ]  ]
		 					senão
		        				se (estado == estouNaSC) OR
		           					 (estado == QueroSC AND  myTs < ts)
		        				então  postergados := postergados + [p, r ]
		     					lts.ts := max(lts.ts, rts.ts)
	*/

	// Extrai informações da mensagem: "reqEntry,processId,timestamp"
	parts := strings.Split(msgOutro.Message, ",") // Divide a mensagem por vírgulas
	if len(parts) != 3 {                          // Verifica se a mensagem tem o formato correto
		module.outDbg("Mensagem reqEntry malformada: " + msgOutro.Message)
		return
	}

	// Converte processId e timestamp para inteiros
	otherId, err1 := strconv.Atoi(parts[1]) // ID do processo remetente
	otherTs, err2 := strconv.Atoi(parts[2]) // Timestamp da requisição do outro processo
	if err1 != nil || err2 != nil {         // Verifica se a conversão foi bem-sucedida
		module.outDbg("Erro ao converter ID ou timestamp: " + msgOutro.Message)
		return
	}

	// se (estado == naoQueroSC) OR (estado == QueroSC AND myTs > ts)
	// Lógica de decisão: responde OK se não está na SC OU tem timestamp maior (menor prioridade)
	if module.st == noMX || (module.st == wantMX && module.reqTs > otherTs) {
		// então trigger [ pl, Send | p , [ respOk, r ]  ] - Responde OK imediatamente
		module.sendToLink(module.addresses[otherId], "respOK", "    ")
	} else {
		// senão se (estado == estouNaSC) OR (estado == QueroSC AND myTs < ts)
		// Posterga resposta se está na SC OU tem timestamp menor (maior prioridade)
		if module.st == inMX || (module.st == wantMX && module.reqTs < otherTs) {
			// então postergados := postergados + [p, r ] - Adiciona à lista de aguardando
			module.waiting[otherId] = true
			// lts.ts := max(lts.ts, rts.ts) - Atualiza relógio lógico (Lamport)
			if otherTs > module.lcl {
				module.lcl = otherTs
			}
		}
	}
}

// ------------------------------------------------------------------------------------
// ------- funcoes de ajuda
// ------------------------------------------------------------------------------------

// sendToLink: Função auxiliar para enviar mensagens via PP2PLink
// Encapsula o envio de mensagens com debug
func (module *DIMEX_Module) sendToLink(address string, content string, space string) {
	module.outDbg(space + " ---->>>>   to: " + address + "     msg: " + content) // Debug
	module.Pp2plink.Req <- PP2PLink.PP2PLink_Req_Message{                        // Envia mensagem via PP2PLink
		To:      address, // Endereço de destino
		Message: content} // Conteúdo da mensagem
}

// before: Função auxiliar para comparar timestamps (usada para ordenação)
// Implementa a lógica de ordenação de Lamport: timestamp menor tem prioridade
// Em caso de timestamps iguais, ID menor tem prioridade
func before(oneId, oneTs, othId, othTs int) bool {
	if oneTs < othTs { // Se timestamp é menor, tem prioridade
		return true
	} else if oneTs > othTs { // Se timestamp é maior, não tem prioridade
		return false
	} else { // Se timestamps são iguais, desempata por ID
		return oneId < othId // ID menor tem prioridade
	}
}

// outDbg: Função para impressão de debug
// Imprime mensagens de debug apenas se a flag dbg estiver ativa
func (module *DIMEX_Module) outDbg(s string) {
	if module.dbg { // Só imprime se debug estiver ativo
		fmt.Println(". . . . . . . . . . . . [ DIMEX : " + s + " ]")
	}
}

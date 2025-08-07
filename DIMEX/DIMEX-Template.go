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
	PP2PLink "SD/PP2PLink"  // Módulo de comunicação ponto-a-ponto
	"fmt"                     // Para impressão de debug
	"net"                     // ADICIONADO: Para conexões TCP (map[string]net.Conn)
	"strconv"                 // ADICIONADO: Para conversão de strings para int (timestamps)
	"strings"                 // Para manipulação de strings (Contains)
)

// ------------------------------------------------------------------------------------
// ------- principais tipos
// ------------------------------------------------------------------------------------

// State: Enumeração dos estados possíveis de um processo no algoritmo de exclusão mútua
type State int
const (
	noMX State = iota   // Estado: não quer acessar a seção crítica
	wantMX              // Estado: quer acessar a seção crítica (aguardando respostas)
	inMX                 // Estado: está dentro da seção crítica
)

// dmxReq: Enumeração dos tipos de requisições que a aplicação pode fazer
type dmxReq int
const (
	ENTER dmxReq = iota  // Requisição para entrar na seção crítica
	EXIT                 // Requisição para sair da seção crítica
)

// dmxResp: Estrutura vazia usada como sinal para informar que pode acessar a SC
type dmxResp struct {
	// mensagem para aplicacao indicando que pode prosseguir
}

// DIMEX_Module: Estrutura principal do módulo de exclusão mútua distribuída
type DIMEX_Module struct {
	Req       chan dmxReq  // Canal para receber pedidos da aplicação (ENTER/EXIT)
	Ind       chan dmxResp // Canal para informar aplicação que pode acessar a SC
	addresses []string     // Lista de endereços de todos os processos
	id        int          // ID deste processo (índice no array addresses)
	st        State        // Estado atual deste processo (noMX/wantMX/inMX)
	waiting   []bool       // Array indicando quais processos estão aguardando resposta
	lcl       int          // Relógio lógico local (Lamport)
	reqTs     int          // Timestamp da última requisição deste processo
	nbrResps  int          // ADICIONADO: Contador de respostas recebidas
	dbg       bool         // Flag para ativar/desativar debug

	Pp2plink *PP2PLink.PP2PLink // Acesso à camada de comunicação
}

// ------------------------------------------------------------------------------------
// ------- inicializacao
// ------------------------------------------------------------------------------------

// NewDIMEX: Construtor do módulo DIMEX
func NewDIMEX(_addresses []string, _id int, _dbg bool) *DIMEX_Module {

	// MODIFICADO: Usa versão do PP2PLink com serialização (Andrius)
	p2p := &PP2PLink.PP2PLink{
		Ind:   make(chan PP2PLink.PP2PLink_Ind_Message, 1),
		Req:   make(chan PP2PLink.PP2PLink_Req_Message, 1),
		Run:   false,
		Cache: make(map[string]net.Conn),  // ADICIONADO: Cache de conexões TCP
	}
	p2p.Init(_addresses[_id])  // MODIFICADO: Usa Init() ao invés de NewPP2PLink()

	// Criação da estrutura principal
	dmx := &DIMEX_Module{
		Req: make(chan dmxReq, 1),
		Ind: make(chan dmxResp, 1),

		addresses: _addresses,
		id:        _id,
		st:        noMX,                    // Estado inicial: não quer SC
		waiting:   make([]bool, len(_addresses)),
		lcl:       0,                       // Relógio lógico inicial: 0
		reqTs:     0,                       // Timestamp inicial: 0
		nbrResps:  0,                       // ADICIONADO: Contador de respostas
		dbg:       _dbg,

		Pp2plink: p2p}

	// Inicializa array de processos aguardando
	for i := 0; i < len(dmx.waiting); i++ {
		dmx.waiting[i] = false
	}
	dmx.Start()
	dmx.outDbg("Init DIMEX!")
	return dmx
}

// ------------------------------------------------------------------------------------
// ------- nucleo do funcionamento
// ------------------------------------------------------------------------------------

// Start: Loop principal que processa eventos de forma atômica
func (module *DIMEX_Module) Start() {

	go func() {
		for {
			select {
			case dmxR := <-module.Req: // Evento vindo da aplicação
				if dmxR == ENTER {
					module.outDbg("app pede mx")
					module.handleUponReqEntry() // ENTRADA DO ALGORITMO

				} else if dmxR == EXIT {
					module.outDbg("app libera mx")
					module.handleUponReqExit() // ENTRADA DO ALGORITMO
				}

			case msgOutro := <-module.Pp2plink.Ind: // Evento vindo de outro processo
				// MODIFICADO: Usa Message.Value ao invés de Message
				if strings.Contains(msgOutro.Message.Value, "respOK") {
					module.outDbg("         <<<---- responde! " + msgOutro.Message.Value)
					module.handleUponDeliverRespOk(msgOutro) // ENTRADA DO ALGORITMO

				} else if strings.Contains(msgOutro.Message.Value, "reqEntry") {
					module.outDbg("          <<<---- pede??  " + msgOutro.Message.Value)
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
	module.lcl++                    // IMPLEMENTADO: Incrementa relógio lógico
	module.reqTs = module.lcl       // IMPLEMENTADO: Define timestamp da requisição
	module.nbrResps = 0             // IMPLEMENTADO: Zera contador de respostas
	
	// IMPLEMENTADO: Envia requisição para todos os outros processos
	for i, addr := range module.addresses {
		if i != module.id {
			// IMPLEMENTADO: Inclui timestamp na mensagem para ordenação
			msgData := map[string]string{
				"timestamp": strconv.Itoa(module.reqTs),
				"processId": strconv.Itoa(module.id),
			}
			module.sendToLinkWithData(addr, "reqEntry", msgData, "    ")
		}
	}
	
	module.st = wantMX              // IMPLEMENTADO: Muda estado para "quer SC"
}

// handleUponReqExit: IMPLEMENTADO - Processa saída da seção crítica
func (module *DIMEX_Module) handleUponReqExit() {
	/*
						upon event [ dmx, Exit  |  r  ]  do
		       				para todo [p, r, ts ] em waiting
		          				trigger [ pl, Send | p , [ respOk, r ]  ]
		    				estado := naoQueroSC
							waiting := {}
	*/
	// IMPLEMENTADO: Envia resposta OK para todos os processos aguardando
	for i, isWaiting := range module.waiting {
		if isWaiting {
			module.sendToLink(module.addresses[i], "respOK", "    ")
		}
	}
	
	module.st = noMX                // IMPLEMENTADO: Muda estado para "não quer SC"
	// IMPLEMENTADO: Limpa a lista de processos aguardando
	for i := range module.waiting {
		module.waiting[i] = false
	}
}

// ------------------------------------------------------------------------------------
// ------- tratamento de mensagens de outros processos
// ------- UPON respOK
// ------- UPON reqEntry
// ------------------------------------------------------------------------------------

// handleUponDeliverRespOk: IMPLEMENTADO - Processa resposta de outro processo
func (module *DIMEX_Module) handleUponDeliverRespOk(msgOutro PP2PLink.PP2PLink_Ind_Message) {
	/*
						upon event [ pl, Deliver | p, [ respOk, r ] ]
		      				resps++
		      				se resps = N
		    				então trigger [ dmx, Deliver | free2Access ]
		  					    estado := estouNaSC

	*/
	module.nbrResps++               // IMPLEMENTADO: Incrementa contador de respostas
	if module.nbrResps == len(module.addresses)-1 {
		module.Ind <- dmxResp{}      // IMPLEMENTADO: Libera acesso à SC
		module.st = inMX             // IMPLEMENTADO: Muda estado para "está na SC"
	}
}

// handleUponDeliverReqEntry: IMPLEMENTADO - Processa requisição de outro processo
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
	
	// IMPLEMENTADO: Extrai timestamp da mensagem para comparação
	otherTsStr, exists := msgOutro.Message.Data["timestamp"]
	if !exists {
		module.outDbg("Erro: timestamp não encontrado na mensagem")
		return
	}
	otherTs, err := strconv.Atoi(otherTsStr)
	if err != nil {
		module.outDbg("Erro ao converter timestamp: " + err.Error())
		return
	}
	
	// IMPLEMENTADO: Identifica qual processo enviou a mensagem
	senderId := -1
	for i, addr := range module.addresses {
		if strings.Contains(addr, msgOutro.From) {
			senderId = i
			break
		}
	}
	if senderId == -1 {
		module.outDbg("Erro: não foi possível identificar o processo remetente")
		return
	}
	
	// IMPLEMENTADO: Lógica de decisão baseada em estado e timestamp
	if module.st == noMX || (module.st == wantMX && module.reqTs > otherTs) {
		// Pode responder OK imediatamente (não está na SC ou tem prioridade)
		module.sendToLink(msgOutro.From, "respOK", "    ")
	} else if module.st == inMX || (module.st == wantMX && module.reqTs < otherTs) {
		// Deve postergar a resposta (está na SC ou tem menor prioridade)
		module.waiting[senderId] = true
		// IMPLEMENTADO: Atualiza relógio lógico (Lamport)
		if otherTs > module.lcl {
			module.lcl = otherTs
		}
	}
}

// ------------------------------------------------------------------------------------
// ------- funcoes de ajuda
// ------------------------------------------------------------------------------------

// sendToLink: Função auxiliar para enviar mensagens simples
func (module *DIMEX_Module) sendToLink(address string, content string, space string) {
	module.outDbg(space + " ---->>>>   to: " + address + "     msg: " + content)
	// MODIFICADO: Usa PP2LinkMessage ao invés de string direta
	module.Pp2plink.Req <- PP2PLink.PP2PLink_Req_Message{
		To: address,
		Message: PP2PLink.PP2LinkMessage{
			Value: content,
			Data:  make(map[string]string),
		}}
}

// sendToLinkWithData: ADICIONADO - Função para enviar mensagens com dados extras
func (module *DIMEX_Module) sendToLinkWithData(address string, content string, data map[string]string, space string) {
	module.outDbg(space + " ---->>>>   to: " + address + "     msg: " + content)
	module.Pp2plink.Req <- PP2PLink.PP2PLink_Req_Message{
		To: address,
		Message: PP2PLink.PP2LinkMessage{
			Value: content,
			Data:  data,
		}}
}

// before: Função auxiliar para comparar timestamps (usada para ordenação)
func before(oneId, oneTs, othId, othTs int) bool {
	if oneTs < othTs {
		return true
	} else if oneTs > othTs {
		return false
	} else {
		return oneId < othId
	}
}

// outDbg: Função para impressão de debug
func (module *DIMEX_Module) outDbg(s string) {
	if module.dbg {
		fmt.Println(". . . . . . . . . . . . [ DIMEX : " + s + " ]")
	}
} 
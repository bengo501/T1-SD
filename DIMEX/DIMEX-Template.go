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
	PP2PLink "SD/PP2PLink" // Módulo de comunicação ponto-a-ponto
	"fmt"                  // Para impressão de debug
	"net"                  // ADICIONADO: Para conexões TCP (map[string]net.Conn)
	"strconv"              // ADICIONADO: Para conversão de strings para int (timestamps)
	"strings"              // Para manipulação de strings (Contains)
)

// ------------------------------------------------------------------------------------
// ------- principais tipos
// ------------------------------------------------------------------------------------

// State: Enumeração dos estados possíveis de um processo no algoritmo de exclusão mútua
type State int

const (
	noMX   State = iota // Estado: não quer acessar a seção crítica
	wantMX              // Estado: quer acessar a seção crítica (aguardando respostas)
	inMX                // Estado: está dentro da seção crítica
)

// dmxReq: Enumeração dos tipos de requisições que a aplicação pode fazer
type dmxReq int

const (
	ENTER dmxReq = iota // Requisição para entrar na seção crítica
	EXIT                // Requisição para sair da seção crítica
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
		Cache: make(map[string]net.Conn), // ADICIONADO: Cache de conexões TCP
	}
	p2p.Init(_addresses[_id]) // MODIFICADO: Usa Init() ao invés de NewPP2PLink()

	// Criação da estrutura principal
	dmx := &DIMEX_Module{
		Req: make(chan dmxReq, 1),
		Ind: make(chan dmxResp, 1),

		addresses: _addresses,
		id:        _id,
		st:        noMX, // Estado inicial: não quer SC
		waiting:   make([]bool, len(_addresses)),
		lcl:       0, // Relógio lógico inicial: 0
		reqTs:     0, // Timestamp inicial: 0
		nbrResps:  0, // ADICIONADO: Contador de respostas
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
		module.outDbg("=== LOOP PRINCIPAL INICIADO ===")
		for {
			select {
			case dmxR := <-module.Req: // Evento vindo da aplicação
				if dmxR == ENTER {
					module.outDbg("=== EVENTO ENTER RECEBIDO ===")
					module.handleUponReqEntry() // ENTRADA DO ALGORITMO

				} else if dmxR == EXIT {
					module.outDbg("=== EVENTO EXIT RECEBIDO ===")
					module.handleUponReqExit() // ENTRADA DO ALGORITMO
				}

			case msgOutro := <-module.Pp2plink.Ind: // Evento vindo de outro processo
				module.outDbg(fmt.Sprintf("=== MENSAGEM RECEBIDA DE %s ===", msgOutro.From))
				module.outDbg(fmt.Sprintf("Conteúdo da mensagem: %s", msgOutro.Message.Value))
				// MODIFICADO: Usa Message.Value ao invés de Message
				if strings.Contains(msgOutro.Message.Value, "respOK") {
					module.outDbg("         <<<---- responde! " + msgOutro.Message.Value)
					module.handleUponDeliverRespOk(msgOutro) // ENTRADA DO ALGORITMO

				} else if strings.Contains(msgOutro.Message.Value, "reqEntry") {
					module.outDbg("          <<<---- pede??  " + msgOutro.Message.Value)
					module.handleUponDeliverReqEntry(msgOutro) // ENTRADA DO ALGORITMO

				} else {
					module.outDbg("Mensagem desconhecida: " + msgOutro.Message.Value)
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
	module.outDbg("=== ENTRADA NA SEÇÃO CRÍTICA ===")
	module.lcl++              // IMPLEMENTADO: Incrementa relógio lógico
	module.reqTs = module.lcl // IMPLEMENTADO: Define timestamp da requisição
	module.nbrResps = 0       // IMPLEMENTADO: Zera contador de respostas

	// CORREÇÃO: Adiciona delay baseado no ID para evitar conflitos de timestamp
	// Isso garante que cada processo tenha um timestamp único inicial
	if module.reqTs == 1 {
		module.reqTs += module.id
		module.lcl = module.reqTs
	}

	// MODIFICADO: Se há apenas 1 processo, libera imediatamente
	if len(module.addresses) == 1 {
		module.outDbg("=== PROCESSO ÚNICO - LIBERANDO IMEDIATAMENTE ===")
		module.Ind <- dmxResp{}
		module.st = inMX
		module.outDbg("Estado alterado para inMX")
		return
	}

	module.outDbg(fmt.Sprintf("Enviando requisições para %d processos", len(module.addresses)-1))

	// IMPLEMENTADO: Envia requisição para todos os outros processos
	for i, addr := range module.addresses {
		if i != module.id {
			// IMPLEMENTADO: Inclui timestamp na mensagem para ordenação
			msgData := map[string]string{
				"timestamp": strconv.Itoa(module.reqTs),
				"processId": strconv.Itoa(module.id),
			}
			module.outDbg(fmt.Sprintf("Enviando para processo %d em %s", i, addr))
			module.sendToLinkWithData(addr, "reqEntry", msgData, "    ")
		}
	}

	module.st = wantMX // IMPLEMENTADO: Muda estado para "quer SC"
	module.outDbg("Estado alterado para wantMX")
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
	module.outDbg("=== SAÍDA DA SEÇÃO CRÍTICA ===")

	// IMPLEMENTADO: Envia resposta OK para todos os processos aguardando
	for i, isWaiting := range module.waiting {
		if isWaiting {
			module.outDbg(fmt.Sprintf("Enviando resposta OK para processo %d em %s", i, module.addresses[i]))
			module.sendToLink(module.addresses[i], "respOK", "    ")
		}
	}

	module.st = noMX // IMPLEMENTADO: Muda estado para "não quer SC"
	// IMPLEMENTADO: Limpa a lista de processos aguardando
	for i := range module.waiting {
		module.waiting[i] = false
	}
	module.outDbg("Estado alterado para noMX")
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
	module.outDbg("=== RECEBEU RESPOSTA OK ===")
	module.nbrResps++ // IMPLEMENTADO: Incrementa contador de respostas
	module.outDbg(fmt.Sprintf("Respostas recebidas: %d/%d", module.nbrResps, len(module.addresses)-1))

	// MODIFICADO: Se há apenas 1 processo, libera imediatamente
	if len(module.addresses) == 1 {
		module.outDbg("=== PROCESSO ÚNICO - LIBERANDO IMEDIATAMENTE ===")
		module.Ind <- dmxResp{}
		module.st = inMX
		module.outDbg("Estado alterado para inMX")
		return
	}

	if module.nbrResps == len(module.addresses)-1 {
		module.outDbg("=== LIBERANDO ACESSO À SEÇÃO CRÍTICA ===")
		module.Ind <- dmxResp{} // IMPLEMENTADO: Libera acesso à SC
		module.st = inMX        // IMPLEMENTADO: Muda estado para "está na SC"
		module.outDbg("Estado alterado para inMX")
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
		module.outDbg("Aviso: timestamp não encontrado, usando timestamp padrão")
		otherTsStr = "0" // Usa timestamp padrão se não encontrado
	}
	otherTs, err := strconv.Atoi(otherTsStr)
	if err != nil {
		module.outDbg("Erro ao converter timestamp: " + err.Error() + ", usando 0")
		otherTs = 0 // Usa 0 se erro na conversão
	}

	// IMPLEMENTADO: Identifica qual processo enviou a mensagem (CORRIGIDO)
	senderId := -1
	remoteAddr := msgOutro.From
	// Remove a porta se presente para comparação
	if strings.Contains(remoteAddr, ":") {
		parts := strings.Split(remoteAddr, ":")
		if len(parts) >= 2 {
			remoteAddr = parts[0] + ":" + parts[1]
		}
	}

	for i, addr := range module.addresses {
		// Compara endereços de forma mais robusta
		if addr == remoteAddr || strings.Contains(addr, remoteAddr) || strings.Contains(remoteAddr, addr) {
			senderId = i
			break
		}
	}

	// Se não conseguiu identificar, tenta extrair do processId na mensagem
	if senderId == -1 {
		if processIdStr, exists := msgOutro.Message.Data["processId"]; exists {
			if processId, err := strconv.Atoi(processIdStr); err == nil && processId >= 0 && processId < len(module.addresses) {
				senderId = processId
			}
		}
	}

	// Se ainda não conseguiu identificar, usa um fallback
	if senderId == -1 {
		module.outDbg("Aviso: não foi possível identificar o processo remetente, usando 0")
		senderId = 0 // Fallback para o primeiro processo
	}

	module.outDbg(fmt.Sprintf("Processo %d (endereço: %s) solicitando acesso", senderId, module.addresses[senderId]))

	// CORREÇÃO FINAL: Lógica de decisão baseada em estado e timestamp
	// Regra: responde OK se:
	// 1. Não está na SC (noMX) OU
	// 2. Está querendo SC mas tem timestamp MAIOR (menor prioridade) OU
	// 3. Está querendo SC mas tem timestamp IGUAL e ID MAIOR (desempate por ID)
	// 4. Está na SC (inMX) - deve sempre postergar

	if module.st == inMX {
		// Se está na SC, sempre posterga
		module.outDbg(fmt.Sprintf("Postergando resposta para processo %d (está na SC)", senderId))
		module.waiting[senderId] = true
		// Atualiza relógio lógico (Lamport)
		if otherTs > module.lcl {
			module.lcl = otherTs
		}
	} else if module.st == noMX ||
		(module.st == wantMX && module.reqTs > otherTs) ||
		(module.st == wantMX && module.reqTs == otherTs && module.id > senderId) {
		// Pode responder OK imediatamente
		module.outDbg(fmt.Sprintf("Respondendo OK imediatamente para processo %d", senderId))
		module.sendToLink(module.addresses[senderId], "respOK", "    ")
	} else {
		// Deve postergar a resposta (wantMX com menor prioridade)
		module.outDbg(fmt.Sprintf("Postergando resposta para processo %d", senderId))
		module.waiting[senderId] = true
		// Atualiza relógio lógico (Lamport)
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

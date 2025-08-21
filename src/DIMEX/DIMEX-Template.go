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
				handleUponSnapshot()  // recebe do nivel de cima (app) - NOVO
				handleUponSnapshotMarker(msgOutro) // recebe do nivel de baixo - NOVO
*/

package DIMEX

import (
	PP2PLink "SD/src/PP2PLink"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

// ------------------------------------------------------------------------------------
// ------- principais tipos
// ------------------------------------------------------------------------------------

type State int // enumeracao dos estados possiveis de um processo
const (
	noMX State = iota
	wantMX
	inMX
)

type dmxReq int // enumeracao dos tipos de requisições que a aplicação pode fazer
const (
	ENTER dmxReq = iota
	EXIT
	SNAPSHOT // NOVO: tipo para snapshot
)

type dmxResp struct { // mensagem do módulo DIMEX infrmando que pode acessar - pode ser somente um sinal (vazio)
	// mensagem para aplicacao indicando que pode prosseguir
}

// NOVO: Estrutura para estado do processo em snapshot
type ProcessState struct {
	SnapshotId   int      `json:"snapshot_id"`
	ProcessId    int      `json:"process_id"`
	State        State    `json:"state"`
	LocalClock   int      `json:"local_clock"`
	RequestTs    int      `json:"request_timestamp"`
	NumResponses int      `json:"num_responses"`
	Waiting      []bool   `json:"waiting"`
	Addresses    []string `json:"addresses"`
	Timestamp    int64    `json:"timestamp"`
}

type DIMEX_Module struct {
	Req       chan dmxReq  // canal para receber pedidos da aplicacao (REQ, EXIT, SNAPSHOT)
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

	// NOVO: Campos para snapshot (Chandy-Lamport)
	nextSnapshotId  int              // próximo ID de snapshot
	activeSnapshots map[int]bool     // snapshots ativos
	channelMessages map[int][]string // mensagens em trânsito por snapshot
	snapshotMutex   sync.Mutex       // mutex para operações de snapshot
}

// ------------------------------------------------------------------------------------
// ------- inicializacao
// ------------------------------------------------------------------------------------

func NewDIMEX(_addresses []string, _id int, _dbg bool) *DIMEX_Module {
	// Cria o módulo PP2PLink para comunicação ponto-a-ponto usando o template original
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

		Pp2plink: p2p, // Módulo de comunicação

		// NOVO: Inicialização dos campos de snapshot
		nextSnapshotId:  1,                      // Primeiro snapshot terá ID 1
		activeSnapshots: make(map[int]bool),     // Mapa de snapshots ativos
		channelMessages: make(map[int][]string), // Mapa de mensagens por snapshot
	}

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
				} else if dmxR == SNAPSHOT {
					module.outDbg("app pede snapshot")
					module.handleUponSnapshot() // ENTRADA DO ALGORITMO - NOVO
				}

			case msgOutro := <-module.Pp2plink.Ind: // vindo de outro processo
				//fmt.Printf("dimex recebe da rede: ", msgOutro)
				if strings.Contains(msgOutro.Message, "respOK") {
					module.outDbg("         <<<---- responde! " + msgOutro.Message)
					module.handleUponDeliverRespOk(msgOutro) // ENTRADA DO ALGORITMO

				} else if strings.Contains(msgOutro.Message, "reqEntry") {
					module.outDbg("          <<<---- pede??  " + msgOutro.Message)
					module.handleUponDeliverReqEntry(msgOutro) // ENTRADA DO ALGORITMO
				} else if strings.Contains(msgOutro.Message, "snapshotMarker") {
					module.outDbg("          <<<---- snapshot marker " + msgOutro.Message)
					module.handleUponSnapshotMarker(msgOutro) // ENTRADA DO ALGORITMO - NOVO
				}
			}
		}
	}()
}

// ------------------------------------------------------------------------------------
// ------- tratamento de pedidos vindos da aplicacao
// ------- UPON ENTRY
// ------- UPON EXIT
// ------- UPON SNAPSHOT - NOVO
// ------------------------------------------------------------------------------------

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

	module.outDbg(fmt.Sprintf("handleUponReqEntry: lcl=%d, reqTs=%d, nbrResps=%d", module.lcl, module.reqTs, module.nbrResps))

	// para todo processo p - Envia requisição para todos os outros processos
	for i, addr := range module.addresses {
		if i != module.id { // Não envia para si mesmo
			// trigger [ pl , Send | [ reqEntry, r, myTs ] - Envia requisição com timestamp
			msg := fmt.Sprintf("reqEntry,%d,%d", module.id, module.reqTs) // Formato: "reqEntry,processId,timestamp"
			module.sendToLink(addr, msg, "    ")                          // Envia mensagem via PP2PLink
		}
	}

	module.st = wantMX // estado := queroSC - Muda estado para "quer acessar SC"
	module.outDbg(fmt.Sprintf("handleUponReqEntry: estado mudou para wantMX"))
}

func (module *DIMEX_Module) handleUponReqExit() {
	/*
						upon event [ dmx, Exit  |  r  ]  do
		       				para todo [p, r, ts ] em waiting
		          				trigger [ pl, Send | p , [ respOk, r ]  ]
		    				estado := naoQueroSC
							waiting := {}
	*/
	module.outDbg(fmt.Sprintf("handleUponReqExit: estado atual=%d", module.st))

	// para todo [p, r, ts ] em waiting - Para cada processo aguardando resposta
	for i, isWaiting := range module.waiting {
		if isWaiting { // Se o processo está aguardando
			module.outDbg(fmt.Sprintf("handleUponReqExit: enviando respOK para processo %d", i))
			// trigger [ pl, Send | p , [ respOk, r ]  ] - Envia resposta OK
			module.sendToLink(module.addresses[i], "respOK", "    ") // Notifica que pode acessar SC
		}
	}

	module.st = noMX // estado := naoQueroSC - Muda estado para "não quer SC"
	// waiting := {} - Limpa a lista de processos aguardando
	for i := range module.waiting {
		module.waiting[i] = false // Marca todos como não aguardando
	}

	module.outDbg(fmt.Sprintf("handleUponReqExit: estado mudou para noMX, waiting limpo"))
}

// NOVO: handleUponSnapshot - Implementa o início de um snapshot (algoritmo de Chandy-Lamport)
func (module *DIMEX_Module) handleUponSnapshot() {
	module.snapshotMutex.Lock()
	defer module.snapshotMutex.Unlock()

	// Gera ID único para o snapshot
	snapshotId := module.nextSnapshotId
	module.nextSnapshotId++

	module.outDbg(fmt.Sprintf("Iniciando snapshot %d", snapshotId))

	// Marca snapshot como ativo
	module.activeSnapshots[snapshotId] = true
	module.channelMessages[snapshotId] = make([]string, 0)

	// Grava estado local (passo 1 do algoritmo de Chandy-Lamport)
	module.saveProcessState(snapshotId)

	// Envia marcadores para todos os outros processos (passo 2)
	for i, addr := range module.addresses {
		if i != module.id {
			msg := fmt.Sprintf("snapshotMarker,%d,%d", snapshotId, module.id)
			module.sendToLink(addr, msg, "    ")
		}
	}
}

// ------------------------------------------------------------------------------------
// ------- tratamento de mensagens de outros processos
// ------- UPON respOK
// ------- UPON reqEntry
// ------- UPON snapshotMarker - NOVO
// ------------------------------------------------------------------------------------

func (module *DIMEX_Module) handleUponDeliverRespOk(msgOutro PP2PLink.PP2PLink_Ind_Message) {
	/*
						upon event [ pl, Deliver | p, [ respOk, r ] ]
		      				resps++
		      				se resps = N
		    				então trigger [ dmx, Deliver | free2Access ]
		  					    estado := estouNaSC

	*/
	module.nbrResps++ // resps++ - Incrementa contador de respostas recebidas

	module.outDbg(fmt.Sprintf("handleUponDeliverRespOk: nbrResps=%d, total esperado=%d", module.nbrResps, len(module.addresses)-1))

	// se resps = N (N = número total de processos - 1) - Se recebeu todas as respostas
	if module.nbrResps == len(module.addresses)-1 {
		module.outDbg("handleUponDeliverRespOk: TODAS AS RESPOSTAS RECEBIDAS! Liberando acesso à SC")
		// então trigger [ dmx, Deliver | free2Access ] - Libera acesso à SC
		module.Ind <- dmxResp{} // Envia sinal para aplicação indicando que pode acessar
		// estado := estouNaSC - Muda estado para "está na SC"
		module.st = inMX
		module.outDbg(fmt.Sprintf("handleUponDeliverRespOk: estado mudou para inMX"))
	}
}

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

	module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: recebido de processo %d, timestamp %d", otherId, otherTs))
	module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: meu estado=%d, meu reqTs=%d", module.st, module.reqTs))

	// CORREÇÃO: Lógica correta do algoritmo Ricart/Agrawalla
	// Responde OK imediatamente se:
	// 1. Não está na SC (noMX) OU
	// 2. Está querendo SC mas tem timestamp MAIOR (menor prioridade)
	if module.st == noMX {
		module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: estado=noMX, respondendo OK imediatamente"))
		module.sendToLink(module.addresses[otherId], "respOK", "    ")
	} else if module.st == wantMX {
		module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: estado=wantMX, meu reqTs=%d, otherTs=%d", module.reqTs, otherTs))
		// CORREÇÃO: Se meu timestamp é MAIOR, respondo OK (tenho menor prioridade)
		if module.reqTs > otherTs {
			module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: meu timestamp MAIOR, respondendo OK (menor prioridade)"))
			module.sendToLink(module.addresses[otherId], "respOK", "    ")
		} else if module.reqTs < otherTs {
			// Se meu timestamp é MENOR, postergo resposta (tenho maior prioridade)
			module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: meu timestamp MENOR, postergando resposta (maior prioridade)"))
			module.waiting[otherId] = true
			// Atualiza relógio lógico (Lamport)
			if otherTs > module.lcl {
				module.lcl = otherTs
				module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: relógio atualizado para %d", module.lcl))
			}
		} else {
			// Timestamps iguais - desempata por ID do processo
			if module.id > otherId {
				module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: timestamps iguais, meu ID maior, respondendo OK"))
				module.sendToLink(module.addresses[otherId], "respOK", "    ")
			} else {
				module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: timestamps iguais, meu ID menor, postergando resposta"))
				module.waiting[otherId] = true
				// Atualiza relógio lógico (Lamport)
				if otherTs > module.lcl {
					module.lcl = otherTs
					module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: relógio atualizado para %d", module.lcl))
				}
			}
		}
	} else if module.st == inMX {
		module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: estado=inMX, postergando resposta"))
		module.waiting[otherId] = true
		// Atualiza relógio lógico (Lamport)
		if otherTs > module.lcl {
			module.lcl = otherTs
			module.outDbg(fmt.Sprintf("handleUponDeliverReqEntry: relógio atualizado para %d", module.lcl))
		}
	}
}

// NOVO: handleUponSnapshotMarker - Processa marcador de snapshot recebido
func (module *DIMEX_Module) handleUponSnapshotMarker(msgOutro PP2PLink.PP2PLink_Ind_Message) {
	parts := strings.Split(msgOutro.Message, ",")
	if len(parts) != 3 {
		module.outDbg("Mensagem snapshotMarker malformada: " + msgOutro.Message)
		return
	}

	snapshotId, err1 := strconv.Atoi(parts[1])
	fromId, err2 := strconv.Atoi(parts[2])
	if err1 != nil || err2 != nil {
		module.outDbg("Erro ao converter snapshotId ou fromId: " + msgOutro.Message)
		return
	}

	module.snapshotMutex.Lock()
	defer module.snapshotMutex.Unlock()

	// Se é o primeiro marcador recebido para este snapshot
	if !module.activeSnapshots[snapshotId] {
		module.outDbg(fmt.Sprintf("Primeiro marcador recebido para snapshot %d", snapshotId))

		// Grava estado local
		module.saveProcessState(snapshotId)

		// Marca snapshot como ativo
		module.activeSnapshots[snapshotId] = true
		module.channelMessages[snapshotId] = make([]string, 0)

		// Envia marcadores para todos os outros processos (exceto o remetente)
		for i, addr := range module.addresses {
			if i != module.id && i != fromId {
				msg := fmt.Sprintf("snapshotMarker,%d,%d", snapshotId, module.id)
				module.sendToLink(addr, msg, "    ")
			}
		}
	}

	// Grava estado do canal (mensagens recebidas após o marcador)
	// Esta implementação simplificada grava todas as mensagens recebidas
	// Em uma implementação mais precisa, gravaria apenas mensagens recebidas após o marcador
}

// NOVO: saveProcessState - Grava o estado do processo para um snapshot específico
func (module *DIMEX_Module) saveProcessState(snapshotId int) {
	state := ProcessState{
		SnapshotId:   snapshotId,
		ProcessId:    module.id,
		State:        module.st,
		LocalClock:   module.lcl,
		RequestTs:    module.reqTs,
		NumResponses: module.nbrResps,
		Waiting:      make([]bool, len(module.waiting)),
		Addresses:    module.addresses,
		Timestamp:    time.Now().UnixNano(),
	}

	// Copia o array waiting
	copy(state.Waiting, module.waiting)

	// Salva em arquivo
	filename := fmt.Sprintf("logs/snapshot_%d_process_%d.json", snapshotId, module.id)
	file, err := os.Create(filename)
	if err != nil {
		module.outDbg(fmt.Sprintf("Erro ao criar arquivo de snapshot: %v", err))
		return
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	err = encoder.Encode(state)
	if err != nil {
		module.outDbg(fmt.Sprintf("Erro ao salvar snapshot: %v", err))
		return
	}

	module.outDbg(fmt.Sprintf("Snapshot %d salvo em %s", snapshotId, filename))
}

// ------------------------------------------------------------------------------------
// ------- funcoes de ajuda
// ------------------------------------------------------------------------------------

func (module *DIMEX_Module) sendToLink(address string, content string, space string) {
	module.outDbg(space + " ---->>>>   to: " + address + "     msg: " + content)
	module.Pp2plink.Req <- PP2PLink.PP2PLink_Req_Message{
		To:      address,
		Message: content,
	}
}

func before(oneId, oneTs, othId, othTs int) bool {
	if oneTs < othTs {
		return true
	} else if oneTs > othTs {
		return false
	} else {
		return oneId < othId
	}
}

func (module *DIMEX_Module) outDbg(s string) {
	if module.dbg {
		fmt.Println(". . . . . . . . . . . . [ DIMEX : " + s + " ]")
	}
}

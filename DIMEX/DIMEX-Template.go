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
// DIMEX-Template.go (Versão Refatorada)
package DIMEX

import (
	PP2PLink "SD/PP2PLink"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"sync"
	"time"
)

// ------------------------------------------------------------------------------------
// ------- principais tipos
// ------------------------------------------------------------------------------------

// --- ENUMS E TIPOS DE ESTADO ---
type State int

const (
	RELEASED State = iota
	WANTED
	HELD
)

type dmxReq int

const (
	ENTER dmxReq = iota
	EXIT
)

type dmxResp struct{}

// --- ESTRUTURAS PARA MENSAGENS JSON ---
// Esta é a estrutura "envelope" para todas as mensagens.
type Message struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"` // Payload flexível
}

// Payloads específicos para cada tipo de mensagem
type ReqEntryPayload struct {
	Timestamp int `json:"timestamp"`
	SenderId  int `json:"senderId"`
}
type RespOkPayload struct {
	SenderId int `json:"senderId"`
}
type MarkerPayload struct {
	SnapshotId  int `json:"snapshotId"`
	InitiatorId int `json:"initiatorId"`
}

// --- ESTRUTURAS PARA SNAPSHOT ---
type DIMEX_State struct {
	St       State  `json:"state"`
	Waiting  []bool `json:"waiting"`
	Lcl      int    `json:"logical_clock"`
	ReqTs    int    `json:"request_timestamp"`
	NbrResps int    `json:"responses_count"`
}

// N: estrutura para estado do processo em snapshot
type ProcessSnapshot struct {
	SnapshotId    int               `json:"snapshot_id"`
	ProcessId     int               `json:"process_id"`
	LocalState    DIMEX_State       `json:"local_state"`
	ChannelStates map[int][]Message `json:"channel_states"` // Key: ID do remetente
}

// --- ESTRUTURAS PARA LOGGING DE SNAPSHOTS ---
type SnapshotLogEntry struct {
	Timestamp   time.Time `json:"timestamp"`
	ProcessId   int       `json:"process_id"`
	SnapshotId  int       `json:"snapshot_id"`
	EventType   string    `json:"event_type"` // "initiated", "marker_received", "marker_sent", "local_state_recorded", "channel_closed", "completed"
	Description string    `json:"description"`
	Details     string    `json:"details,omitempty"`
}

type SnapshotLog struct {
	SnapshotId int                `json:"snapshot_id"`
	ProcessId  int                `json:"process_id"`
	StartTime  time.Time          `json:"start_time"`
	EndTime    *time.Time         `json:"end_time,omitempty"`
	Entries    []SnapshotLogEntry `json:"entries"`
	Status     string             `json:"status"` // "in_progress", "completed", "failed"
}

// --- MÓDULO PRINCIPAL ---
type DIMEX_Module struct {
	Req       chan dmxReq
	Ind       chan dmxResp
	Pp2plink  *PP2PLink.PP2PLink
	addresses []string
	id        int
	st        State
	waiting   []bool
	lcl       int
	reqTs     int
	nbrResps  int
	dbg       bool

	// N: campos para snapshot (chandy-lamport)
	snapshotsLock sync.Mutex
	isRecording   map[int]bool             // [snapshotId] -> bool
	channelRec    map[int]map[int]bool     // [snapshotId][channelId] -> bool
	snapshots     map[int]*ProcessSnapshot // [snapshotId] -> snapshot data

	// N: campos para logging de snapshots
	snapshotLogs map[int]*SnapshotLog // [snapshotId] -> log data
	logsLock     sync.Mutex
}

// ------------------------------------------------------------------------------------
// ------- inicializacao
// ------------------------------------------------------------------------------------

func NewDIMEX(_addresses []string, _id int, _dbg bool) *DIMEX_Module {
	p2p := &PP2PLink.PP2PLink{
		Ind:   make(chan PP2PLink.PP2PLink_Ind_Message, 1),
		Req:   make(chan PP2PLink.PP2PLink_Req_Message, 1),
		Run:   false,
		Cache: make(map[string]net.Conn),
	}
	p2p.Init(_addresses[_id])

	dmx := &DIMEX_Module{
		Req:          make(chan dmxReq, 1),
		Ind:          make(chan dmxResp, 1),
		Pp2plink:     p2p,
		addresses:    _addresses,
		id:           _id,
		st:           RELEASED,
		waiting:      make([]bool, len(_addresses)),
		dbg:          _dbg,
		isRecording:  make(map[int]bool),
		channelRec:   make(map[int]map[int]bool),
		snapshots:    make(map[int]*ProcessSnapshot),
		snapshotLogs: make(map[int]*SnapshotLog),
	}
	dmx.Start()
	dmx.outDbg("Módulo DIMEX inicializado.")
	return dmx
}

// ------------------------------------------------------------------------------------
// ------- nucleo do funcionamento
// ------------------------------------------------------------------------------------

func (module *DIMEX_Module) Start() {
	go func() {
		for {
			select {
			case dmxR := <-module.Req:
				if dmxR == ENTER {
					module.outDbg("Aplicacao pediu para ENTRAR na SC.")
					module.handleUponReqEntry()
				} else if dmxR == EXIT {
					module.outDbg("Aplicacao pediu para SAIR da SC.")
					module.handleUponReqExit()
				}

			case msgOutro := <-module.Pp2plink.Ind:
				// Decodifica a mensagem "envelope" primeiro
				var msg Message
				if err := json.Unmarshal([]byte(msgOutro.Message.Value), &msg); err != nil {
					module.outDbg(fmt.Sprintf("ERRO: Mensagem JSON malformada de %s: %v", msgOutro.From, err))
					continue
				}

				// Lógica de gravação do snapshot (intercepta ANTES de processar)
				module.handleSnapshotRecording(msgOutro.From, msg)

				// Roteia a mensagem com base no seu tipo
				switch msg.Type {
				case "reqEntry":
					var payload ReqEntryPayload
					if err := json.Unmarshal(msg.Payload, &payload); err != nil {
						module.outDbg(fmt.Sprintf("ERRO: Payload 'reqEntry' malformado: %v", err))
						continue
					}
					module.outDbg(fmt.Sprintf("Recebeu REQ de P%d com TS %d", payload.SenderId, payload.Timestamp))
					module.handleUponDeliverReqEntry(payload)
				case "respOk":
					var payload RespOkPayload
					if err := json.Unmarshal(msg.Payload, &payload); err != nil {
						module.outDbg(fmt.Sprintf("ERRO: Payload 'respOk' malformado: %v", err))
						continue
					}
					module.outDbg(fmt.Sprintf("Recebeu RESP de P%d", payload.SenderId))
					module.handleUponDeliverRespOk(payload)
				case "snapshotMarker":
					var payload MarkerPayload
					if err := json.Unmarshal(msg.Payload, &payload); err != nil {
						module.outDbg(fmt.Sprintf("ERRO: Payload 'snapshotMarker' malformado: %v", err))
						continue
					}
					module.outDbg(fmt.Sprintf("Recebeu MARKER para Snap %d do iniciador P%d", payload.SnapshotId, payload.InitiatorId))
					module.handleSnapshotMarker(payload, msgOutro.From)
				}
			}
		}
	}()
}

// ------------------------------------------------------------------------------------

// --- LÓGICA DO ALGORITMO RICART-AGRAWALA ---
// ------- tratamento de pedidos vindos da aplicacao
// ------- UPON ENTRY
// ------- UPON EXIT
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
	module.st = WANTED        // estado := queroSC
	module.lcl++              // lts.ts++ -> incrementa relógio lógico local
	module.reqTs = module.lcl // myTs := lts -> timestamp requisição local
	module.nbrResps = 0       // resps := 0 -> contador de respostas zerado

	// para todo processo p
	payload := ReqEntryPayload{
		Timestamp: module.reqTs,
		SenderId:  module.id,
	}
	module.broadcastMessage("reqEntry", payload)                                 // trigger [ pl , Send | [ reqEntry, r, myTs ]
	module.outDbg(fmt.Sprintf("Enviou REQ para todos com TS %d.", module.reqTs)) // log
}

func (module *DIMEX_Module) handleUponReqExit() {
	/*
						upon event [ dmx, Exit  |  r  ]  do
		       				para todo [p, r, ts ] em waiting
		          				trigger [ pl, Send | p , [ respOk, r ]  ]
		    				estado := naoQueroSC
							waiting := {}
	*/

	module.st = RELEASED // estado := naoQueroSC
	// para todo [p, r, ts ] em waiting
	for i, isWaiting := range module.waiting {
		if isWaiting {
			payload := RespOkPayload{SenderId: module.id}                   // trigger [ pl, Send | p , [ respOk, r ]  ]
			module.sendMessageTo(i, "respOk", payload)                      // envia resposta de saida para p
			module.outDbg(fmt.Sprintf("Enviou RESP de saida para P%d.", i)) // log
		}
	}
	// Limpa a fila de espera
	module.waiting = make([]bool, len(module.addresses))
}

// ------------------------------------------------------------------------------------
// ------- tratamento de mensagens de outros processos
// ------- UPON respOK
// ------- UPON reqEntry

func (module *DIMEX_Module) handleUponDeliverReqEntry(payload ReqEntryPayload) {
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
	// Regra de Lamport: atualize o relógio ANTES de qualquer decisão.
	module.lcl = max(module.lcl, payload.Timestamp) + 1

	// Lógica de decisão de Ricart-Agrawala
	shouldReply := module.st == RELEASED ||
		(module.st == WANTED && before(payload.Timestamp, payload.SenderId, module.reqTs, module.id))

	if shouldReply { // se deve responder
		respPayload := RespOkPayload{SenderId: module.id}                                    // trigger [ pl, Send | p , [ respOk, r ]  ]
		module.sendMessageTo(payload.SenderId, "respOk", respPayload)                        // envia resposta de saida para p
		module.outDbg(fmt.Sprintf("Respondeu OK imediatamente para P%d.", payload.SenderId)) // log
	} else {
		module.waiting[payload.SenderId] = true                                         // coloca p na fila de espera
		module.outDbg(fmt.Sprintf("P%d colocado na fila de espera.", payload.SenderId)) // log
	}
}

func (module *DIMEX_Module) handleUponDeliverRespOk(payload RespOkPayload) {
	/*
						upon event [ pl, Deliver | p, [ respOk, r ] ]
		      				resps++
		      				se resps = N
		    				então trigger [ dmx, Deliver | free2Access ]
		  					    estado := estouNaSC

	*/
	module.nbrResps++ // incrementa contador de respostas
	module.outDbg(fmt.Sprintf("Contador de respostas: %d/%d.", module.nbrResps, len(module.addresses)-1))
	if module.nbrResps == len(module.addresses)-1 {
		module.st = HELD
		module.Ind <- dmxResp{} // Sinaliza para a aplicação
		module.outDbg("PERMISSAO CONCEDIDA! Entrando na SC.")
	}
}

// ------------------------------------------------------------------------------------

// --- LÓGICA DO ALGORITMO CHANDY-LAMPORT ---

func (module *DIMEX_Module) InitiateSnapshot(snapshotId int) {
	module.snapshotsLock.Lock()
	defer module.snapshotsLock.Unlock()

	// Garante que não inicie o mesmo snapshot duas vezes
	if _, exists := module.isRecording[snapshotId]; exists {
		return
	}

	module.outDbg(fmt.Sprintf("INICIANDO Snapshot %d.", snapshotId))

	// Log do início do snapshot
	module.logSnapshotEvent(snapshotId, "initiated",
		fmt.Sprintf("Processo %d iniciou snapshot %d", module.id, snapshotId),
		fmt.Sprintf("Estado atual: %v, Relógio: %d", module.st, module.lcl))

	module.recordLocalState(snapshotId)

	markerPayload := MarkerPayload{
		SnapshotId:  snapshotId,
		InitiatorId: module.id,
	}
	module.broadcastMessage("snapshotMarker", markerPayload)

	// Log do envio de markers
	module.logSnapshotEvent(snapshotId, "marker_sent",
		"Markers enviados para todos os processos",
		fmt.Sprintf("Total de processos: %d", len(module.addresses)-1))
}

func (module *DIMEX_Module) recordLocalState(snapshotId int) {
	module.isRecording[snapshotId] = true // marca o snapshot como sendo gravado

	// Prepara para gravar todos os canais de entrada
	module.channelRec[snapshotId] = make(map[int]bool) // inicializa o mapa de canais
	for i := range module.addresses {
		if i != module.id {
			module.channelRec[snapshotId][i] = true // marca o canal como sendo gravado
		}
	}

	// Copia o estado atual para o snapshot
	waitingCopy := make([]bool, len(module.waiting)) // cria uma cópia do array de espera
	copy(waitingCopy, module.waiting)                // copia o array de espera para a cópia

	module.snapshots[snapshotId] = &ProcessSnapshot{
		SnapshotId: snapshotId, // id do snapshot
		ProcessId:  module.id,  // id do processo
		LocalState: DIMEX_State{
			St:       module.st, // estado do processo
			Waiting:  waitingCopy,
			Lcl:      module.lcl,      // relógio lógico local
			ReqTs:    module.reqTs,    // timestamp da requisição
			NbrResps: module.nbrResps, // contador de respostas
		},
		ChannelStates: make(map[int][]Message),
	}
	module.outDbg(fmt.Sprintf("Estado local gravado para Snapshot %d.", snapshotId))

	// Log da gravação do estado local
	module.logSnapshotEvent(snapshotId, "local_state_recorded",
		"Estado local capturado com sucesso",
		fmt.Sprintf("Estado: %v, Relógio: %d, ReqTs: %d, Respostas: %d",
			module.st, module.lcl, module.reqTs, module.nbrResps))

	// Inicia um timeout para forçar a conclusão do snapshot após 5 segundos
	go func() {
		time.Sleep(5 * time.Second)
		module.snapshotsLock.Lock()
		defer module.snapshotsLock.Unlock()

		if module.isRecording[snapshotId] && !module.isSnapshotComplete(snapshotId) {
			// Força o fechamento de todos os canais
			for channelId := range module.channelRec[snapshotId] {
				module.channelRec[snapshotId][channelId] = false
			}

			module.outDbg(fmt.Sprintf("TIMEOUT: Forçando conclusão do Snapshot %d", snapshotId))
			module.logSnapshotEvent(snapshotId, "timeout_completed",
				"Snapshot finalizado por timeout",
				"Todos os canais foram forçadamente fechados")
			module.updateSnapshotStatus(snapshotId, "completed")
			module.SaveSnapshotToFile(snapshotId)
		}
	}()
}

func (module *DIMEX_Module) handleSnapshotMarker(payload MarkerPayload, fromAddress string) {
	module.snapshotsLock.Lock()
	defer module.snapshotsLock.Unlock()

	snapshotId := payload.SnapshotId
	fromId := module.findIdByAddress(fromAddress)

	// Se não conseguir encontrar o ID pelo endereço, é porque é uma mensagem de snapshot marker
	// que pode vir do iniciador ou de qualquer processo que está repassando
	if fromId == -1 {
		// Para markers de snapshot, vamos assumir que veio do processo iniciador
		// ou criar uma lógica mais robusta baseada no contexto
		module.outDbg(fmt.Sprintf("Endereço %s não encontrado, assumindo como processo externo", fromAddress))
		return // Ignora markers de processos não identificados
	}

	if !module.isRecording[snapshotId] {
		// Primeira vez que vemos este marcador: grava estado e repassa
		module.outDbg(fmt.Sprintf("Primeiro MARKER recebido para Snap %d.", snapshotId))

		// Log do recebimento do primeiro marker
		module.logSnapshotEvent(snapshotId, "marker_received",
			fmt.Sprintf("Primeiro marker recebido de P%d", fromId),
			fmt.Sprintf("Iniciador: P%d", payload.InitiatorId))

		module.recordLocalState(snapshotId)
		// O canal do remetente é considerado vazio
		module.channelRec[snapshotId][fromId] = false

		// Repassa o marcador para todos
		markerPayload := MarkerPayload{SnapshotId: snapshotId, InitiatorId: payload.InitiatorId}
		module.broadcastMessage("snapshotMarker", markerPayload)

		// Log do reenvio de markers
		module.logSnapshotEvent(snapshotId, "marker_sent",
			"Markers reenviados para outros processos", "")
	} else {
		// Já está gravando, apenas fecha o canal do remetente
		module.channelRec[snapshotId][fromId] = false
		module.outDbg(fmt.Sprintf("Canal de P%d fechado para Snap %d.", fromId, snapshotId))

		// Log do fechamento do canal
		module.logSnapshotEvent(snapshotId, "channel_closed",
			fmt.Sprintf("Canal de P%d fechado", fromId), "")
	}

	// Verifica se o snapshot local terminou para poder salvar
	if module.isSnapshotComplete(snapshotId) {
		// Log da conclusão do snapshot
		module.logSnapshotEvent(snapshotId, "completed",
			"Snapshot completado com sucesso",
			"Todos os canais foram fechados")
		module.updateSnapshotStatus(snapshotId, "completed")
		module.SaveSnapshotToFile(snapshotId)
	}
}

func (module *DIMEX_Module) handleSnapshotRecording(fromAddress string, msg Message) {
	module.snapshotsLock.Lock()
	defer module.snapshotsLock.Unlock()

	// Tenta extrair o senderId da mensagem ao invés de usar endereço
	var fromId int = -1

	// Verifica se a mensagem tem um payload com senderId
	switch msg.Type {
	case "reqEntry":
		var payload ReqEntryPayload
		if err := json.Unmarshal(msg.Payload, &payload); err == nil {
			fromId = payload.SenderId
		}
	case "respOk":
		var payload RespOkPayload
		if err := json.Unmarshal(msg.Payload, &payload); err == nil {
			fromId = payload.SenderId
		}
	}

	// Se ainda não conseguiu, tenta pelo endereço
	if fromId == -1 {
		fromId = module.findIdByAddress(fromAddress)
	}

	if fromId == -1 {
		return // Não conseguiu identificar o remetente
	}

	// Para cada snapshot em andamento, verifica se este canal está sendo gravado
	for snapId, isRec := range module.isRecording {
		if isRec {
			if shouldRecord, ok := module.channelRec[snapId][fromId]; ok && shouldRecord {
				if snapshot, exists := module.snapshots[snapId]; exists {
					snapshot.ChannelStates[fromId] = append(snapshot.ChannelStates[fromId], msg)
					module.outDbg(fmt.Sprintf("Mensagem de P%d gravada no canal para Snap %d", fromId, snapId))

					// Log da gravação de mensagem no canal
					module.logSnapshotEvent(snapId, "message_recorded",
						fmt.Sprintf("Mensagem de P%d gravada no canal", fromId),
						fmt.Sprintf("Tipo: %s", msg.Type))
				}
			}
		}
	}
}

// --- FUNÇÕES AUXILIARES ---

// Você precisa implementar este gatilho em useDIMEX.go
func (module *DIMEX_Module) StartSnapshotting(interval time.Duration) {
	if module.id == 0 { // Apenas o processo 0 inicia snapshots
		go func() {
			snapshotId := 1
			ticker := time.NewTicker(interval)
			defer ticker.Stop()
			for {
				<-ticker.C
				module.InitiateSnapshot(snapshotId)
				snapshotId++
			}
		}()
	}
}

func (module *DIMEX_Module) isSnapshotComplete(snapshotId int) bool {
	// Um snapshot está completo se o estado foi gravado e todos os canais foram fechados
	if !module.isRecording[snapshotId] {
		return false
	}

	// Verifica se todos os canais válidos foram fechados
	channelMap, exists := module.channelRec[snapshotId]
	if !exists {
		return true // Se não há canais para gravar, está completo
	}

	for channelId, isRecordingChannel := range channelMap {
		// Só considera canais válidos (IDs >= 0 e diferentes do próprio processo)
		if channelId >= 0 && channelId < len(module.addresses) && channelId != module.id && isRecordingChannel {
			return false // Ainda há um canal válido aberto
		}
	}
	return true
}

func (module *DIMEX_Module) SaveSnapshotToFile(snapshotId int) {
	snapshot, ok := module.snapshots[snapshotId]
	if !ok {
		return
	}
	// Cria o diretório 'snapshots' se não existir
	if _, err := os.Stat("snapshots"); os.IsNotExist(err) {
		os.Mkdir("snapshots", 0755)
	}
	fileName := fmt.Sprintf("snapshots/snapshot_%d_proc_%d.json", snapshotId, module.id)
	file, err := os.Create(fileName)
	if err != nil {
		module.outDbg(fmt.Sprintf("ERRO ao criar arquivo de snapshot: %v", err))
		return
	}
	defer file.Close()
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(snapshot); err != nil {
		module.outDbg(fmt.Sprintf("ERRO ao salvar snapshot em JSON: %v", err))
	}
	module.outDbg(fmt.Sprintf("Snapshot %d salvo em %s", snapshotId, fileName))
}

func (module *DIMEX_Module) sendMessageTo(destId int, msgType string, payload interface{}) {
	msgPayloadBytes, err := json.Marshal(payload)
	if err != nil {
		module.outDbg(fmt.Sprintf("ERRO ao fazer marshal do payload: %v", err))
		return
	}
	msg := Message{Type: msgType, Payload: msgPayloadBytes}
	msgBytes, err := json.Marshal(msg)
	if err != nil {
		module.outDbg(fmt.Sprintf("ERRO ao fazer marshal da mensagem: %v", err))
		return
	}

	destAddr := module.addresses[destId]
	module.Pp2plink.Req <- PP2PLink.PP2PLink_Req_Message{
		To:      destAddr,
		Message: PP2PLink.PP2LinkMessage{Value: string(msgBytes)},
	}
}

func (module *DIMEX_Module) broadcastMessage(msgType string, payload interface{}) {
	for i := range module.addresses {
		if i != module.id {
			module.sendMessageTo(i, msgType, payload)
		}
	}
}

func (module *DIMEX_Module) findIdByAddress(addr string) int {
	for i, a := range module.addresses {
		if a == addr {
			return i
		}
	}
	return -1 // Não encontrado
}

func (module *DIMEX_Module) outDbg(s string) {
	if module.dbg {
		// Log estruturado: [Timestamp] [Processo] [Relógio Lógico] Mensagem
		fmt.Printf("%s [P%d][C%d] %s\n", time.Now().Format("15:04:05.000"), module.id, module.lcl, s)
	}
}

func before(ts1, id1, ts2, id2 int) bool {
	if ts1 < ts2 {
		return true
	}
	if ts1 == ts2 && id1 < id2 {
		return true
	}
	return false
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// ------------------------------------------------------------------------------------
// ------- SISTEMA DE LOGGING PARA SNAPSHOTS
// ------------------------------------------------------------------------------------

// logSnapshotEvent registra um evento de snapshot no log
func (module *DIMEX_Module) logSnapshotEvent(snapshotId int, eventType, description, details string) {
	module.logsLock.Lock()
	defer module.logsLock.Unlock()

	// Cria o log do snapshot se não existir
	if _, exists := module.snapshotLogs[snapshotId]; !exists {
		module.snapshotLogs[snapshotId] = &SnapshotLog{
			SnapshotId: snapshotId,
			ProcessId:  module.id,
			StartTime:  time.Now(),
			Entries:    make([]SnapshotLogEntry, 0),
			Status:     "in_progress",
		}
	}

	// Adiciona a entrada do evento
	entry := SnapshotLogEntry{
		Timestamp:   time.Now(),
		ProcessId:   module.id,
		SnapshotId:  snapshotId,
		EventType:   eventType,
		Description: description,
		Details:     details,
	}

	module.snapshotLogs[snapshotId].Entries = append(module.snapshotLogs[snapshotId].Entries, entry)

	// Log simples no console também
	module.outDbg(fmt.Sprintf("[SNAPSHOT LOG] %s: %s", eventType, description))
}

// updateSnapshotStatus atualiza o status do snapshot e salva o log se estiver completo
func (module *DIMEX_Module) updateSnapshotStatus(snapshotId int, status string) {
	module.logsLock.Lock()
	defer module.logsLock.Unlock()

	if log, exists := module.snapshotLogs[snapshotId]; exists {
		log.Status = status
		if status == "completed" || status == "failed" {
			now := time.Now()
			log.EndTime = &now
			// Salva o log quando o snapshot termina
			go module.saveSnapshotLog(snapshotId)
		}
	}
}

// saveSnapshotLog salva o log do snapshot em um arquivo JSON na pasta logs/
func (module *DIMEX_Module) saveSnapshotLog(snapshotId int) {
	module.logsLock.Lock()
	log, exists := module.snapshotLogs[snapshotId]
	if !exists {
		module.logsLock.Unlock()
		return
	}
	// Faz uma cópia para evitar problemas de concorrência
	logCopy := *log
	logCopy.Entries = make([]SnapshotLogEntry, len(log.Entries))
	copy(logCopy.Entries, log.Entries)
	module.logsLock.Unlock()

	// Cria o diretório 'logs' se não existir
	if _, err := os.Stat("logs"); os.IsNotExist(err) {
		os.Mkdir("logs", 0755)
	}

	fileName := fmt.Sprintf("logs/snapshot_log_%d_proc_%d.json", snapshotId, module.id)
	file, err := os.Create(fileName)
	if err != nil {
		module.outDbg(fmt.Sprintf("ERRO ao criar arquivo de log de snapshot: %v", err))
		return
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(&logCopy); err != nil {
		module.outDbg(fmt.Sprintf("ERRO ao salvar log de snapshot em JSON: %v", err))
	} else {
		module.outDbg(fmt.Sprintf("Log do Snapshot %d salvo em %s", snapshotId, fileName))
	}
}

// getSnapshotLogSummary retorna um resumo do log do snapshot
func (module *DIMEX_Module) getSnapshotLogSummary(snapshotId int) string {
	module.logsLock.Lock()
	defer module.logsLock.Unlock()

	log, exists := module.snapshotLogs[snapshotId]
	if !exists {
		return fmt.Sprintf("Log do Snapshot %d não encontrado", snapshotId)
	}

	duration := "Em andamento"
	if log.EndTime != nil {
		duration = log.EndTime.Sub(log.StartTime).String()
	}

	return fmt.Sprintf("Snapshot %d - Status: %s, Eventos: %d, Duração: %s",
		snapshotId, log.Status, len(log.Entries), duration)
}

// printAllSnapshotLogs imprime um resumo de todos os logs de snapshot
func (module *DIMEX_Module) printAllSnapshotLogs() {
	module.logsLock.Lock()
	defer module.logsLock.Unlock()

	if len(module.snapshotLogs) == 0 {
		module.outDbg("Nenhum log de snapshot encontrado")
		return
	}

	module.outDbg("=== RESUMO DOS LOGS DE SNAPSHOT ===")
	for snapshotId := range module.snapshotLogs {
		summary := module.getSnapshotLogSummary(snapshotId)
		module.outDbg(summary)
	}
	module.outDbg("==================================")
}

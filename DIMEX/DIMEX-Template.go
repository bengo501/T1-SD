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

type ProcessSnapshot struct {
	SnapshotId    int               `json:"snapshot_id"`
	ProcessId     int               `json:"process_id"`
	LocalState    DIMEX_State       `json:"local_state"`
	ChannelStates map[int][]Message `json:"channel_states"` // Key: ID do remetente
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

	// Campos para o Snapshot
	snapshotsLock sync.Mutex
	isRecording   map[int]bool             // [snapshotId] -> bool
	channelRec    map[int]map[int]bool     // [snapshotId][channelId] -> bool
	snapshots     map[int]*ProcessSnapshot // [snapshotId] -> snapshot data
}

func NewDIMEX(_addresses []string, _id int, _dbg bool) *DIMEX_Module {
	p2p := &PP2PLink.PP2PLink{
		Ind:   make(chan PP2PLink.PP2PLink_Ind_Message, 1),
		Req:   make(chan PP2PLink.PP2PLink_Req_Message, 1),
		Run:   false,
		Cache: make(map[string]net.Conn),
	}
	p2p.Init(_addresses[_id])

	dmx := &DIMEX_Module{
		Req:         make(chan dmxReq, 1),
		Ind:         make(chan dmxResp, 1),
		Pp2plink:    p2p,
		addresses:   _addresses,
		id:          _id,
		st:          RELEASED,
		waiting:     make([]bool, len(_addresses)),
		dbg:         _dbg,
		isRecording: make(map[int]bool),
		channelRec:  make(map[int]map[int]bool),
		snapshots:   make(map[int]*ProcessSnapshot),
	}
	dmx.Start()
	dmx.outDbg("Módulo DIMEX inicializado.")
	return dmx
}

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

// --- LÓGICA DO ALGORITMO RICART-AGRAWALA ---

func (module *DIMEX_Module) handleUponReqEntry() {
	module.st = WANTED
	module.lcl++
	module.reqTs = module.lcl
	module.nbrResps = 0

	payload := ReqEntryPayload{
		Timestamp: module.reqTs,
		SenderId:  module.id,
	}
	module.broadcastMessage("reqEntry", payload)
	module.outDbg(fmt.Sprintf("Enviou REQ para todos com TS %d.", module.reqTs))
}

func (module *DIMEX_Module) handleUponReqExit() {
	module.st = RELEASED
	for i, isWaiting := range module.waiting {
		if isWaiting {
			payload := RespOkPayload{SenderId: module.id}
			module.sendMessageTo(i, "respOk", payload)
			module.outDbg(fmt.Sprintf("Enviou RESP de saída para P%d.", i))
		}
	}
	// Limpa a fila de espera
	module.waiting = make([]bool, len(module.addresses))
}

func (module *DIMEX_Module) handleUponDeliverReqEntry(payload ReqEntryPayload) {
	// Regra de Lamport: atualize o relógio ANTES de qualquer decisão.
	module.lcl = max(module.lcl, payload.Timestamp) + 1

	// Lógica de decisão de Ricart-Agrawala
	shouldReply := module.st == RELEASED ||
		(module.st == WANTED && before(payload.Timestamp, payload.SenderId, module.reqTs, module.id))

	if shouldReply {
		respPayload := RespOkPayload{SenderId: module.id}
		module.sendMessageTo(payload.SenderId, "respOk", respPayload)
		module.outDbg(fmt.Sprintf("Respondeu OK imediatamente para P%d.", payload.SenderId))
	} else {
		module.waiting[payload.SenderId] = true
		module.outDbg(fmt.Sprintf("P%d colocado na fila de espera.", payload.SenderId))
	}
}

func (module *DIMEX_Module) handleUponDeliverRespOk(payload RespOkPayload) {
	module.nbrResps++
	module.outDbg(fmt.Sprintf("Contador de respostas: %d/%d.", module.nbrResps, len(module.addresses)-1))
	if module.nbrResps == len(module.addresses)-1 {
		module.st = HELD
		module.Ind <- dmxResp{} // Sinaliza para a aplicação
		module.outDbg("PERMISSAO CONCEDIDA! Entrando na SC.")
	}
}

// --- LÓGICA DO ALGORITMO CHANDY-LAMPORT ---

func (module *DIMEX_Module) InitiateSnapshot(snapshotId int) {
	module.snapshotsLock.Lock()
	defer module.snapshotsLock.Unlock()

	// Garante que não inicie o mesmo snapshot duas vezes
	if _, exists := module.isRecording[snapshotId]; exists {
		return
	}

	module.outDbg(fmt.Sprintf("INICIANDO Snapshot %d.", snapshotId))
	module.recordLocalState(snapshotId)

	markerPayload := MarkerPayload{
		SnapshotId:  snapshotId,
		InitiatorId: module.id,
	}
	module.broadcastMessage("snapshotMarker", markerPayload)
}

func (module *DIMEX_Module) recordLocalState(snapshotId int) {
	module.isRecording[snapshotId] = true

	// Prepara para gravar todos os canais de entrada
	module.channelRec[snapshotId] = make(map[int]bool)
	for i := range module.addresses {
		if i != module.id {
			module.channelRec[snapshotId][i] = true
		}
	}

	// Copia o estado atual para o snapshot
	waitingCopy := make([]bool, len(module.waiting))
	copy(waitingCopy, module.waiting)

	module.snapshots[snapshotId] = &ProcessSnapshot{
		SnapshotId: snapshotId,
		ProcessId:  module.id,
		LocalState: DIMEX_State{
			St:       module.st,
			Waiting:  waitingCopy,
			Lcl:      module.lcl,
			ReqTs:    module.reqTs,
			NbrResps: module.nbrResps,
		},
		ChannelStates: make(map[int][]Message),
	}
	module.outDbg(fmt.Sprintf("Estado local gravado para Snapshot %d.", snapshotId))
}

func (module *DIMEX_Module) handleSnapshotMarker(payload MarkerPayload, fromAddress string) {
	module.snapshotsLock.Lock()
	defer module.snapshotsLock.Unlock()

	snapshotId := payload.SnapshotId
	fromId := module.findIdByAddress(fromAddress)

	if !module.isRecording[snapshotId] {
		// Primeira vez que vemos este marcador: grava estado e repassa
		module.outDbg(fmt.Sprintf("Primeiro MARKER recebido para Snap %d.", snapshotId))
		module.recordLocalState(snapshotId)
		// O canal do remetente é considerado vazio
		module.channelRec[snapshotId][fromId] = false

		// Repassa o marcador para todos
		markerPayload := MarkerPayload{SnapshotId: snapshotId, InitiatorId: payload.InitiatorId}
		module.broadcastMessage("snapshotMarker", markerPayload)
	} else {
		// Já está gravando, apenas fecha o canal do remetente
		module.channelRec[snapshotId][fromId] = false
		module.outDbg(fmt.Sprintf("Canal de P%d fechado para Snap %d.", fromId, snapshotId))
	}

	// Verifica se o snapshot local terminou para poder salvar
	if module.isSnapshotComplete(snapshotId) {
		module.SaveSnapshotToFile(snapshotId)
	}
}

func (module *DIMEX_Module) handleSnapshotRecording(fromAddress string, msg Message) {
	module.snapshotsLock.Lock()
	defer module.snapshotsLock.Unlock()

	fromId := module.findIdByAddress(fromAddress)
	if fromId == -1 {
		return
	}

	// Para cada snapshot em andamento, verifica se este canal está sendo gravado
	for snapId, isRec := range module.isRecording {
		if isRec {
			if shouldRecord, ok := module.channelRec[snapId][fromId]; ok && shouldRecord {
				if snapshot, exists := module.snapshots[snapId]; exists {
					snapshot.ChannelStates[fromId] = append(snapshot.ChannelStates[fromId], msg)
					module.outDbg(fmt.Sprintf("Mensagem de P%d gravada no canal para Snap %d", fromId, snapId))
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
	for _, isRecordingChannel := range module.channelRec[snapshotId] {
		if isRecordingChannel {
			return false // Ainda há um canal aberto
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

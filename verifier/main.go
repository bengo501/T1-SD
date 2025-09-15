// verifier/main.go
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"
)

// IMPORTANTE: Estas structs devem ser uma CÓPIA EXATA das structs
// de snapshot definidas no seu pacote DIMEX.
type State int

const (
	RELEASED State = iota
	WANTED
	HELD
)

type Message struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}
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
	ChannelStates map[int][]Message `json:"channel_states"`
}

// GlobalState representa o estado combinado de todos os processos em um snapshot.
type GlobalState struct {
	SnapshotId    int
	ProcessStates map[int]ProcessSnapshot // Key: ProcessId
	NumProcesses  int
}

func main() {
	// 1. Validar e obter os argumentos da linha de comando
	if len(os.Args) != 3 {
		fmt.Println("Uso: go run main.go <snapshot_id> <numero_total_de_processos>")
		return
	}
	snapshotId, err := strconv.Atoi(os.Args[1])
	if err != nil {
		fmt.Printf("Erro: snapshot_id inválido: %v\n", err)
		return
	}
	numProcesses, err := strconv.Atoi(os.Args[2])
	if err != nil {
		fmt.Printf("Erro: numero_total_de_processos inválido: %v\n", err)
		return
	}

	fmt.Printf("Analisando Snapshot %d com %d processos...\n", snapshotId, numProcesses)

	// 2. Carregar todos os arquivos de snapshot para montar o estado global
	globalState := GlobalState{
		SnapshotId:    snapshotId,
		ProcessStates: make(map[int]ProcessSnapshot),
		NumProcesses:  numProcesses,
	}

	for i := 0; i < numProcesses; i++ {
		fileName := fmt.Sprintf("../snapshots/snapshot_%d_proc_%d.json", snapshotId, i)
		file, err := os.ReadFile(fileName)
		if err != nil {
			fmt.Printf("Erro ao ler o arquivo %s: %v\n", fileName, err)
			return
		}

		var ps ProcessSnapshot
		if err := json.Unmarshal(file, &ps); err != nil {
			fmt.Printf("Erro ao decodificar o JSON do arquivo %s: %v\n", fileName, err)
			return
		}
		globalState.ProcessStates[i] = ps
	}

	if len(globalState.ProcessStates) != numProcesses {
		fmt.Println("Erro: Nem todos os arquivos de snapshot foram carregados.")
		return
	}

	// 3. Executar as verificações das invariantes
	fmt.Println("\n--- Verificando Invariantes ---")

	// Invariante 1: No máximo um processo na Seção Crítica
	if checkInvariant1_AtMostOneInMX(globalState) {
		fmt.Println("[OK] Invariante 1: No maximo um processo está na SC.")
	} else {
		fmt.Println("[FALHOU] Invariante 1: Mais de um processo foi encontrado na SC!")
	}

	// Invariante 4: Conservação de Respostas
	if checkInvariant4_ConservationOfReplies(globalState) {
		fmt.Println("[OK] Invariante 4: A contagem de respostas está consistente.")
	} else {
		fmt.Println("[FALHOU] Invariante 4: Inconsistência na contagem de respostas para um processo em 'WANTED'.")
	}

	// Adicione chamadas para outras invariantes que você criar aqui...
}

// SUA TAREFA É IMPLEMENTAR A LÓGICA DESTAS FUNÇÕES

func checkInvariant1_AtMostOneInMX(gs GlobalState) bool {
	// DICA: Itere sobre `gs.ProcessStates`. Conte quantos processos têm `LocalState.St == HELD`.
	// Se a contagem for > 1, retorne `false`.
	// ... sua lógica aqui ...
	return true
}

func checkInvariant4_ConservationOfReplies(gs GlobalState) bool {
	// Esta é a mais complexa.
	// Para cada processo `p` em `gs.ProcessStates`:
	//   Se `p.LocalState.St == WANTED`:
	//     1. Inicie um contador `totalPermissions = p.LocalState.NbrResps`.
	//     2. Itere sobre todos os outros processos `q`:
	//        a. Verifique se há uma mensagem `respOk` de `q` para `p` "em trânsito"
	//           (no `ChannelStates` de `p` vindo de `q`). Se sim, incremente o contador.
	//        b. Verifique se `p` está na fila de espera de `q` (`q.LocalState.Waiting[p.ProcessId] == true`).
	//           Se sim, incremente o contador.
	//     3. Ao final, verifique se `totalPermissions == gs.NumProcesses - 1`. Se for falso para qualquer
	//        processo `p` em `WANTED`, a invariante falhou. Retorne `false`.
	//
	// Se o loop terminar para todos os processos sem falhas, retorne `true`.
	// ... sua lógica aqui ...
	return true
}

package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

// Estruturas para análise de snapshots
type ProcessState struct {
	SnapshotId   int      `json:"snapshot_id"`
	ProcessId    int      `json:"process_id"`
	State        int      `json:"state"` // 0=noMX, 1=wantMX, 2=inMX
	LocalClock   int      `json:"local_clock"`
	RequestTs    int      `json:"request_timestamp"`
	NumResponses int      `json:"num_responses"`
	Waiting      []bool   `json:"waiting"`
	Addresses    []string `json:"addresses"`
	Timestamp    int64    `json:"timestamp"`
}

type SnapshotAnalysis struct {
	SnapshotId    int                  `json:"snapshot_id"`
	ProcessStates map[int]ProcessState `json:"process_states"`
	Violations    []string             `json:"violations"`
	IsValid       bool                 `json:"is_valid"`
}

// Constantes para estados
const (
	noMX   = 0
	wantMX = 1
	inMX   = 2
)

// Função principal de análise
func main() {
	fmt.Println("=== ANALISADOR DE SNAPSHOTS DIMEX ===")

	// Verifica se a pasta logs existe
	if _, err := os.Stat("logs"); os.IsNotExist(err) {
		fmt.Println("Erro: Pasta 'logs' não encontrada!")
		return
	}

	// Encontra todos os snapshots disponíveis
	snapshots := findAvailableSnapshots()
	if len(snapshots) == 0 {
		fmt.Println("Nenhum snapshot encontrado!")
		return
	}

	fmt.Printf("Encontrados %d snapshots únicos\n", len(snapshots))

	// Analisa cada snapshot
	results := make([]SnapshotAnalysis, 0)
	for _, snapshotId := range snapshots {
		analysis := analyzeSnapshot(snapshotId)
		results = append(results, analysis)

		// Exibe resultado
		if analysis.IsValid {
			fmt.Printf("✅ Snapshot %d: VÁLIDO\n", snapshotId)
		} else {
			fmt.Printf("❌ Snapshot %d: INVÁLIDO\n", snapshotId)
			for _, violation := range analysis.Violations {
				fmt.Printf("   - %s\n", violation)
			}
		}
	}

	// Estatísticas finais
	validCount := 0
	for _, result := range results {
		if result.IsValid {
			validCount++
		}
	}

	fmt.Printf("\n=== RESUMO ===\n")
	fmt.Printf("Total de snapshots: %d\n", len(results))
	fmt.Printf("Snapshots válidos: %d\n", validCount)
	fmt.Printf("Snapshots inválidos: %d\n", len(results)-validCount)
	fmt.Printf("Taxa de sucesso: %.2f%%\n", float64(validCount)/float64(len(results))*100)
}

// Encontra todos os snapshots disponíveis
func findAvailableSnapshots() []int {
	snapshots := make(map[int]bool)

	files, err := ioutil.ReadDir("logs")
	if err != nil {
		fmt.Printf("Erro ao ler pasta logs: %v\n", err)
		return []int{}
	}

	for _, file := range files {
		if strings.HasPrefix(file.Name(), "snapshot_") && strings.HasSuffix(file.Name(), ".json") {
			parts := strings.Split(file.Name(), "_")
			if len(parts) >= 3 {
				snapshotId, err := strconv.Atoi(parts[1])
				if err == nil {
					snapshots[snapshotId] = true
				}
			}
		}
	}

	// Converte para slice e ordena
	result := make([]int, 0, len(snapshots))
	for snapshotId := range snapshots {
		result = append(result, snapshotId)
	}
	sort.Ints(result)

	return result
}

// Analisa um snapshot específico
func analyzeSnapshot(snapshotId int) SnapshotAnalysis {
	analysis := SnapshotAnalysis{
		SnapshotId:    snapshotId,
		ProcessStates: make(map[int]ProcessState),
		Violations:    make([]string, 0),
		IsValid:       true,
	}

	// Carrega estados de todos os processos para este snapshot
	files, err := ioutil.ReadDir("logs")
	if err != nil {
		analysis.Violations = append(analysis.Violations, fmt.Sprintf("Erro ao ler pasta logs: %v", err))
		analysis.IsValid = false
		return analysis
	}

	for _, file := range files {
		if strings.HasPrefix(file.Name(), fmt.Sprintf("snapshot_%d_process_", snapshotId)) {
			filepath := filepath.Join("logs", file.Name())
			data, err := ioutil.ReadFile(filepath)
			if err != nil {
				analysis.Violations = append(analysis.Violations, fmt.Sprintf("Erro ao ler %s: %v", file.Name(), err))
				analysis.IsValid = false
				continue
			}

			var state ProcessState
			if err := json.Unmarshal(data, &state); err != nil {
				analysis.Violations = append(analysis.Violations, fmt.Sprintf("Erro ao decodificar %s: %v", file.Name(), err))
				analysis.IsValid = false
				continue
			}

			analysis.ProcessStates[state.ProcessId] = state
		}
	}

	// Verifica se temos pelo menos 2 processos para análise válida
	if len(analysis.ProcessStates) < 2 {
		analysis.Violations = append(analysis.Violations,
			fmt.Sprintf("Snapshot incompleto: apenas %d processos participaram (mínimo 2)", len(analysis.ProcessStates)))
		analysis.IsValid = false
		return analysis
	}

	// Verifica invariantes
	checkInvariant1(&analysis) // Máximo um processo na SC
	checkInvariant2(&analysis) // Se todos não querem SC, waiting deve ser false
	checkInvariant3(&analysis) // Se p está waiting em q, então q está na SC ou quer SC
	checkInvariant4(&analysis) // Soma de respostas + waiting deve ser N-1

	return analysis
}

// Invariante 1: No máximo um processo na SC
func checkInvariant1(analysis *SnapshotAnalysis) {
	processesInSC := 0
	for _, state := range analysis.ProcessStates {
		if state.State == inMX {
			processesInSC++
		}
	}

	if processesInSC > 1 {
		analysis.Violations = append(analysis.Violations,
			fmt.Sprintf("Inv1 violado: %d processos na seção crítica (máximo 1)", processesInSC))
		analysis.IsValid = false
	}
}

// Invariante 2: Se todos processos estão em "não quer a SC", então todos waiting devem ser false
func checkInvariant2(analysis *SnapshotAnalysis) {
	allNoMX := true
	for _, state := range analysis.ProcessStates {
		if state.State != noMX {
			allNoMX = false
			break
		}
	}

	if allNoMX {
		for _, state := range analysis.ProcessStates {
			for i, waiting := range state.Waiting {
				if waiting {
					analysis.Violations = append(analysis.Violations,
						fmt.Sprintf("Inv2 violado: processo %d está waiting em %d mas todos estão noMX",
							state.ProcessId, i))
					analysis.IsValid = false
				}
			}
		}
	}
}

// Invariante 3: Se um processo q está marcado como waiting em p, então p está na SC ou quer SC
func checkInvariant3(analysis *SnapshotAnalysis) {
	for _, state := range analysis.ProcessStates {
		for i, waiting := range state.Waiting {
			if waiting {
				// Verifica se o processo i está na SC ou quer SC
				if processState, exists := analysis.ProcessStates[i]; exists {
					if processState.State != inMX && processState.State != wantMX {
						analysis.Violations = append(analysis.Violations,
							fmt.Sprintf("Inv3 violado: processo %d está waiting em %d, mas %d não está na SC nem quer SC",
								state.ProcessId, i, i))
						analysis.IsValid = false
					}
				}
			}
		}
	}
}

// Invariante 4: Se um processo q quer a seção crítica, então o somatório de respostas + waiting deve ser N-1
func checkInvariant4(analysis *SnapshotAnalysis) {
	N := len(analysis.ProcessStates)

	for _, state := range analysis.ProcessStates {
		if state.State == wantMX {
			// Conta quantos processos estão waiting para este processo
			waitingCount := 0
			for _, otherState := range analysis.ProcessStates {
				if otherState.ProcessId != state.ProcessId && otherState.Waiting[state.ProcessId] {
					waitingCount++
				}
			}

			// Soma: respostas recebidas + processos waiting
			total := state.NumResponses + waitingCount

			if total != N-1 {
				analysis.Violations = append(analysis.Violations,
					fmt.Sprintf("Inv4 violado: processo %d quer SC, respostas=%d, waiting=%d, total=%d (esperado %d)",
						state.ProcessId, state.NumResponses, waitingCount, total, N-1))
				analysis.IsValid = false
			}
		}
	}
}

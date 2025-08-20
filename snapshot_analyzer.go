package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

type ProcessState struct {
	SnapshotID   int      `json:"snapshot_id"`
	ProcessID    int      `json:"process_id"`
	State        int      `json:"state"` // 0=noMX, 1=wantMX, 2=inMX
	LocalClock   int      `json:"local_clock"`
	RequestTs    int      `json:"request_timestamp"`
	NumResponses int      `json:"num_responses"`
	Waiting      []bool   `json:"waiting"`
	Addresses    []string `json:"addresses"`
	Timestamp    int64    `json:"timestamp"`
}

type SnapshotAnalysis struct {
	SnapshotID    int            `json:"snapshotId"`
	ProcessStates []ProcessState `json:"processStates"`
	IsValid       bool           `json:"isValid"`
	Violations    []string       `json:"violations"`
	FaultDetected bool           `json:"faultDetected"`
	FaultType     string         `json:"faultType"`
}

func main() {
	fmt.Println("=== ANALISADOR DE SNAPSHOTS - DETECÇÃO DE FALHAS ===")

	// Encontrar snapshots disponíveis
	snapshots := findAvailableSnapshots()
	if len(snapshots) == 0 {
		fmt.Println("❌ Nenhum snapshot encontrado!")
		return
	}

	fmt.Printf("📊 Encontrados %d snapshots únicos\n", len(snapshots))

	// Analisar cada snapshot
	var analyses []SnapshotAnalysis
	var totalViolations int
	var faultDetections int

	for _, snapshotID := range snapshots {
		analysis := analyzeSnapshot(snapshotID)
		analyses = append(analyses, analysis)

		if !analysis.IsValid {
			totalViolations++
		}
		if analysis.FaultDetected {
			faultDetections++
		}
	}

	// Gerar relatório detalhado
	generateDetailedReport(analyses, totalViolations, faultDetections)

	// Salvar relatório em arquivo
	saveReportToFile(analyses)
}

func findAvailableSnapshots() []int {
	var snapshots []int
	seen := make(map[int]bool)

	files, err := ioutil.ReadDir("logs")
	if err != nil {
		fmt.Printf("❌ Erro ao ler diretório logs: %v\n", err)
		return snapshots
	}

	for _, file := range files {
		if strings.HasPrefix(file.Name(), "snapshot_") && strings.HasSuffix(file.Name(), ".json") {
			parts := strings.Split(file.Name(), "_")
			if len(parts) >= 3 {
				snapshotID, err := strconv.Atoi(parts[1])
				if err == nil && !seen[snapshotID] {
					snapshots = append(snapshots, snapshotID)
					seen[snapshotID] = true
				}
			}
		}
	}

	sort.Ints(snapshots)
	return snapshots
}

func analyzeSnapshot(snapshotID int) SnapshotAnalysis {
	analysis := SnapshotAnalysis{
		SnapshotID:    snapshotID,
		ProcessStates: []ProcessState{},
		IsValid:       true,
		Violations:    []string{},
		FaultDetected: false,
		FaultType:     "",
	}

	// Carregar estados de todos os processos para este snapshot
	files, err := ioutil.ReadDir("logs")
	if err != nil {
		analysis.Violations = append(analysis.Violations, fmt.Sprintf("Erro ao ler logs: %v", err))
		analysis.IsValid = false
		return analysis
	}

	for _, file := range files {
		if strings.HasPrefix(file.Name(), fmt.Sprintf("snapshot_%d_process_", snapshotID)) {
			data, err := ioutil.ReadFile(filepath.Join("logs", file.Name()))
			if err != nil {
				continue
			}

			var state ProcessState
			if json.Unmarshal(data, &state) == nil {
				analysis.ProcessStates = append(analysis.ProcessStates, state)
			}
		}
	}

	// Verificar se snapshot está completo
	if len(analysis.ProcessStates) < 2 {
		analysis.Violations = append(analysis.Violations,
			fmt.Sprintf("Snapshot incompleto: apenas %d processos participaram (mínimo 2)", len(analysis.ProcessStates)))
		analysis.IsValid = false
		return analysis
	}

	// Verificar invariantes
	checkInvariant1(&analysis) // Máximo um processo na SC
	checkInvariant2(&analysis) // Se todos noMX, então waiting=false e sem mensagens
	checkInvariant3(&analysis) // Se waiting=true, então processo na SC ou quer SC
	checkInvariant4(&analysis) // Se quer SC, então respostas + waiting = N-1
	checkInvariant5(&analysis) // Detecção específica de falhas

	// Determinar se há falhas detectadas
	if len(analysis.Violations) > 0 {
		analysis.IsValid = false
		analysis.FaultDetected = detectFaultType(analysis)
	}

	return analysis
}

func checkInvariant1(analysis *SnapshotAnalysis) {
	inSC := 0
	for _, state := range analysis.ProcessStates {
		if state.State == 2 { // inMX = 2
			inSC++
		}
	}

	if inSC > 1 {
		analysis.Violations = append(analysis.Violations,
			fmt.Sprintf("Inv1 VIOLADA: %d processos na SC (máximo 1 permitido)", inSC))
	}
}

func checkInvariant2(analysis *SnapshotAnalysis) {
	allNoMX := true
	waitingCount := 0

	for _, state := range analysis.ProcessStates {
		if state.State != 0 { // noMX = 0
			allNoMX = false
		}
		// Contar flags waiting true
		for _, waiting := range state.Waiting {
			if waiting {
				waitingCount++
			}
		}
	}

	if allNoMX && waitingCount > 0 {
		analysis.Violations = append(analysis.Violations,
			fmt.Sprintf("Inv2 VIOLADA: Todos noMX mas %d flags waiting=true", waitingCount))
	}
}

func checkInvariant3(analysis *SnapshotAnalysis) {
	for _, state := range analysis.ProcessStates {
		// Verificar se há flags waiting true
		for i, waiting := range state.Waiting {
			if waiting {
				// Verificar se o processo i está na SC ou quer SC
				validWaiting := false
				for _, otherState := range analysis.ProcessStates {
					if otherState.ProcessID == i && (otherState.State == 2 || otherState.State == 1) {
						validWaiting = true
						break
					}
				}
				if !validWaiting {
					analysis.Violations = append(analysis.Violations,
						fmt.Sprintf("Inv3 VIOLADA: Processo %d waiting=true para processo %d mas processo %d não está na SC ou quer SC",
							state.ProcessID, i, i))
				}
			}
		}
	}
}

func checkInvariant4(analysis *SnapshotAnalysis) {
	N := len(analysis.ProcessStates)

	for _, state := range analysis.ProcessStates {
		if state.State == 1 { // wantMX = 1
			// Contar respostas recebidas
			responses := state.NumResponses

			// Contar flags waiting para este processo
			waitingFlags := 0
			for _, otherState := range analysis.ProcessStates {
				if otherState.ProcessID != state.ProcessID {
					for i, waiting := range otherState.Waiting {
						if i == state.ProcessID && waiting {
							waitingFlags++
						}
					}
				}
			}

			total := responses + waitingFlags
			expected := N - 1

			if total != expected {
				analysis.Violations = append(analysis.Violations,
					fmt.Sprintf("Inv4 VIOLADA: Processo %d quer SC mas total=%d (esperado %d) - respostas=%d, waiting=%d",
						state.ProcessID, total, expected, responses, waitingFlags))
			}
		}
	}
}

func checkInvariant5(analysis *SnapshotAnalysis) {
	// Detecção específica de falhas inseridas

	// Falha 1: Violação de exclusão mútua
	inSC := 0
	for _, state := range analysis.ProcessStates {
		if state.State == 2 { // inMX = 2
			inSC++
		}
	}

	if inSC > 1 {
		analysis.FaultDetected = true
		analysis.FaultType = "VIOLAÇÃO_EXCLUSÃO_MÚTUA"
		return
	}

	// Falha 2: Deadlock - processos querendo SC mas sem respostas
	deadlockDetected := false
	for _, state := range analysis.ProcessStates {
		if state.State == 1 && state.NumResponses == 0 { // wantMX = 1
			// Verificar se outros processos não estão respondendo
			allNotResponding := true
			for _, otherState := range analysis.ProcessStates {
				if otherState.ProcessID != state.ProcessID &&
					(otherState.State == 0 ||
						(otherState.State == 1 && otherState.RequestTs > state.RequestTs)) {
					allNotResponding = false
					break
				}
			}
			if allNotResponding {
				deadlockDetected = true
				break
			}
		}
	}

	if deadlockDetected {
		analysis.FaultDetected = true
		analysis.FaultType = "DEADLOCK"
	}
}

func detectFaultType(analysis SnapshotAnalysis) bool {
	for _, violation := range analysis.Violations {
		if strings.Contains(violation, "Inv1 VIOLADA") {
			analysis.FaultType = "VIOLAÇÃO_EXCLUSÃO_MÚTUA"
			return true
		}
		if strings.Contains(violation, "Inv4 VIOLADA") && strings.Contains(violation, "respostas=0") {
			analysis.FaultType = "DEADLOCK"
			return true
		}
	}
	return false
}

func generateDetailedReport(analyses []SnapshotAnalysis, totalViolations, faultDetections int) {
	fmt.Println("\n" + strings.Repeat("=", 60))
	fmt.Println("📋 RELATÓRIO DETALHADO DE ANÁLISE")
	fmt.Println(strings.Repeat("=", 60))

	fmt.Printf("📊 Total de snapshots analisados: %d\n", len(analyses))
	fmt.Printf("❌ Snapshots com violações: %d\n", totalViolations)
	fmt.Printf("🚨 Falhas detectadas: %d\n", faultDetections)

	if faultDetections > 0 {
		fmt.Println("\n🔍 FALHAS DETECTADAS:")
		faultTypes := make(map[string]int)
		for _, analysis := range analyses {
			if analysis.FaultDetected {
				faultTypes[analysis.FaultType]++
			}
		}
		for faultType, count := range faultTypes {
			fmt.Printf("   • %s: %d snapshots\n", faultType, count)
		}
	}

	fmt.Println("\n📝 DETALHES POR SNAPSHOT:")
	for _, analysis := range analyses {
		status := "✅ VÁLIDO"
		if !analysis.IsValid {
			status = "❌ INVÁLIDO"
		}

		fmt.Printf("\nSnapshot %d: %s\n", analysis.SnapshotID, status)
		fmt.Printf("   Processos: %d\n", len(analysis.ProcessStates))

		if analysis.FaultDetected {
			fmt.Printf("   🚨 FALHA: %s\n", analysis.FaultType)
		}

		if len(analysis.Violations) > 0 {
			fmt.Println("   Violações:")
			for _, violation := range analysis.Violations {
				fmt.Printf("     • %s\n", violation)
			}
		}
	}

	fmt.Println("\n" + strings.Repeat("=", 60))
}

func saveReportToFile(analyses []SnapshotAnalysis) {
	report := map[string]interface{}{
		"timestamp": "2024-12-19",
		"analyses":  analyses,
		"summary": map[string]interface{}{
			"totalSnapshots":   len(analyses),
			"invalidSnapshots": 0,
			"faultDetections":  0,
		},
	}

	// Contar estatísticas
	for _, analysis := range analyses {
		if !analysis.IsValid {
			report["summary"].(map[string]interface{})["invalidSnapshots"] =
				report["summary"].(map[string]interface{})["invalidSnapshots"].(int) + 1
		}
		if analysis.FaultDetected {
			report["summary"].(map[string]interface{})["faultDetections"] =
				report["summary"].(map[string]interface{})["faultDetections"].(int) + 1
		}
	}

	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		fmt.Printf("❌ Erro ao gerar relatório: %v\n", err)
		return
	}

	err = ioutil.WriteFile("logs/relatorio_analise.json", data, 0644)
	if err != nil {
		fmt.Printf("❌ Erro ao salvar relatório: %v\n", err)
		return
	}

	fmt.Println("💾 Relatório salvo em: logs/relatorio_analise.json")
}

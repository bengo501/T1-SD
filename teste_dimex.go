package main

import (
	"SD/DIMEX"
	"fmt"
	"os"
	"strconv"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Uso: go run teste_dimex.go <id> <endereco1> <endereco2> <endereco3>")
		return
	}

	id, _ := strconv.Atoi(os.Args[1])
	addresses := os.Args[2:]
	fmt.Printf("[APP] Processo %d iniciando\n", id)

	dmx := DIMEX.NewDIMEX(addresses, id, true)
	fmt.Printf("[APP] DIMEX criado\n")

	// Abrir arquivo
	file, err := os.OpenFile("./logs/mxOUT.txt", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Printf("[APP] Erro ao abrir arquivo: %v\n", err)
		return
	}
	defer file.Close()

	fmt.Printf("[APP] Aguardando inicialização...\n")
	time.Sleep(3 * time.Second)

	for {
		fmt.Printf("[APP] Processo %d solicitando acesso\n", id)
		dmx.Req <- DIMEX.ENTER
		<-dmx.Ind
		fmt.Printf("[APP] Processo %d recebeu liberação!\n", id)

		file.WriteString("|.")
		file.Sync()

		fmt.Printf("[APP] Processo %d liberando\n", id)
		dmx.Req <- DIMEX.EXIT
	}
}

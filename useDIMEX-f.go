// Construido como parte da disciplina: Sistemas Distribuidos - PUCRS - Escola Politecnica
//  Professor: Fernando Dotti  (https://fldotti.github.io/)
// Uso p exemplo:
//   go run usaDIMEX.go 0 127.0.0.1:5000  127.0.0.1:6001  127.0.0.1:7002 ")
//   go run usaDIMEX.go 1 127.0.0.1:5000  127.0.0.1:6001  127.0.0.1:7002 ")
//   go run usaDIMEX.go 2 127.0.0.1:5000  127.0.0.1:6001  127.0.0.1:7002 ")
// ----------
// LANCAR N PROCESSOS EM SHELL's DIFERENTES, UMA PARA CADA PROCESSO.
// para cada processo fornecer: seu id único (0, 1, 2 ...) e a mesma lista de processos.
// o endereco de cada processo é o dado na lista, na posicao do seu id.
// no exemplo acima o processo com id=1  usa a porta 6001 para receber e as portas
// 5000 e 7002 para mandar mensagens respectivamente para processos com id=0 e 2
// -----------
// Esta versão supõe que todos processos tem acesso a um mesmo arquivo chamado "mxOUT.txt"
// Todos processos escrevem neste arquivo, usando o protocolo dimex para exclusao mutua.
// Os processos escrevem "|." cada vez que acessam o arquivo.   Assim, o arquivo com conteúdo
// correto deverá ser uma sequencia de
// |.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.
// |.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.
// |.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.
// etc etc ...     ....  até o usuário interromper os processos (ctl c).
// Qualquer padrao diferente disso, revela um erro.
//      |.|.|.|.|.||..|.|.|.  etc etc  por exemplo.
// Se voce retirar o protocolo dimex vai ver que o arquivo poderá entrelacar
// "|."  dos processos de diversas diferentes formas.
// Ou seja, o padrão correto acima é garantido pelo dimex.
// Ainda assim, isto é apenas um teste.  E testes são frágeis em sistemas distribuídos.

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
		fmt.Println("Please specify at least one address:port!")
		fmt.Println("go run usaDIMEX-f.go 0 127.0.0.1:5000  127.0.0.1:6001  127.0.0.1:7002 ")
		fmt.Println("go run usaDIMEX-f.go 1 127.0.0.1:5000  127.0.0.1:6001  127.0.0.1:7002 ")
		fmt.Println("go run usaDIMEX-f.go 2 127.0.0.1:5000  127.0.0.1:6001  127.0.0.1:7002 ")
		return
	}

	id, _ := strconv.Atoi(os.Args[1])
	addresses := os.Args[2:]
	fmt.Printf("[APP] Iniciando processo %d com endereços: %v\n", id, addresses)

	var dmx *DIMEX.DIMEX_Module = DIMEX.NewDIMEX(addresses, id, true)
	fmt.Printf("[APP] Módulo DIMEX criado: %v\n", dmx)

	// INICIALIZA O MÓDULO DIMEX
	dmx.Start()
	fmt.Printf("[APP] Módulo DIMEX iniciado\n")

	// abre arquivo que TODOS processos devem poder usar
	fmt.Printf("[APP] Abrindo arquivo logs/mxOUT.txt\n")
	file, err := os.OpenFile("./logs/mxOUT.txt", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Printf("[APP] Erro ao abrir arquivo: %v\n", err)
		return
	}
	defer file.Close() // Ensure the file is closed at the end of the function
	fmt.Printf("[APP] Arquivo aberto com sucesso\n")

	// espera para facilitar inicializacao de todos processos (a mao)
	fmt.Printf("[APP] Aguardando 3 segundos para inicialização...\n")
	time.Sleep(3 * time.Second)

	fmt.Printf("[APP] Iniciando loop principal\n")
	for {
		// SOLICITA ACESSO AO DIMEX
		fmt.Printf("[APP] Processo %d solicitando acesso à seção crítica\n", id)
		dmx.Req <- DIMEX.ENTER
		fmt.Printf("[APP] Processo %d aguardando liberação\n", id)
		// ESPERA LIBERACAO DO MODULO DIMEX
		<-dmx.Ind //
		fmt.Printf("[APP] Processo %d recebeu liberação!\n", id)

		// A PARTIR DAQUI ESTA ACESSANDO O ARQUIVO SOZINHO
		fmt.Printf("[APP] Processo %d escrevendo '|' no arquivo\n", id)
		_, err = file.WriteString("|") // marca entrada no arquivo
		if err != nil {
			fmt.Printf("[APP] Erro ao escrever '|': %v\n", err)
			return
		}
		file.Sync() // Força a escrita no disco

		fmt.Printf("[APP] Processo %d *EM* seção crítica\n", id)

		_, err = file.WriteString(".") // marca saida no arquivo
		if err != nil {
			fmt.Printf("[APP] Erro ao escrever '.': %v\n", err)
			return
		}
		file.Sync() // Força a escrita no disco

		// AGORA VAI LIBERAR O ARQUIVO PARA OUTROS
		fmt.Printf("[APP] Processo %d liberando seção crítica\n", id)
		dmx.Req <- DIMEX.EXIT //
		fmt.Printf("[APP] Processo %d *FORA* seção crítica\n", id)
	}
}

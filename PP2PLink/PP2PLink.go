/*
  Construido como parte da disciplina: Sistemas Distribuidos - PUCRS - Escola Politecnica
  Professor: Fernando Dotti  (https://fldotti.github.io/)
  Modulo representando Perfect Point to Point Links tal como definido em:
    Introduction to Reliable and Secure Distributed Programming
    Christian Cachin, Rachid Gerraoui, Luis Rodrigues
  * Semestre 2018/2 - Primeira versao.  Estudantes:  Andre Antonitsch e Rafael Copstein
  * Semestre 2019/1 - Reaproveita conexões TCP já abertas - Estudantes: Vinicius Sesti e Gabriel Waengertner
  * Semestre 2020/1 - Separa mensagens de qualquer tamanho atee 4 digitos.
  Sender envia tamanho no formato 4 digitos (preenche com 0s a esquerda)
  Receiver recebe 4 digitos, calcula tamanho do buffer a receber,
  e recebe com io.ReadFull o tamanho informado - Dotti
  * Semestre 2022/1 - melhorias eliminando retorno de erro aos canais superiores.
  se conexao fecha nao retorna nada.   melhorias em comentarios.   adicionado modo debug. - Dotti
*/

package PP2PLink

import (
	"encoding/json"
	"fmt"
	"io"
	"net"
	"strconv"
	"strings"
	"sync"
	"time"
)

type PP2LinkMessage struct {
	Value string
	Data  map[string]string
}

type PP2PLink_Req_Message struct {
	To      string
	Message PP2LinkMessage
}

type PP2PLink_Ind_Message struct {
	From    string
	Message PP2LinkMessage
}

type PP2PLink struct {
	Ind   chan PP2PLink_Ind_Message
	Req   chan PP2PLink_Req_Message
	Run   bool
	Cache map[string]net.Conn
	mutex sync.RWMutex // Proteção para acesso concorrente ao cache
}

func (module *PP2PLink) Init(address string) {
	fmt.Println("[PP LINK] - Init PP2PLink!")
	if module.Run {
		return
	}

	module.Cache = make(map[string]net.Conn)
	module.Run = true
	module.Start(address)
}

func (module *PP2PLink) Start(address string) {
	go func() {
		listen, err := net.Listen("tcp4", address)
		if err != nil {
			fmt.Printf("[PP2PLink] ERRO CRÍTICO: Não foi possível iniciar listener em %s: %v\n", address, err)
			return
		}
		defer listen.Close()

		for {
			conn, err := listen.Accept()
			if err != nil {
				fmt.Printf("[PP2PLink] Erro ao aceitar conexão: %v\n", err)
				continue
			}

			go func(connection net.Conn) {
				defer connection.Close()

				for {
					// Define timeout para leitura
					connection.SetReadDeadline(time.Now().Add(30 * time.Second))

					bufTam := make([]byte, 4)
					_, err := io.ReadFull(connection, bufTam)
					if err != nil {
						if err != io.EOF {
							fmt.Printf("[PP2PLink] Erro ao ler tamanho da mensagem: %v\n", err)
						}
						return
					}

					tam, err := strconv.Atoi(string(bufTam))
					if err != nil {
						fmt.Printf("[PP2PLink] Erro ao converter tamanho: %v\n", err)
						continue
					}

					bufMsg := make([]byte, tam)
					_, err = io.ReadFull(connection, bufMsg)
					if err != nil {
						fmt.Printf("[PP2PLink] Erro ao ler mensagem: %v\n", err)
						return
					}

					bufMsgAsStruct := StringToMessage(string(bufMsg))
					msg := PP2PLink_Ind_Message{
						From:    connection.RemoteAddr().String(),
						Message: bufMsgAsStruct,
					}
					module.Ind <- msg
				}
			}(conn)
		}
	}()

	go func() {
		for {
			message := <-module.Req
			go module.Send(message)
		}
	}()
}

func (module *PP2PLink) Send(message PP2PLink_Req_Message) {
	value := message.Message.Value
	if strings.Contains(value, "delay") {
		time.Sleep(3 * time.Second)
	}

	var conn net.Conn
	var ok bool
	var err error

	// Proteção para acesso concorrente ao cache
	module.mutex.RLock()
	if conn, ok = module.Cache[message.To]; ok {
		// Testa se a conexão ainda está válida
		conn.SetWriteDeadline(time.Now().Add(1 * time.Second))
		_, err = conn.Write([]byte{})
		if err != nil {
			// Remove a conexão inválida do cache
			module.mutex.RUnlock()
			module.mutex.Lock()
			delete(module.Cache, message.To)
			module.mutex.Unlock()
			conn = nil
			ok = false
		} else {
			module.mutex.RUnlock()
		}
	} else {
		module.mutex.RUnlock()
	}

	if !ok || conn == nil {
		conn, err = net.DialTimeout("tcp", message.To, 5*time.Second)
		if err != nil {
			fmt.Printf("[PP2PLink] Erro ao conectar com %s: %v\n", message.To, err)
			return
		}
		module.mutex.Lock()
		module.Cache[message.To] = conn
		module.mutex.Unlock()
	}

	messageAsString := MessageToString(message.Message)
	strSize := strconv.Itoa(len(messageAsString))
	for len(strSize) < 4 {
		strSize = "0" + strSize
	}
	if !(len(strSize) == 4) {
		fmt.Println("ERROR AT PPLINK MESSAGE SIZE CALCULATION - INVALID MESSAGES MAY BE IN TRANSIT")
		return
	}

	// Define timeout para escrita
	conn.SetWriteDeadline(time.Now().Add(5 * time.Second))

	_, err = fmt.Fprintf(conn, strSize)
	if err != nil {
		fmt.Printf("[PP2PLink] Erro ao enviar tamanho: %v\n", err)
		// Remove conexão inválida e tenta reconectar
		module.mutex.Lock()
		delete(module.Cache, message.To)
		module.mutex.Unlock()
		return
	}

	_, err = fmt.Fprintf(conn, messageAsString)
	if err != nil {
		fmt.Printf("[PP2PLink] Erro ao enviar mensagem: %v\n", err)
		// Remove conexão inválida
		module.mutex.Lock()
		delete(module.Cache, message.To)
		module.mutex.Unlock()
		return
	}
}

func StringToMessage(s string) PP2LinkMessage {
	// Limpa a string e procura por JSON válido
	s = strings.TrimSpace(s)

	// Procura por início e fim de JSON
	start := strings.Index(s, "{")
	end := strings.LastIndex(s, "}")

	if start == -1 || end == -1 || end <= start {
		fmt.Printf("[PP2PLink] String não contém JSON válido: %s\n", s)
		return PP2LinkMessage{Value: "error", Data: map[string]string{}}
	}

	jsonStr := s[start : end+1]

	rawIn := json.RawMessage(jsonStr)
	bytes, err := rawIn.MarshalJSON()
	if err != nil {
		fmt.Printf("[PP2PLink] Erro ao processar mensagem JSON: %v\n", err)
		return PP2LinkMessage{Value: "error", Data: map[string]string{}}
	}

	var message PP2LinkMessage
	err = json.Unmarshal(bytes, &message)
	if err != nil {
		fmt.Printf("[PP2PLink] Erro ao deserializar mensagem: %v\n", err)
		return PP2LinkMessage{Value: "error", Data: map[string]string{}}
	}
	return message
}

func MessageToString(message PP2LinkMessage) string {
	bytes, err := json.Marshal(message)
	if err != nil {
		fmt.Printf("[PP2PLink] Erro ao serializar mensagem: %v\n", err)
		// Retorna uma mensagem de erro em vez de panic
		return `{"Value":"error","Data":{}}`
	}
	return string(bytes)
}

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
	mutex sync.RWMutex // ADICIONADO: Mutex para proteger acesso concorrente ao Cache
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
	fmt.Printf("[PP2PLink] Iniciando PP2PLink em %s\n", address)

	go func() {
		listen, err := net.Listen("tcp4", address)
		if err != nil {
			fmt.Printf("[PP2PLink] ERRO CRÍTICO: Não foi possível iniciar listener em %s: %v\n", address, err)
			return
		}
		fmt.Printf("[PP2PLink] ✅ Listener iniciado com sucesso em %s\n", address)
		defer listen.Close()

		for {
			conn, err := listen.Accept()
			if err != nil {
				fmt.Printf("[PP2PLink] Erro ao aceitar conexão: %v\n", err)
				continue
			}

			fmt.Printf("[PP2PLink] ✅ Nova conexão aceita de %s\n", conn.RemoteAddr().String())

			go func(connection net.Conn) {
				defer func() {
					connection.Close()
					fmt.Printf("[PP2PLink] Conexão fechada com %s\n", connection.RemoteAddr().String())
				}()

				for {
					// Lê o tamanho da mensagem (4 bytes)
					bufTam := make([]byte, 4)
					_, err := io.ReadFull(connection, bufTam)
					if err != nil {
						if err != io.EOF {
							fmt.Printf("[PP2PLink] Erro ao ler tamanho da mensagem de %s: %v\n", connection.RemoteAddr().String(), err)
						}
						return
					}

					// Converte o tamanho para int
					tamStr := strings.TrimSpace(string(bufTam))
					tam, err := strconv.Atoi(tamStr)
					if err != nil {
						fmt.Printf("[PP2PLink] Erro ao converter tamanho da mensagem '%s': %v\n", tamStr, err)
						continue
					}

					if tam <= 0 || tam > 10000 { // Limite de segurança
						fmt.Printf("[PP2PLink] Tamanho de mensagem inválido: %d\n", tam)
						continue
					}

					// Lê a mensagem
					bufMsg := make([]byte, tam)
					_, err = io.ReadFull(connection, bufMsg)
					if err != nil {
						fmt.Printf("[PP2PLink] Erro ao ler mensagem de %s: %v\n", connection.RemoteAddr().String(), err)
						return
					}

					// Converte a mensagem para estrutura
					msgStr := string(bufMsg)
					fmt.Printf("[PP2PLink] Mensagem bruta recebida: '%s'\n", msgStr)

					bufMsgAsStruct := StringToMessage(msgStr)
					msg := PP2PLink_Ind_Message{
						From:    connection.RemoteAddr().String(),
						Message: bufMsgAsStruct,
					}

					fmt.Printf("[PP2PLink] ✅ Mensagem processada de %s: %s\n", msg.From, bufMsgAsStruct.Value)

					// Envia para o canal com timeout para evitar bloqueio
					select {
					case module.Ind <- msg:
						fmt.Printf("[PP2PLink] ✅ Mensagem enviada para o canal\n")
					default:
						fmt.Printf("[PP2PLink] ⚠️ Canal ocupado, mensagem descartada\n")
					}
				}
			}(conn)
		}
	}()

	go func() {
		fmt.Printf("[PP2PLink] Goroutine de envio iniciada\n")
		for {
			message := <-module.Req
			fmt.Printf("[PP2PLink] Nova mensagem para enviar para %s\n", message.To)
			go module.Send(message)
		}
	}()
}

func (module *PP2PLink) Send(message PP2PLink_Req_Message) {
	value := message.Message.Value
	if strings.Contains(value, "delay") {
		time.Sleep(3 * time.Second)
	}

	fmt.Printf("[PP2PLink] 📤 Enviando mensagem para %s: %s\n", message.To, value)

	var conn net.Conn
	var ok bool
	var err error

	// ADICIONADO: Proteção com mutex para leitura do Cache
	module.mutex.RLock()
	if conn, ok = module.Cache[message.To]; ok {
		module.mutex.RUnlock()
		fmt.Printf("[PP2PLink] 🔄 Usando conexão existente para %s\n", message.To)

		// Testa se a conexão ainda está válida
		conn.SetWriteDeadline(time.Now().Add(1 * time.Second))
		_, err = conn.Write([]byte{})
		if err != nil {
			fmt.Printf("[PP2PLink] ⚠️ Conexão existente inválida para %s: %v\n", message.To, err)
			// Remove a conexão inválida do cache
			module.mutex.Lock()
			delete(module.Cache, message.To)
			module.mutex.Unlock()
			conn = nil
			ok = false
		}
	} else {
		module.mutex.RUnlock()
	}

	if !ok || conn == nil {
		// ADICIONADO: Proteção com mutex para escrita no Cache
		module.mutex.Lock()
		// Verifica novamente após obter o lock de escrita
		if conn, ok = module.Cache[message.To]; ok {
			module.mutex.Unlock()
			fmt.Printf("[PP2PLink] 🔄 Usando conexão existente para %s\n", message.To)
		} else {
			fmt.Printf("[PP2PLink] 🔗 Criando nova conexão para %s\n", message.To)
			conn, err = net.DialTimeout("tcp", message.To, 5*time.Second)
			if err != nil {
				module.mutex.Unlock()
				fmt.Printf("[PP2PLink] ❌ Erro ao conectar com %s: %v\n", message.To, err)
				return
			}
			module.Cache[message.To] = conn
			module.mutex.Unlock()
			fmt.Printf("[PP2PLink] ✅ Conexão criada com sucesso para %s\n", message.To)
		}
	}

	messageAsString := MessageToString(message.Message)
	strSize := strconv.Itoa(len(messageAsString))

	// Preenche com zeros à esquerda para ter exatamente 4 caracteres
	for len(strSize) < 4 {
		strSize = "0" + strSize
	}

	if len(strSize) != 4 {
		fmt.Printf("[PP2PLink] ❌ ERRO: Tamanho da mensagem inválido: %s (len=%d)\n", strSize, len(strSize))
		return
	}

	fmt.Printf("[PP2PLink] 📏 Enviando tamanho: '%s' para %s\n", strSize, message.To)
	fmt.Printf("[PP2PLink] 📄 Enviando conteúdo: '%s' para %s\n", messageAsString, message.To)

	// Define timeout para escrita
	conn.SetWriteDeadline(time.Now().Add(5 * time.Second))

	// Envia tamanho
	_, err = fmt.Fprintf(conn, strSize)
	if err != nil {
		fmt.Printf("[PP2PLink] ❌ Erro ao enviar tamanho para %s: %v\n", message.To, err)
		return
	}

	// Envia mensagem
	_, err = fmt.Fprintf(conn, messageAsString)
	if err != nil {
		fmt.Printf("[PP2PLink] ❌ Erro ao enviar mensagem para %s: %v\n", message.To, err)
		return
	}

	fmt.Printf("[PP2PLink] ✅ Mensagem enviada com sucesso para %s\n", message.To)
}

func StringToMessage(s string) PP2LinkMessage {
	rawIn := json.RawMessage(s)
	bytes, err := rawIn.MarshalJSON()
	if err != nil {
		panic(err)
	}

	var message PP2LinkMessage
	err = json.Unmarshal(bytes, &message)
	if err != nil {
		panic(err)
	}
	return message
}

func MessageToString(message PP2LinkMessage) string {
	bytes, err := json.Marshal(message)
	if err != nil {
		panic(err)
	}
	return string(bytes)
}

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
	"fmt"
	"io"
	"net"
	"strconv"
)

type PP2PLink_Req_Message struct {
	To      string
	Message string
}

type PP2PLink_Ind_Message struct {
	From    string
	Message string
}

type PP2PLink struct {
	Ind   chan PP2PLink_Ind_Message
	Req   chan PP2PLink_Req_Message
	Run   bool
	dbg   bool
	Cache map[string]net.Conn // cache de conexoes - reaproveita conexao com destino ao inves de abrir outra
}

func NewPP2PLink(_address string, _dbg bool) *PP2PLink {
	p2p := &PP2PLink{
		Req:   make(chan PP2PLink_Req_Message, 1),
		Ind:   make(chan PP2PLink_Ind_Message, 1),
		Run:   true,
		dbg:   _dbg,
		Cache: make(map[string]net.Conn)}
	p2p.outDbg(" Init PP2PLink!")
	p2p.Start(_address)
	return p2p
}

func (module *PP2PLink) outDbg(s string) {
	if module.dbg {
		fmt.Println(". . . . . . . . . . . . . . . . . [ PP2PLink msg : " + s + " ]")
	}
}

func (module *PP2PLink) Start(address string) {

	// PROCESSO PARA RECEBIMENTO DE MENSAGENS
	go func() {
		listen, _ := net.Listen("tcp4", address)
		for {
			// aceita repetidamente tentativas novas de conexao
			conn, err := listen.Accept()
			module.outDbg("ok   : conexao aceita com outro processo.")
			// para cada conexao lanca rotina de tratamento
			go func() {
				// repetidamente recebe mensagens na conexao TCP (sem fechar)
				// e passa para modulo de cima
				for { //                              // enquanto conexao aberta
					if err != nil {
						fmt.Println(".", err)
						break
					}
					bufTam := make([]byte, 4) //       // le tamanho da mensagem
					_, err := io.ReadFull(conn, bufTam)
					if err != nil {
						module.outDbg("erro : " + err.Error() + " conexao fechada pelo outro processo.")
						break
					}
					tam, err := strconv.Atoi(string(bufTam))
					bufMsg := make([]byte, tam)        // declara buffer do tamanho exato
					_, err = io.ReadFull(conn, bufMsg) // le do tamanho do buffer ou da erro
					if err != nil {
						fmt.Println("@", err)
						break
					}
					msg := PP2PLink_Ind_Message{
						From:    conn.RemoteAddr().String(),
						Message: string(bufMsg)}
					// ATE AQUI:  procedimentos para receber msg
					module.Ind <- msg //               // repassa mensagem para modulo superior
				}
			}()
		}
	}()

	// PROCESSO PARA ENVIO DE MENSAGENS
	go func() {
		for {
			message := <-module.Req
			module.Send(message)
		}
	}()
}

func (module *PP2PLink) Send(message PP2PLink_Req_Message) {
	var conn net.Conn
	var ok bool
	var err error

	// ja existe uma conexao aberta para aquele destinatario?
	if conn, ok = module.Cache[message.To]; ok {
	} else { // se nao existe, abre e guarda na cache
		conn, err = net.Dial("tcp", message.To)
		module.outDbg("ok   : conexao iniciada com outro processo")
		if err != nil {
			fmt.Println(err)
			return
		}
		module.Cache[message.To] = conn
	}
	// calcula tamanho da mensagem e monta string de 4 caracteres numericos com o tamanho.
	// completa com 0s aa esquerda para fechar tamanho se necessario.
	str := strconv.Itoa(len(message.Message))
	for len(str) < 4 {
		str = "0" + str
	}
	if !(len(str) == 4) {
		module.outDbg("ERROR AT PPLINK MESSAGE SIZE CALCULATION - INVALID MESSAGES MAY BE IN TRANSIT")
	}
	_, err = fmt.Fprintf(conn, str)             // escreve 4 caracteres com tamanho
	_, err = fmt.Fprintf(conn, message.Message) // escreve a mensagem com o tamanho calculado
	if err != nil {
		module.outDbg("erro : " + err.Error() + ". Conexao fechada. 1 tentativa de reabrir:")
		conn, err = net.Dial("tcp", message.To)
		if err != nil {
			//fmt.Println(err)
			module.outDbg("       " + err.Error())
			return
		} else {
			module.outDbg("ok   : conexao iniciada com outro processo.")
		}
		module.Cache[message.To] = conn
		_, err = fmt.Fprintf(conn, str)             // escreve 4 caracteres com tamanho
		_, err = fmt.Fprintf(conn, message.Message) // escreve a mensagem com o tamanho calculado
	}
	return
}

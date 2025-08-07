from threading import Thread
from socket import socket, SOCK_STREAM

class PerfectPointToPointLink:
	"""
	Module 2.3: Interface and properties of perfect point-to-point links

	Events
	------
	Send(q, m):
		Requests to send message m to process q.
	Deliver(p, m):
		Delivers message m sent by process p.

	Properties
	----------
	PL1: Reliable delivery:
		If a correct process p sends a message m to a correct
		process q, then q eventually delivers m.
	PL2: No duplication:
		No message is delivered by a process more than once.
	PL3: No creation:
		If some process q delivers a message m with sender p, then m
		was previously sent to q by process p.
	"""

	def __init__(self, address, on_delivery = print):
		self.handle_delivery = on_delivery

		self.socket = socket(type=SOCK_STREAM)
		self.socket.bind(solve_address(address))

		self.threads = [Thread(target=f) for f in (self.watch,)]
		for t in self.threads:
			t.start()

	def Send(self, q, m):
		# Requests to send message m to process q.
			q = solve_address(q)
			s = socket(type=SOCK_STREAM)
			try:
				s.connect(q)
				s.sendto(m.encode(), q)
			except ConnectionError:
				pass

	def Deliver(self, p, m):
		# Delivers message m sent by process p.
			p = solve_address(p)
			self.handle_delivery(':'.join(map(str, p)), m)

	def watch(self):
		# Watches the link.
		while(True):
			self.socket.listen(1)
			connection, address = self.socket.accept()
			message, _ = connection.recvfrom(1024)
			self.Deliver(address, message.decode())

def solve_address(addr):
	# Converts a string address (ip:port) to the tuple used by socket.
	if(type(addr) == str):
		ip, port = addr.split(':')
		port = int(port)
		return (ip, port)
	else:
		return addr
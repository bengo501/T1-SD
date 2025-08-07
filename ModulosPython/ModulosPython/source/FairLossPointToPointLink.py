from threading import Thread
from socket import socket, SOCK_DGRAM

class FairLossPointToPointLink:
	"""
	Module 2.1: Interface and properties of fair-loss point-to-point links

	Events
	------
	Send(q, m):
		Requests to send message m to process q.
	Deliver(p, m):
		Delivers message m sent by process p.

	Properties
	----------
	FLL1: Fair-loss:
		If a correct process p infinitely often sends a message m to a
		correct process q, then q delivers m an infinite number of times.
	FLL2: Finite duplication:
		If a correct process p sends a message m a finite number
		of times to process q, then m cannot be delivered an infinite number of times by q.
	FLL3: No creation:
		If some process q delivers a message m with sender p, then m
		was previously sent to q by process p.
	"""

	def __init__(self, address, on_delivery = print):
		self.handle_delivery = on_delivery

		self.socket = socket(type=SOCK_DGRAM)
		self.socket.bind(solve_address(address))

		self.threads = [Thread(target=f) for f in (self.watch,)]
		for t in self.threads:
			t.start()

	def Send(self, q, m):
		# Requests to send message m to process q.
			q = solve_address(q)
			self.socket.sendto(m.encode(), q)

	def Deliver(self, p, m):
		# Delivers message m sent by process p.
			p = solve_address(p)
			self.handle_delivery(':'.join(map(str, p)), m)

	def watch(self):
		# Watches the link.
		while(True):
			message, address = self.socket.recvfrom(1024)
			self.Deliver(address, message.decode())

def solve_address(addr):
	# Converts a string address (ip:port) to the tuple used by socket.
	if(type(addr) == str):
		ip, port = addr.split(':')
		port = int(port)
		return (ip, port)
	else:
		return addr
import subprocess
import socket
from threading import Thread

PORT = 5437

EXISTS = 'exists'
GROUP = 'group'
READY = 'ready'

class Manager:
	def __init__(self, module = None, own_processes = set(), other_processes = set()):
		self.module = module
		self.n_processes = own_processes if type(own_processes) == int else None
		self.own_processes = own_processes if type(own_processes) == set else set()
		self.other_processes = other_processes

		self.ip_options = get_ip_options()
		if(len(self.ip_options) > 1):
			print('Choose an ip:')
			print('\n'.join(f'{i}: {ip}' for i, ip in enumerate(self.ip_options)))
			op = int(input())
		else:
			op = 0
		self.ip = self.ip_options[op] if self.ip_options else None

		self.known = set()
		self.group = {self.ip}

		self.threads = [Thread(target=f, daemon=True) for f in (self.listen,)]
		for t in self.threads:
			t.start()

	def set_ports(self):
		# Find n unused ports
		while(len(self.own_processes) < self.n_processes):
			with socket.socket() as s:
				s.bind(('', 0))
				port = s.getsockname()[1]
				self.own_processes.add(f'{self.ip}:{port}')

	def broadcast(self, message):
		with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
			s.bind((self.ip, PORT))
			s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
			s.sendto(message.encode(), ("255.255.255.255", PORT))

	def start(self):
		module = getattr(self.module, '__name__', None) or self.module
		for name in self.own_processes:
			others = [p for p in self.own_processes if p != name] + list(self.other_processes)
			subprocess.Popen(f'python chat.py {module} {name} {" ".join(others)}', creationflags=subprocess.CREATE_NEW_CONSOLE)

	def add(self, *others):
		self.group.update(others)
		self.broadcast(f'{GROUP} {" ".join(self.group)}')

	def ready(self):
		if(not self.own_processes):
			self.set_ports()
			self.broadcast(f'{READY} {" ".join(self.own_processes)}')

		# Start when all the processes of all managers in the group are known
		if(all(any(ip.startswith(other) for ip in self.other_processes) for other in self.group - {self.ip})):
			self.start()

	def on_started_listening(self):
		self.broadcast(EXISTS)

	def listen(self):
		with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
			s.bind(('', PORT))
			self.on_started_listening()
			while(True):
				message, address = s.recvfrom(1024)
				address = address[0]
				if(address.startswith(self.ip)):
					continue
				message = message.decode()

				# Update list of known managers, while keeping them updated
				if(message == EXISTS):
					if(not address in self.known):
						self.known.add(address)
						self.broadcast(EXISTS)

				# Join group upon request
				elif(message.startswith(GROUP)):
					managers = message[len(GROUP)+1:].split(' ')
					if(any(m in self.group for m in managers)):
						before = len(self.group)
						self.group.update(managers)
						if(len(self.group) != before):
							self.broadcast(f'{GROUP} {" ".join(self.group)}')

				# Receive command to start, updating the process list
				elif(message.startswith(READY)):
					if(address in self.group):
						processes = message[len(READY)+1:].split(' ')
						self.other_processes.update(processes)

						self.ready()

def get_ip_options():
	try:
		return socket.gethostbyname_ex(socket.getfqdn())[2]
	except:
		try:
			return socket.gethostbyname_ex(socket.getfqdn().split('.')[0])[2]
		except:
			return []
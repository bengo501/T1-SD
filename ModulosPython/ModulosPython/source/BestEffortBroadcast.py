from PerfectPointToPointLink import PerfectPointToPointLink as PL
from collections.abc import Iterable

class BestEffortBroadcast:
	"""
	Module 3.1: Interface and properties of best-effort broadcast
	Uses: PerfectPointToPointLink

	Events
	------
	Broadcast(m):
		Broadcassts a message m to all processes.
	Deliver(p, m):
		Delivers message m broadcast by process p.

	Properties
	----------
	BEB1: Validity:
		If a correct process broadcasts a message m, then every correct
		process eventually delivers m.
	BEB2: No duplication:
		No message is delivered more than once.
	BEB3: No creation:
		If a process delivers a message m with sender s, then m was
		previously broadcast by process s.
	"""

	def __init__(self, address, *others, on_delivery = print):
		self.others = set(next(iter(others[0])) if isinstance(others[0], Iterable) and not isinstance(others[0], str) else others)
		self.handle_delivery = on_delivery
		self.connection = PL(address, on_delivery=self.Deliver)

	def Broadcast(self, m):
		for q in self.others:
			self.connection.Send(q, m)

	def Deliver(self, p, m):
		self.handle_delivery(p, m)
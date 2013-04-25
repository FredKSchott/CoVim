#!/usr/bin/env python

from twisted.internet.protocol import Factory, Protocol
#from twisted.protocols.basic import LineReceiver
from twisted.internet import reactor
import pickle
import sys

class React(Protocol):
  def __init__(self, factory):
    self.factory = factory
    self.state = "GETNAME"
  def dataReceived(self, data):
    if self.state == "GETNAME":
      self.handle_GETNAME(data)
    else:
      self.handle_BUFF(data)
  def handle_GETNAME(self, name):
    if self.factory.clients.has_key(name):
      data_string = pickle.dumps({'message':"Name taken!"})
      self.transport.write(data_string)
      return
    if ' ' in name:
      data_string = pickle.dumps({'message':"Name contains space!"})
      self.transport.write(data_string)
      return
    data = {'message': 'Welcome, ' + name}
    if self.factory.count:
      data['buffer'] = self.factory.buf
    data_string = pickle.dumps(data)
    self.transport.write(data_string)
    self.name = name
    self.factory.clients[name] = self
    self.state = "CHAT"
    for name, protocol in self.factory.clients.iteritems():
      if protocol != self:
        message = self.name + " has connected!"
        protocol.transport.write(pickle.dumps({'message': message}))
  def handle_BUFF(self, data_string):
    data = pickle.loads(data_string)
    print data
    if 'buffer' in data.keys():
      self.factory.buf = data['buffer']
    for name, protocol in self.factory.clients.iteritems():
      if protocol != self:
        protocol.transport.write(data_string)
  def connectionMade(self):
    self.factory.count += 1
  def connectionLost(self, reason):
    self.factory.count -= 1
    if self.factory.count == 0:
      reactor.stop()
    if self.factory.clients.has_key(self.name):
      for name, protocol in self.factory.clients.iteritems():
        if protocol != self:
          message = self.name + " has disconnected!"
          protocol.transport.write(pickle.dumps({'message': message}))
      del self.factory.clients[self.name]

class ReactFactory(Factory):
  def __init__(self):
    self.clients = {}
    self.count = 0
    self.buf = ''
  def buildProtocol(self, addr):
    return React(self) 

if __name__ == '__main__':
  reactor.listenTCP(int(sys.argv[1]), ReactFactory())
  reactor.run()


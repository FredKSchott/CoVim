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
    # Handle duplicate name 
    if self.factory.clients.has_key(name):
      d = {
        'packet_type':'message',
        'data': {
          'message_type':'error_newname_taken'
        }
      }
      self.transport.write(pickle.dumps(d))
      return
    # Handle spaces in name
    if ' ' in name:
      d = {
        'packet_type':'message',
        'data': {
          'message_type':'error_newname_spaces'
        }
      }
      self.transport.write(pickle.dumps(d))
      return
    # Name is Valid, Add to Document
    self.name = name
    self.factory.clients[name] = self
    self.state = "CHAT"
    d = {
      'packet_type':'message',
      'data': {
        'message_type':'connect_success',
        'name':name,
        'collaborators':self.factory.clients.keys()
      }
    }
    if (self.factory.count>1):
      d['data']['buffer'] = self.factory.buf 
    self.transport.write(pickle.dumps(d))
    print 'User "'+self.name+'" Connected'
    # Alert other Collaborators of new user
    for name, protocol in self.factory.clients.iteritems():
      if protocol != self:
        d = {
          'packet_type':'message',
          'data': {
            'message_type':'user_connected',
            'name':self.name
          }
        }
        protocol.transport.write(pickle.dumps(d))
  def handle_BUFF(self, data_string):
    packet = pickle.loads(data_string)
    data = packet['data']
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
      print 'All users disconnected. Shutting down...'
      reactor.stop()
    if hasattr(self,'name') and self.name in self.factory.clients.keys():
      for name, protocol in self.factory.clients.iteritems():
        if protocol != self:
#remove your name from list of collaborators
          d = {
            'packet_type':'message',
            'data': {
              'message_type':'user_disconnected',
              'name':self.name
            }
          }
          protocol.transport.write(pickle.dumps(d))
      print 'User "'+self.name+'" Disconnected'
      del self.factory.clients[self.name]

class ReactFactory(Factory):
  def __init__(self):
    self.clients = {}
    self.count = 0
    self.buf = ''
  def initiate(self, port):
    self.port = port
    print 'Now listening on port '+str(port)+'...'
    reactor.listenTCP(port,self)
    reactor.run()
  def buildProtocol(self, addr):
    return React(self) 

if __name__ == '__main__':
  Server = ReactFactory()
  Server.initiate(int(sys.argv[1]))

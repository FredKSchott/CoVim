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
    if userManager.has_user(name):
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
    self.user = User(name, self)
    userManager.add_user(self.user)
    self.state = "CHAT"
    d = {
      'packet_type':'message',
      'data': {
        'message_type':'connect_success',
        'name':name,
        'collaborators':userManager.users.keys()
      }
    }
    if userManager.is_multi():
      d['data']['buffer'] = self.factory.buff 
    self.transport.write(pickle.dumps(d))
    print 'User "'+self.user.name+'" Connected'
    # Alert other Collaborators of new user
    d = {
      'packet_type':'message',
      'data': {
        'message_type':'user_connected',
        'name':self.user.name
      }
    }
    self.user.broadcast_packet(d)

  def handle_BUFF(self, data_string):
    d = pickle.loads(data_string)
    data = d['data']
    if 'cursor' in data.keys():
      user = userManager.get_user(data['name'])
      user.update_cursor(data['cursor']['x'], data['cursor']['y'])
      d['data']['updated_cursors'] = [user.to_json()]
      del d['data']['cursor']
    if 'buffer' in data.keys():
      b_data = data['buffer']
      #TODO: Improve Speed: If change_y = 0, just replace that one line
      #print ' \\n '.join(self.factory.buff[:b_data['start']])
      #print ' \\n '.join(b_data['buffer'])
      #print ' \\n '.join(self.factory.buff[b_data['end']-b_data['change_y']+1:])
      self.factory.buff = self.factory.buff[:b_data['start']]   \
                          + b_data['buffer']                    \
                          + self.factory.buff[b_data['end']-b_data['change_y']+1:]
      d['data']['updated_cursors'] += userManager.update_cursors(b_data, user)
      print d
      self.user.broadcast_packet(d, True)
      return
    print d
    self.user.broadcast_packet(d, False)




      # Correct Y
        # change_y = len(new_buffer)-len(old_buffer)
        # change_x = len(new_buffer[my_y-1])-len(old_buffer[my_y-1])

        # if change_y != 0:
        #   if sender_y <= my_y:
        #     my_y += change_y
        # elif change_x != 0:
        #   if sender_x <= my_x:
        #     my_x += change_x
    

  #def connectionMade(self):

  def connectionLost(self, reason):
    userManager.rem_user(self.user)
    if userManager.is_empty():
      print 'All users disconnected. Shutting down...'
      reactor.stop()

class ReactFactory(Factory):
  def __init__(self):
    self.buff = []
  def initiate(self, port):
    self.port = port
    print 'Now listening on port '+str(port)+'...'
    reactor.listenTCP(port,self)
    reactor.run()
  def buildProtocol(self, addr):
    return React(self) 


class Cursor:
  def __init__(self):
    self.x = 1
    self.y = 1

  def to_json(self):
    return {
      'x': self.x,
      'y': self.y
    }


class User:
  def __init__(self, name, protocol):
    self.name = name
    self.protocol = protocol
    self.cursor = Cursor()

  def to_json(self):
    return {
      'name': self.name,
      'cursor': self.cursor.to_json()
    }

  def broadcast_packet(self, obj, send_to_self = False):
    for name, user in userManager.users.iteritems():
      if user.name != self.name or send_to_self:
        user.protocol.transport.write(pickle.dumps(obj))
        #TODO: don't send yourself your own buffer, but del on a copy doesn't work

  def update_cursor(self, x, y):
    self.cursor.x = x
    self.cursor.y = y


class UserManager:
  def __init__(self):
    self.users = {}
  
  def is_empty(self):
    return len(self.users)==0
  
  def is_multi(self):
    return len(self.users)>1
  
  def has_user(self, search_name):
    return self.users.has_key(search_name)
  
  def add_user(self,u):
    self.users[u.name] = u
  
  def get_user(self, u_name):
    try:
      return self.users[u_name]
    except KeyError:
      raise Exception('user doesnt exist')

  def rem_user(self, user):
    if self.users.has_key(user.name):
      d = {
        'packet_type':'message',
        'data': {
          'message_type':'user_disconnected',
          'name':user.name
        }
      }
      user.broadcast_packet(d)
      print 'User "'+user.name+'" Disconnected'
      del self.users[user.name]
  
  def update_cursors(self, buffer_data, u):
    return_arr = []
    y_target = u.cursor.y
    for name, user in userManager.users.iteritems():
      if user != u:
        print str(user.cursor.y) +','+ str(y_target)
        if user.cursor.y > y_target:
          user.cursor.y += buffer_data['change_y']
          return_arr.append(user.to_json())
    return return_arr
    #update all users cursors
      #if cursor is after change 
        #update it, then add user to cursor array





userManager = UserManager()

if __name__ == '__main__':
  Server = ReactFactory()
  Server.initiate(int(sys.argv[1]))

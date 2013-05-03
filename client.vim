if !has('python')
  echo "Error: Required vim compiled with +python"
  finish
endif
:hi Cursor1 ctermbg=DarkRed ctermfg=White guibg=DarkRed guifg=White gui=bold term=bold cterm=bold 
:hi Cursor2 ctermbg=DarkBlue ctermfg=White guibg=DarkBlue guifg=White gui=bold term=bold cterm=bold 
:hi Cursor3 ctermbg=DarkGreen ctermfg=White guibg=DarkGreen guifg=White gui=bold term=bold cterm=bold 
:hi Cursor4 ctermbg=DarkCyan ctermfg=White guibg=DarkCyan guifg=White gui=bold term=bold cterm=bold 
:hi Cursor5 ctermbg=DarkMagenta ctermfg=White guibg=DarkMagenta guifg=White gui=bold term=bold cterm=bold 
:hi Cursor6 ctermbg=Brown ctermfg=White guibg=Brown guifg=White gui=bold term=bold cterm=bold 
:hi Cursor7 ctermbg=LightRed ctermfg=Black guibg=LightRed guifg=Black gui=bold term=bold cterm=bold 
:hi Cursor8 ctermbg=LightBlue ctermfg=Black guibg=LightBlue guifg=Black gui=bold term=bold cterm=bold 
:hi Cursor9 ctermbg=LightGreen ctermfg=Black guibg=LightGreen guifg=Black gui=bold term=bold cterm=bold 
:hi Cursor10 ctermbg=LightCyan ctermfg=Black guibg=LightCyan guifg=Black gui=bold term=bold cterm=bold 
:hi Cursor0 ctermbg=LightYellow ctermfg=Black guibg=LightYellow guifg=Black gui=bold term=bold cterm=bold 


:python import vim
python << EOF

from twisted.internet.protocol import ClientFactory, Protocol
#from twisted.protocols.basic import LineReceiver
from twisted.internet import reactor
#from twisted.internet.interfaces import IReactorThreads
from threading import Thread
import pickle
import os

class VimProtocol(Protocol):
  def __init__(self, fact):
    self.fact = fact
  def addUsers(self, list):
    for name in list:
      self.fact.colors[name] = ('Cursor' + str(self.fact.color_count), self.fact.id_count)
      self.fact.id_count += 1
      self.fact.color_count = (self.fact.id_count-3)%11
      vim.command('call matchadd(\''+self.fact.colors[name][0]+'\', \'\%'+ \
                  '0v.\%0l\', 10, ' + str(self.fact.colors[name][1])+ ')')
      self.refreshBuddyList()
  def remUser(self, name):
    vim.command('call matchdelete('+str(self.fact.colors[name][1]) + ')')
    del(self.fact.colors[name])
    self.refreshBuddyList()
  def refreshBuddyList(self):
    CoVim.buddylist[:] = [' '.join(self.fact.colors.keys())+' ']
    current_window_i = vim.eval('winnr()')
    x_a = 1
    vim.command("1wincmd w")
    for match_id in self.fact.buddylist_matches:
      vim.command('call matchdelete('+str(match_id) + ')')
    self.fact.buddylist_matches = []
    for name in self.fact.colors.keys():
      x_b = x_a + len(name)
      self.fact.buddylist_matches.append(vim.eval('matchadd(\''+self.fact.colors[name][0]+'\',\'\%<'+str(x_b)+'v.\%>'+str(x_a)+'v\',10,'+str(self.fact.colors[name][1]+5000)+')'))
      x_a = x_b + 1
    vim.command(str(current_window_i)+"wincmd w")
  def send(self, event):
      self.transport.write(event)
  def connectionMade(self):
    self.send(self.fact.me)
  def dataReceived(self, data_string):
    packet = pickle.loads(data_string)	
    if 'packet_type' in packet.keys():
      (my_y,my_x) = vim.current.window.cursor
      data = packet['data']
      if 'buffer' in data.keys():
        old_buffer = vim.current.buffer[:]
        new_buffer = data['buffer'].split('\n')
        vim.current.buffer[:] = new_buffer
      if packet['packet_type'] == 'message':
        if data['message_type'] == 'error_newname_taken':
          CoVim.disconnect()
          print 'ERROR: Name already in use. Please try a different name'
        if data['message_type'] == 'error_newname_spaces':
          CoVim.disconnect()
          print 'ERROR: No spaces alowed. Please try a different name'
        if data['message_type'] == 'connect_success':
          CoVim.setupWorkspace()
          self.addUsers(data['collaborators'])
          print 'Success! You\'re now connected to the shared document'
        if data['message_type'] == 'user_connected':
          self.addUsers([ data['name'] ])
          print data['name']+' connected to this document'
        if data['message_type'] == 'user_disconnected':
          self.remUser(data['name'])
          print data['name']+' disconnected from this document'
      if packet['packet_type'] == 'update':
        sender_x = max(1,data['x'])
        sender_y = data['y'] 
        print str(sender_x)+', '+str(sender_y)
        vim.command(':call matchdelete('+str(self.fact.colors[data['name']][1]) + ')')
        vim.command(':call matchadd(\''+self.fact.colors[data['name']][0]+'\', \'\%'+ \
                    str(sender_x) + 'v.\%'+str(sender_y)+'l\', 10, ' + \
                    str(self.fact.colors[data['name']][1])+ ')')
        #Correct Y
        change_y = len(new_buffer)-len(old_buffer)
        change_x = len(new_buffer[my_y-1])-len(old_buffer[my_y-1])
        if change_y != 0:
          if sender_y <= my_y:
            my_y += change_y
          #if sender_y == my_y:
        elif change_x != 0:
          if sender_x <= my_x:
            my_x += change_x
          #if sender_y == my_y:
        
      vim.command(':redraw')
      vim.current.window.cursor = (my_y, my_x) 

class VimFactory(ClientFactory):
  def __init__(self, name):
    self.id_count = 4
    self.setup(name)
  def setup(self, me=False):
    if me:
      self.me = me
    self.buddylist_matches = []
    self.colors = {}
    self.color_count = 1
  def buildProtocol(self, addr):
    self.p = VimProtocol(self)
    return self.p
  def startFactory(self):
    self.isConnected = True
  def stopFactory(self):
    self.isConnected = False
  def buff_update(self):
    d = {
      "packet_type":"update",
      "data": {
        "x":vim.current.window.cursor[1],
        "y":vim.current.window.cursor[0],
        "name":self.me,
        "buffer": '\n'.join(vim.current.buffer[:])
        }
    }
    data = pickle.dumps(d)
    self.p.send(data)
  def cursor_update(self):
    d = {
      "packet_type":"update",
      "data": {
        "x":vim.current.window.cursor[1]+1,
        "y":vim.current.window.cursor[0],
        "name":self.me,
        "buffer": '\n'.join(vim.current.buffer[:])
        }
    }
    data = pickle.dumps(d)
    self.p.send(data)
  def clientConnectionLost(self, connector, reason):
    #THIS IS A HACK
    if hasattr(CoVim, 'buddylist'):
      CoVim.disconnect()
      print 'Lost connection.'
  def clientConnectionFailed(self, connector, reason):
    CoVim.disconnect()
    print 'Connection failed.' 

class CoVimScope:
  #def __init__(self):
  def initiate(self, port, name):
    #Check if connected. If connected, throw error.
    if hasattr(self, 'fact') and self.fact.isConnected:
      print 'ERROR: Already connected. Please disconnect first'
      return
    if not port and hasattr(self, 'port') and self.port:
      port = self.port
    if not port or not name:
      print 'Syntax Error: Use form :Covim connect <port> <name>'  
      return
    port = int(port)
    if not hasattr(self, 'connection'):
      self.port = port
      self.fact = VimFactory(name)
      self.connection = reactor.connectTCP('localhost', port, self.fact)
      self.reactor_thread = Thread(target=reactor.run, args=(False,))
      self.reactor_thread.start()
    elif hasattr(self, 'port') and port != self.port:
      print 'ERROR: Different port '+self.port+' already used. To try another port restart Vim'
      return
    else:
      self.fact.setup(name)
      self.connection.connect()
      print 'Reconnecting...'
      return
    #if first time run, setup
    #if not connected, reconnect
    print 'Connecting...'
  def setupWorkspace(self):
    vim.command(':autocmd!')
    vim.command('autocmd CursorMoved * py CoVim.cursor_update()')
    vim.command('autocmd CursorMovedI * py CoVim.buff_update()')
    vim.command('autocmd VimLeave * py CoVim.quit()')
    vim.command("1new +setlocal\ stl=%!'CoVim-Collaborators'")
    self.buddylist = vim.current.buffer
    self.buddylist_window = vim.current.window
    vim.command("wincmd j")
  def command(self, arg1=False, arg2=False, arg3=False):
    if arg1=="connect":
      self.initiate(arg2, arg3)
    elif arg1=="disconnect":
      self.disconnect()
    elif arg1=="start":
      self.createServer(arg2, arg3)
    else:
      print "Sytax Error: '"+arg1+"' is not a command. Please use 'start', 'connect' or 'disconnect'."
  def createServer(self, port, name):
    os.system('./vimserver.py ' + port + ' &')
    self.initiate(port, name)
  def buff_update(self):
    reactor.callFromThread(self.fact.buff_update)
  def cursor_update(self):
    reactor.callFromThread(self.fact.cursor_update)
  def disconnect(self):
    if hasattr(self,'buddylist'):
      vim.command("1wincmd w")
      vim.command("q!")
      del(self.buddylist)
      del(self.buddylist_window)
    reactor.callFromThread(self.connection.disconnect)
    print 'Successfully disconnected from document!'
  def quit(self):
    reactor.callFromThread(reactor.stop)


CoVim = CoVimScope()
EOF

com! -nargs=* CoVim py CoVim.command(<f-args>)


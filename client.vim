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

#@NOTE: can't handle special characters, encodes to ascii
class VimProtocol(Protocol):
  def __init__(self, fact):
    self.fact = fact
    self.buddylist_matches = []
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
    for match_id in self.buddylist_matches:
      vim.command('call matchdelete('+str(match_id) + ')')
      self.buddylist_matches = []
    for name in self.fact.colors.keys():
      x_b = x_a + len(name)
      self.buddylist_matches.append(vim.eval('matchadd(\''+self.fact.colors[name][0]+'\',\'\%<'+str(x_b)+'v.\%>'+str(x_a)+'v\',10,'+str(self.fact.colors[name][1]+5000)+')'))
      x_a = x_b + 1
    vim.command(str(current_window_i)+"wincmd w")
  def send(self, event):
      self.transport.write(event)
  def connectionMade(self):
    self.send(self.fact.me)
  def dataReceived(self, data_string):
    packet = pickle.loads(data_string)	
    if 'packet_type' in packet.keys():
      data = packet['data']
      if 'buffer' in data.keys():
        vim.current.buffer[:] = data['buffer'].split('\n')
      if packet['packet_type'] == 'message':
        if data['message_type'] == 'error_newname_taken':
          print 'ERROR: Name already in use. Please try a different name'
        if data['message_type'] == 'error_newname_spaces':
          print 'ERROR: No spaces alowed. Please try a different name'
        if data['message_type'] == 'connect_success':
          self.addUsers(data['collaborators'])
          print 'Success! You\'re now connected to the shared document'
        if data['message_type'] == 'user_connected':
          self.addUsers([ data['name'] ])
          print data['name']+' connected to this document'
        if data['message_type'] == 'user_disconnected':
          self.remUser(data['name'])
          print data['name']+' disconnected from this document'
      if packet['packet_type'] == 'update':
        if 'x' in data.keys():
          cursor_x = max(1,data['x'])
          cursor_y = data['y'] 
          print str(cursor_x)+', '+str(cursor_y)
          vim.command(':call matchdelete('+str(self.fact.colors[data['name']][1]) + ')')
          vim.command(':call matchadd(\''+self.fact.colors[data['name']][0]+'\', \'\%'+ \
                      str(cursor_x) + 'v.\%'+str(cursor_y)+'l\', 10, ' + \
                      str(self.fact.colors[data['name']][1])+ ')')
    vim.command(':redraw')
    vim.current.window.cursor = vim.current.window.cursor

class VimFactory(ClientFactory):
  def __init__(self, name):
    self.me = name
    self.colors = {}
    self.color_count = 1
    self.id_count = 4
  def buildProtocol(self, addr):
    self.p = VimProtocol(self)
    return self.p
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

class CoVimScope:
  def initiate(self, port, name):
    port = int(port)
    self.fact = VimFactory(name)
    reactor.connectTCP('localhost', port, self.fact)
    reactor_thread = Thread(target=reactor.run, args=(False,))
    reactor_thread.start()
#TODO put this all in a vim function
    vim.command(':autocmd!')
    vim.command('autocmd CursorMoved * py CoVim.cursor_update()')
    vim.command('autocmd CursorMovedI * py CoVim.buff_update()')
    vim.command('autocmd VimLeave * py CoVim.leave()')
    vim.command("1new +setlocal\ stl=%!'CoVim-Collaborators'")
    self.buddylist = vim.current.buffer
    vim.command("wincmd j")
  def createServer(self, port, name):
    os.system('./vimserver.py ' + port + ' &')
    self.initiate(port, name)
  def buff_update(self):
    reactor.callFromThread(self.fact.buff_update)
  def cursor_update(self):
    reactor.callFromThread(self.fact.cursor_update)
  def leave(self):
    reactor.callFromThread(reactor.stop)
    
CoVim = CoVimScope()

EOF

com! -nargs=* CoVimStart py CoVim.createServer(<f-args>)
com! -nargs=* CoVimConnect py CoVim.initiate(<f-args>)
com! CoVimDisconnect py CoVim.leave()


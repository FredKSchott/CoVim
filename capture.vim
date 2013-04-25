if !has('python')
  echo "Error: Required vim compiled with +python"
  finish
endif
:hi Cursor1 ctermbg=DarkRed ctermfg=White guibg=DarkRed guifg=White
:hi Cursor2 ctermbg=DarkBlue ctermfg=White guibg=DarkBlue guifg=White
:hi Cursor3 ctermbg=DarkGreen ctermfg=White guibg=DarkGreen guifg=White
:hi Cursor4 ctermbg=DarkCyan ctermfg=White guibg=DarkCyan guifg=White
:hi Cursor5 ctermbg=DarkMagenta ctermfg=White guibg=DarkMagenta guifg=White
:hi Cursor6 ctermbg=Brown ctermfg=White guibg=Brown guifg=White
:hi Cursor7 ctermbg=LightRed ctermfg=Black guibg=LightRed guifg=Black
:hi Cursor8 ctermbg=LightBlue ctermfg=Black guibg=LightBlue guifg=Black
:hi Cursor9 ctermbg=LightGreen ctermfg=Black guibg=LightGreen guifg=Black
:hi Cursor10 ctermbg=LightCyan ctermfg=Black guibg=LightCyan guifg=Black
:hi Cursor0 ctermbg=LightYellow ctermfg=Black guibg=LightYellow guifg=Black

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
  def send(self, event):
      self.transport.write(event)
  def connectionMade(self):
    self.send(self.fact.me)
  def dataReceived(self, data_string):
    data = pickle.loads(data_string)	
    if 'name' in data.keys():
      if data['name'] not in self.fact.colors.keys():
        self.fact.colors[data['name']] = ('Cursor' + str(self.fact.color_count),
                                                         self.fact.id_count)
        vim.command(':call matchadd(\''+self.fact.colors[data['name']][0]+'\', \'\%'+ \
                    str(data['x']) + 'v.\%'+str(data['y'])+'l\', 10, ' + \
                    str(self.fact.colors[data['name']][1])+ ')')
        self.fact.color_count += 1
        self.fact.color_count %= 11
        self.fact.id_count += 1
    if 'message' in data.keys():
      message = data['message'].split()
      if len(message) == 3:
        if message[2] == 'disconnected!':
          vim.command(':call matchdelete('+str(self.fact.colors[message[0]][1]) + \
                      ')')
          del(self.fact.colors[message[0]])
      message = data['message']
      print message
    if 'buffer' in data.keys():
      vim.current.buffer[:] = data['buffer'].split('\n')
    if 'x' in data.keys():
      #vim.command(':match '+self.fact.colors[data['name']]+' /\%' + \
                  #str(data['x']-1) + 'v.\%'+str(data['y'])+'l/')
      vim.command(':call matchdelete('+str(self.fact.colors[data['name']][1]) + \
                  ')')
      vim.command(':call matchadd(\''+self.fact.colors[data['name']][0]+'\', \'\%'+ \
                  str(data['x']) + 'v.\%'+str(data['y'])+'l\', 10, ' + \
                  str(self.fact.colors[data['name']][1])+ ')')
      #vim.command(':call matchadd(\''+self.fact.colors[data['name']][0]+'\', \'\%'+ \
                  #str(data['x']) + 'v.\%'+str(data['y'])+'l\')')
      #vim.command(':match '+self.fact.colors[data['name']]+' /\%' + \
                  #str(data['x']) + 'v.\%'+str(data['y'])+'l/')
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
      'x':vim.current.window.cursor[1],
      'y':vim.current.window.cursor[0],
      'name':self.me,
      'buffer': '\n'.join(vim.current.buffer[:])
    }
    data = pickle.dumps(d)
    self.p.send(data)
  def cursor_update(self):
    d = {
      "x":vim.current.window.cursor[1]+1,
      "y":vim.current.window.cursor[0],
      "name":self.me,
    }
    data = pickle.dumps(d)
    self.p.send(data)

class MvimScope:
  
  def initiate(self, port, name):
    port = int(port)
    self.fact = VimFactory(name)
    reactor.connectTCP('localhost', port, self.fact)
    reactor_thread = Thread(target=reactor.run, args=(False,))
    reactor_thread.start()
    vim.command(':autocmd!')
    vim.command('autocmd CursorMovedI * py Mvim.buff_update()')
    vim.command('autocmd CursorMoved * py Mvim.cursor_update()')
    vim.command('autocmd VimLeave * py Mvim.leave()')
  def createServer(self, port, name):
    os.system('./vimserver.py ' + port + ' &')
    self.initiate(port, name)
  def buff_update(self):
    reactor.callFromThread(self.fact.buff_update)
  def cursor_update(self):
    reactor.callFromThread(self.fact.cursor_update)
  def leave(self):
    reactor.callFromThread(reactor.stop)
    
Mvim = MvimScope()

EOF

com! -nargs=* MvimStart py Mvim.createServer(<f-args>)
com! -nargs=* MvimConnect py Mvim.initiate(<f-args>)
com! MvimLeave py Mvim.leave()


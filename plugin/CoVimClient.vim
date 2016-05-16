"Check for Python Support"
if !has('python3')
    com! -nargs=* CoVim echoerr "Error: CoVim requires vim compiled with +python3"
    finish
endif

com! -nargs=* CoVim py3 CoVim.command(<f-args>)

"Needs to be set on connect, MacVim overrides otherwise"
function! SetCoVimColors ()
    hi CursorUser gui=bold term=bold cterm=bold
    hi Cursor1 ctermbg=DarkRed ctermfg=White guibg=DarkRed guifg=White gui=bold term=bold cterm=bold
    hi Cursor2 ctermbg=DarkBlue ctermfg=White guibg=DarkBlue guifg=White gui=bold term=bold cterm=bold
    hi Cursor3 ctermbg=DarkGreen ctermfg=White guibg=DarkGreen guifg=White gui=bold term=bold cterm=bold
    hi Cursor4 ctermbg=DarkCyan ctermfg=White guibg=DarkCyan guifg=White gui=bold term=bold cterm=bold
    hi Cursor5 ctermbg=DarkMagenta ctermfg=White guibg=DarkMagenta guifg=White gui=bold term=bold cterm=bold
    hi Cursor6 ctermbg=Brown ctermfg=White guibg=Brown guifg=White gui=bold term=bold cterm=bold
    hi Cursor7 ctermbg=LightRed ctermfg=Black guibg=LightRed guifg=Black gui=bold term=bold cterm=bold
    hi Cursor8 ctermbg=LightBlue ctermfg=Black guibg=LightBlue guifg=Black gui=bold term=bold cterm=bold
    hi Cursor9 ctermbg=LightGreen ctermfg=Black guibg=LightGreen guifg=Black gui=bold term=bold cterm=bold
    hi Cursor10 ctermbg=LightCyan ctermfg=Black guibg=LightCyan guifg=Black gui=bold term=bold cterm=bold
    hi Cursor0 ctermbg=LightYellow ctermfg=Black guibg=LightYellow guifg=Black gui=bold term=bold cterm=bold
endfunction

if !exists("CoVim_default_name")
    let CoVim_default_name = 0
endif
if !exists("CoVim_default_port")
    let CoVim_default_port = 0
endif

python3 << EOF

import vim
import os
import json
import warnings
from twisted.internet.protocol import ClientFactory, Protocol
from twisted.internet import reactor
from threading import Thread
from time import sleep

# Ignore Warnings
warnings.filterwarnings('ignore', '.*', UserWarning)
warnings.filterwarnings('ignore', '.*', DeprecationWarning)

# Find the server path
CoVimServerPath = vim.eval('expand("<sfile>:h")') + '/CoVimServer.py'

## CoVim Protocol
class CoVimProtocol(Protocol):
    def __init__(self, fact):
        self.fact = fact

    def send(self, event):
        self.transport.write(event.encode('utf-8'))

    def connectionMade(self):
        self.send(CoVim.username)

    def dataReceived(self, data_string):
        def clean_data_string(d_s):
            bad_data = d_s.find("}{")
            if bad_data > -1:
                d_s = d_s[:bad_data+1]
            return d_s
         
        if isinstance(data_string, bytes):
            data_string = data_string.decode('utf-8')
        data_string = clean_data_string(data_string)
        packet = json.loads(data_string)
        if 'packet_type' in packet.keys():
            data = packet['data']
            if packet['packet_type'] == 'message':
                if data['message_type'] == 'error_newname_taken':
                    CoVim.disconnect()
                    print('ERROR: Name already in use. Please try a different name')
                if data['message_type'] == 'error_newname_invalid':
                    CoVim.disconnect()
                    print('ERROR: Name contains illegal characters. Only numbers, letters, underscores, and dashes allowed. Please try a different name')
                if data['message_type'] == 'connect_success':
                    CoVim.setupWorkspace()
                    if 'buffer' in data.keys():
                        CoVim.vim_buffer = data['buffer']
                        vim.current.buffer[:] = CoVim.vim_buffer
                    CoVim.addUsers(data['collaborators'])
                    print('Success! You\'re now connected [Port '+str(CoVim.port)+']')
                if data['message_type'] == 'user_connected':
                    CoVim.addUsers([data['user']])
                    print(data['user']['name']+' connected to this document')
                if data['message_type'] == 'user_disconnected':
                    CoVim.remUser(data['name'])
                    print(data['name']+' disconnected from this document')
            if packet['packet_type'] == 'update':
                if 'buffer' in data.keys() and data['name'] != CoVim.username:
                    b_data = data['buffer']
                    CoVim.vim_buffer = vim.current.buffer[:b_data['start']]   \
                                                         + b_data['buffer']   \
                                                         + vim.current.buffer[b_data['end']-b_data['change_y']+1:]
                    vim.current.buffer[:] = CoVim.vim_buffer
                if 'updated_cursors' in data.keys():
                    # We need to update your own cursor as soon as possible, then update other cursors after
                    for updated_user in data['updated_cursors']:
                        if CoVim.username == updated_user['name'] and data['name'] != CoVim.username:
                            vim.current.window.cursor = (updated_user['cursor']['y'], updated_user['cursor']['x'])
                    for updated_user in data['updated_cursors']:
                        if CoVim.username != updated_user['name']:
                            vim.command(':call matchdelete(' + str(CoVim.collab_manager.collaborators[updated_user['name']][1]) + ')')
                            vim.command(':call matchadd(\'' + CoVim.collab_manager.collaborators[updated_user['name']][0] + '\', \'\%' + str(updated_user['cursor']['x']) + 'v.\%' + str(updated_user['cursor']['y']) + 'l\', 10, ' + str(CoVim.collab_manager.collaborators[updated_user['name']][1]) + ')')
                #data['cursor']['x'] = max(1,data['cursor']['x'])
                #print(str(data['cursor']['x'])+', '+str(data['cursor']['y'])
            vim.command(':redraw')


#CoVimFactory - Handles Socket Communication
class CoVimFactory(ClientFactory):

    def buildProtocol(self, addr):
        self.p = CoVimProtocol(self)
        return self.p

    def startFactory(self):
        self.isConnected = True

    def stopFactory(self):
        self.isConnected = False

    def buff_update(self):
        d = {
            "packet_type": "update",
            "data": {
                "cursor": {
                    "x": max(1, vim.current.window.cursor[1]),
                    "y": vim.current.window.cursor[0]
                },
                "name": CoVim.username
            }
        }
        d = self.create_update_packet(d)
        data = json.dumps(d)
        self.p.send(data)

    def cursor_update(self):
        d = {
            "packet_type": "update",
            "data": {
                "cursor": {
                    "x": max(1, vim.current.window.cursor[1]+1),
                    "y": vim.current.window.cursor[0]
                },
                "name": CoVim.username
            }
        }
        d = self.create_update_packet(d)
        data = json.dumps(d)
        self.p.send(data)

    def create_update_packet(self, d):
        current_buffer = vim.current.buffer[:]
        if current_buffer != CoVim.vim_buffer:
            cursor_y = vim.current.window.cursor[0] - 1
            change_y = len(current_buffer) - len(CoVim.vim_buffer)
            change_x = 0
            if len(CoVim.vim_buffer) > cursor_y-change_y and cursor_y-change_y >= 0 \
                and len(current_buffer) > cursor_y and cursor_y >= 0:
                change_x = len(current_buffer[cursor_y]) - len(CoVim.vim_buffer[cursor_y-change_y])
            limits = {
                'from': max(0, cursor_y-abs(change_y)),
                'to': min(len(vim.current.buffer)-1, cursor_y+abs(change_y))
            }
            d_buffer = {
                'start': limits['from'],
                'end': limits['to'],
                'change_y': change_y,
                'change_x': change_x,
                'buffer': vim.current.buffer[limits['from']:limits['to']+1],
                'buffer_size': len(current_buffer)
            }
            d['data']['buffer'] = d_buffer
            CoVim.vim_buffer = current_buffer
        return d

    def clientConnectionLost(self, connector, reason):
        #THIS IS A HACK
        if hasattr(CoVim, 'buddylist'):
            CoVim.disconnect()
            print('Lost connection.')

    def clientConnectionFailed(self, connector, reason):
        CoVim.disconnect()
        print('Connection failed.')


#Manage Collaborators
class CollaboratorManager:

    def __init__(self):
        self.collab_id_itr = 4
        self.reset()

    def reset(self):
        self.collab_color_itr = 1
        self.collaborators = {}
        self.buddylist_highlight_ids = []

    def addUser(self, user_obj):
        if user_obj['name'] == CoVim.username:
            self.collaborators[user_obj['name']] = ('CursorUser', 4000)
        else:
            self.collaborators[user_obj['name']] = ('Cursor' + str(self.collab_color_itr), self.collab_id_itr)
            self.collab_id_itr += 1
            self.collab_color_itr = (self.collab_id_itr-3) % 11
            vim.command(':call matchadd(\''+self.collaborators[user_obj['name']][0]+'\', \'\%' + str(user_obj['cursor']['x']) + 'v.\%'+str(user_obj['cursor']['y'])+'l\', 10, ' + str(self.collaborators[user_obj['name']][1]) + ')')
        self.refreshCollabDisplay()

    def remUser(self, name):
        vim.command('call matchdelete('+str(self.collaborators[name][1]) + ')')
        del(self.collaborators[name])
        self.refreshCollabDisplay()

    def refreshCollabDisplay(self):
        buddylist_window_width = int(vim.eval('winwidth(0)'))
        CoVim.buddylist[:] = ['']
        x_a = 1
        line_i = 0
        vim.command("1wincmd w")
        for match_id in self.buddylist_highlight_ids:
            vim.command('call matchdelete('+str(match_id) + ')')
        self.buddylist_highlight_ids = []
        for name in self.collaborators.keys():
            x_b = x_a + len(name)
            if x_b > buddylist_window_width:
                line_i += 1
                x_a = 1
                x_b = x_a + len(name)
                CoVim.buddylist.append('')
                vim.command('resize '+str(line_i+1))
            CoVim.buddylist[line_i] += name+' '
            self.buddylist_highlight_ids.append(vim.eval('matchadd(\''+self.collaborators[name][0]+'\',\'\%<'+str(x_b)+'v.\%>'+str(x_a)+'v\%'+str(line_i+1)+'l\',10,'+str(self.collaborators[name][1]+2000)+')'))
            x_a = x_b + 1
        vim.command("wincmd p")


#Manage all of CoVim
class CoVimScope:

    def initiate(self, addr, port, name):
        #Check if connected. If connected, throw error.
        if hasattr(self, 'fact') and self.fact.isConnected:
            print('ERROR: Already connected. Please disconnect first')
            return
        if not port and hasattr(self, 'port') and self.port:
            port = self.port
        if not addr and hasattr(self, 'addr') and self.addr:
            addr = self.addr
        if not addr or not port or not name:
            print('Syntax Error: Use form :Covim connect <server address> <port> <name>')
            return
        port = int(port)
        addr = str(addr)
        vim.command('autocmd VimLeave * py3 CoVim.quit()')
        if not hasattr(self, 'connection'):
            self.addr = addr
            self.port = port
            self.username = name
            self.vim_buffer = []
            self.fact = CoVimFactory()
            self.collab_manager = CollaboratorManager()
            self.connection = reactor.connectTCP(addr, port, self.fact)
            self.reactor_thread = Thread(target=reactor.run, args=(False,))
            self.reactor_thread.start()
            print('Connecting...')
        elif (hasattr(self, 'port') and port != self.port) or (hasattr(self, 'addr') and addr != self.addr):
            print('ERROR: Different address/port already used. To try another, you need to restart Vim')
        else:
            self.collab_manager.reset()
            self.connection.connect()
            print('Reconnecting...')

    def createServer(self, port, name):
        vim.command(':silent execute "!'+CoVimServerPath+' '+port+' &>/dev/null &"')
        sleep(0.5)
        self.initiate('localhost', port, name)

    def setupWorkspace(self):
        vim.command('call SetCoVimColors()')
        vim.command(':autocmd!')
        vim.command('autocmd CursorMoved <buffer> py3 reactor.callFromThread(CoVim.fact.cursor_update)')
        vim.command('autocmd CursorMovedI <buffer> py3 reactor.callFromThread(CoVim.fact.buff_update)')
        vim.command('autocmd VimLeave * py3 CoVim.quit()')
        vim.command("1new +setlocal\ stl=%!'CoVim-Collaborators'")
        self.buddylist = vim.current.buffer
        self.buddylist_window = vim.current.window
        vim.command("wincmd j")

    def addUsers(self, userlist):
        list(map(self.collab_manager.addUser, userlist))

    def remUser(self, name):
        self.collab_manager.remUser(name)

    def refreshCollabDisplay(self):
        self.collab_manager.refreshCollabDisplay()

    def command(self, arg1=False, arg2=False, arg3=False, arg4=False):
        default_name = vim.eval('CoVim_default_name')
        default_name_string = " - default: '"+default_name+"'" if default_name != '0' else ""
        default_port = vim.eval('CoVim_default_port')
        default_port_string = " - default: "+default_port if default_port != '0' else ""
        if arg1 == "connect":
            if arg2 and arg3 and arg4:
                self.initiate(arg2, arg3, arg4)
            elif arg2 and arg3 and default_name != '0':
                self.initiate(arg2, arg3, default_name)
            elif arg2 and default_port != '0' and default_name != '0':
                self.initiate(arg2, default_port, default_name)
            else:
                print("usage :CoVim connect [host address / 'localhost'] [port"+default_port_string+"] [name"+default_name_string+"]")
        elif arg1 == "disconnect":
            self.disconnect()
        elif arg1 == "quit":
            self.exit()
        elif arg1 == "start":
            if arg2 and arg3:
                self.createServer(arg2, arg3)
            elif arg2 and default_name != '0':
                self.createServer(arg2, default_name)
            elif default_port != '0' and default_name != '0':
                self.createServer(default_port, default_name)
            else:
                print("usage :CoVim start [port"+default_port_string+"] [name"+default_name_string+"]")
        else:
            print("usage: CoVim [start] [connect] [disconnect] [quit]")

    def exit(self):
        if hasattr(self, 'buddylist_window') and hasattr(self, 'connection'):
            self.disconnect()
            vim.command('q')
        else:
            print("ERROR: CoVim must be running to use this command")

    def disconnect(self):
        if hasattr(self, 'buddylist'):
            vim.command("1wincmd w")
            vim.command("q!")
            self.collab_manager.buddylist_highlight_ids = []
            for name in self.collab_manager.collaborators.keys():
                if name != CoVim.username:
                    vim.command(':call matchdelete('+str(self.collab_manager.collaborators[name][1]) + ')')
            del(self.buddylist)
        if hasattr(self, 'buddylist_window'):
            del(self.buddylist_window)
        if hasattr(self, 'connection'):
            reactor.callFromThread(self.connection.disconnect)
            print('Successfully disconnected from document!')
        else:
            print("ERROR: CoVim must be running to use this command")

    def quit(self):
        reactor.callFromThread(reactor.stop)

CoVim = CoVimScope()

EOF

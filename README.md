#CoVim - Collaborative Editting for Vim
CoVim adds real-time collaboration to your favorite (or least favorite) text editor. Think Google Docs for Vim.

##Features
- Multiple users can edit the same document
- Simple setup & use
- Works with your existing configuration

##Hello, World(s)!
1. Add client.vim & server.py to your plugin folder (~/.vim/plugin/)
2. Open Vim
3. To start a new CoVim server: `:CoVim start [port] [name]`
4. To connect to a running server: `:CoVim connect [host address / 'localhost'] [port] [name]`

##FAQ / Troubleshooting
__Q: How do files work with CoVim? Are we all editing one file? Our own copies?__  
A: CoVim never saves a file. It simply modifies your buffer (whatever's being displayed in the window) allowing you to save a copy of the working collaboration to file anytime. 

__Q: Why do I get an import error every time I start Vim?__  
A: Make sure Vim is using a version of Python that includes Twisted (2.5+), and that it's linking to the right libraries. See [this post](https://github.com/Valloric/YouCompleteMe/issues/241) for more info on debugging & fixing.

__Q: Why doesn't CoVim support X?__  
A: New features are being added all the time. Check back in a bit or (even better) contribute!

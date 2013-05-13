#CoVim - Collaborative Editting for Vim
CoVim adds multi-user, real-time collaboration to your favorite (or least favorite) text editor. Think Google Docs for Vim.

##Hello, World(s)!
1. Add client.vim & server.py to your plugin folder (~/.vim/plugin/)
2. Open Vim
3. To start a new CoVim server: `:CoVim start [port] [name]`
4. To connect to a running server: `:CoVim connect [host address / 'localhost'] [port] [name]`

##Troubleshooting
__Q: I get an import error every time I start Vim__  
A: Make sure Vim is using a version of Python that includes Twisted (2.5+), and that it's linking to the right libraries. See [this post](https://github.com/Valloric/YouCompleteMe/issues/241) for info on debugging & fixing.


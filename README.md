#CoVim - Collaborative Editting for Vim
CoVim adds multi-user, real-time collaboration to your favorite (or least favorite) text editor. Think Google Docs for Vim.

##First, Start Your Server
1. `./server [port]`

##Then, Start Your Clients
1. Add client.vim to your plugin folder (~/.vim/plugin/)
1. Open Vim 
2. `:CoVim connect [host address] [port] [name]`

##Troubleshooting
__Q: I get an import error every time I start Vim__  
A: Make sure Vim is using a version of Python that includes Twisted, and that it's able to find the right libraries. See [this post](https://github.com/Valloric/YouCompleteMe/issues/241) for info on debugging & fixing.


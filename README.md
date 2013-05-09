#CoVim - Collaborative Editting for Vim
CoVim adds multi-user, real-time collaboration to your favorite (or least favorite) text editor. Think Google Docs for Vim.

##First, Start Your Server
1. `./server [port]`

##Then, Start Each Client
1. Add client.vim to your plugin folder (~/.vim/plugin/)
1. Open Vim 
2. `:CoVim connect [port] [name]`

##Troubleshooting
__Q: I get an import error every time I start Vim__  
A: Vim uses whatever version of Python was most recent when it was installed. Been a while? Update Vim (simply `brew install vim` on Mac).


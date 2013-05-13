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
A: Most likely, Your MacVim binaries are linked against your system python instead of homebrew's. You can double check using otool.  
`otool -L [/usr/local/bin/vim` (find your vim location using `which vim`)  
If you see the /System/.../Python.framework in there then that's your issue.

You can relink the binary against homebrew's version of the framework without recompiling...  
`install_name_tool` -change [old Python.framework] [current Python.framework] /usr/local/bin/vim`



Vim uses whatever version of Python was most recent when it was installed. Been a while? Update Vim (simply `brew install vim` on Mac).


#CoVim - Collaborative Editting for Vim
One of Vim's [most requested features](http://www.vim.org/sponsor/vote_results.php) is here!  
__CoVim__ is a Vim Plugin that adds real-time collaboration to your favorite text editor (think Google Docs for Vim).

![Demo Gif](http://i.imgur.com/6iSettg.gif "Demo Gif")

###Features
- Allows multiple users to edit the same document
- Displays collaborators working on current document, with their cursor colors 
- Works with your existing configuration
- Easy to setup and use

###Hello, World(s)!
1. Double-check you have twisted library installed: `pip install twisted`
2. Add client.vim & server.py to your plugin folder: `~/.vim/plugin/`
3. Open Vim
4. To start a new CoVim server: `:CoVim start [port] [name]`
5. To connect to a running server: `:CoVim connect [host address / 'localhost'] [port] [name]`

####[FAQ / Troubleshooting](https://github.com/FredKSchott/CoVim/wiki/FAQ---Troubleshooting)

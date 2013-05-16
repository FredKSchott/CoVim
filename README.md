#CoVim - Collaborative Editing for Vim
One of Vim's [most requested features](http://www.vim.org/sponsor/vote_results.php) is here!  

##What this is
CoVim is a Vim Plugin that adds real-time collaboration to your favorite text editor. Think Google Docs for Vim.  
__More info can be found on the [announcement post!](http://www.fredkschott.com/post/50510962864/introducing-covim-collaborative-editing-for-vim)__

![Demo Gif](http://i.imgur.com/6iSettg.gif "Demo Gif")

##Features
- Allows multiple users to connect to the same document online
- Displays collaborators with individual cursors 
- Works with your existing configuration
- Easy to set up & use

##Hello, World(s)!
1. Double-check you have twisted library installed: `pip install twisted`
2. Add client.vim & server.py to your plugin folder: `~/.vim/plugin/` or install through Vundle/Pathogen
3. Open Vim
4. To start a new CoVim server: `:CoVim start [port] [name]`
5. To connect to a running server: `:CoVim connect [host address / 'localhost'] [port] [name]`
6. To disconnect: `Quit Vim` or `:CoVim disconnect`

##Links
__[Announcement Post](http://www.fredkschott.com/post/50510962864/introducing-covim-collaborative-editing-for-vim)__  
__[FAQ / Troubleshooting](https://github.com/FredKSchott/CoVim/wiki/FAQ-&-Troubleshooting)__

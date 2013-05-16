#CoVim - Collaborative Editing for Vim
One of Vim's [most requested features](http://www.vim.org/sponsor/vote_results.php) is here!  

##What this is
CoVim is a Vim Plugin that adds real-time collaboration to your favorite text editor. Think Google Docs for Vim.  
__More info can be found on the [announcement post!](http://www.fredkschott.com/post/50510962864/introducing-covim-collaborative-editing-for-vim)__

![Demo Gif](http://i.imgur.com/bjk4Ze5.gif "Demo Gif")

##Features
- Allows multiple users to connect to the same document online
- Displays collaborators with individual cursors 
- Works with your existing configuration
- Easy to set up & use

##Hello, World(s)!
1. Double-check you have twisted library installed: `pip install twisted`
2. Add client.vim & server.py to your plugin folder: `~/.vim/plugin/` or install through Vundle/Pathogen
3. Open Vim
4. To start a new CoVim server: `:CoVim start [port] [name]` (from the command line: `./server.py [port]`)
5. To connect to a running server: `:CoVim connect [host address / 'localhost'] [port] [name]`
6. To disconnect: `Quit Vim` or `:CoVim disconnect`
=======
##Installation

Before installation, Double-check you have twisted library installed:
* For apt-get based distros: `sudo apt-get install python-twisted`
* For yum based distros: `sudo yum install python-twisted`
* If all else fails: `pip install twisted`

Install via one of the 3 methods:

A) Using [Pathogen](https://github.com/tpope/vim-pathogen):
```
cd ~/.vim/bundle
git clone git://github.com/FredKSchott/CoVim.git
```

B) Using [Vundle](https://github.com/gmarik/vundle):
Add `Bundle 'FredKSchott/CoVim'` to your `~/.vimrc` and then:
* either within Vim `:BundleInstall`
* or in your shell: `vim +BundleInstall +qall`

c) Manual Installation: 

Add plugin/client.vim & plugin/server.py to your local plugin folder: `~/.vim/plugin/`


##Usage
1. Open Vim
2. To start a new CoVim server: `:CoVim start [port] [name]`
3. To connect to a running server: `:CoVim connect [host address / 'localhost'] [port] [name]`
4. To disconnect: `Quit Vim` or `:CoVim disconnect`


##Links
__[Announcement Post](http://www.fredkschott.com/post/50510962864/introducing-covim-collaborative-editing-for-vim)__  
__[FAQ / Troubleshooting](https://github.com/FredKSchott/CoVim/wiki/FAQ-&-Troubleshooting)__

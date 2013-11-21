#CoVim - Collaborative Editing for Vim
One of Vim's [most requested features](http://www.vim.org/sponsor/vote_results.php) is here!  
CoVim is a Vim Plugin that adds  real-time collaboration to your favorite text editor. Think Google Docs for Vim.  
__Follow [@FredKSchott](http://www.twitter.com/fredkschott) for development news and updates!__


![Demo Gif](http://i.imgur.com/CZeKkAI.gif "Demo Gif")

##Features
- Allows multiple users to connect to the same document online
- Displays collaborators with uniquely colored cursors 
- Works with your existing configuration
- Easy to set up & use
- And [More!](http://www.fredkschott.com/post/50510962864/introducing-covim-collaborative-editing-for-vim)

##Installation

CoVim requires a version of Vim compiled with python 2.5+. Visit [Troubleshooting](https://github.com/FredKSchott/CoVim/wiki#troubleshooting) if you're having trouble starting Vim.
Also note that the Twisted & Argparse libraries can also be installed via apt-get & yum.

####Install With [Pathogen](https://github.com/tpope/vim-pathogen):

1. `pip install twisted argparse`
2. `cd ~/.vim/bundle`
3. `git clone git://github.com/FredKSchott/CoVim.git`  

####Install With [Vundle](https://github.com/gmarik/vundle):

1. `pip install twisted argparse`
2. Add `Bundle 'FredKSchott/CoVim'` to your `~/.vimrc`
3. `vim +BundleInstall +qall`

####Install Manually:

1. `pip install twisted argparse`
2. Add `CoVimClient.vim` & `CoVimServer.py` to `~/.vim/plugin/`

***
If Vim is having trouble finding modules (twisted, argparse, etc) do the following:

1. run `pip show MODULE_NAME` and get the `Location:` path
2. add the following line to your .vimrc: `python import sys; sys.path.append("/module/location/path/")`
3. Repeat until all modules are included in your path

##Usage
__To start a new CoVim server:__ `:CoVim start [port] [name]` (or, from the command line: `./server.py [port]`)  
__To connect to a running server:__ `:CoVim connect [host address / 'localhost'] [port] [name]`  
__To disconnect:__ `:CoVim disconnect`  
__To quit Vim while CoVim is connected:__ `:CoVim quit` or `:qall!`


##Customization
####Add any the following to your .vimrc to customize CoVim:

```
let CoVim_default_name = "YOURNAME"
let CoVim_default_port = "YOURPORT"  
```

##Links
__[Announcement Post](http://www.fredkschott.com/post/50510962864/introducing-covim-collaborative-editing-for-vim)__  
__[FAQ](https://github.com/FredKSchott/CoVim/wiki#faq)__  
__[Troubleshooting](https://github.com/FredKSchott/CoVim/wiki#troubleshooting)__

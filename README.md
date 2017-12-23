<img src="http://fredkschott.com/img/CoVim_Icon.png" width="46" height="46" /> CoVim
==========================
Collaborative Editing for Vim (One of Vim's [most requested features](http://www.vim.org/sponsor/vote_results.php)) is finally here! Think Google Docs for Vim. 

__By: Fred Schott, Sam Haney__  
__Follow [@FredKSchott](http://www.twitter.com/fredkschott) for development news and updates!__

 


![Demo Gif](http://i.imgur.com/CZeKkAI.gif "Demo Gif")

## Features
- Allows multiple users to connect to the same document online
- Displays collaborators with uniquely colored cursors 
- Works with your existing configuration
- Easy to set up & use
- And [More!](http://fredkschott.com/post/2013/05/introducing-covim-real-time-collaboration-for-vim/)

## Installation

CoVim requires a version of Vim compiled with python 3.0+. Visit [Troubleshooting](https://github.com/FredKSchott/CoVim/wiki#troubleshooting) if you're having trouble starting Vim.
Also note that the Twisted & Argparse libraries can also be installed via apt-get & yum.

#### Install With [Pathogen](https://github.com/tpope/vim-pathogen):

1. `pip3 install twisted argparse service_identity`
2. `cd ~/.vim/bundle`
3. `git clone git://github.com/FredKSchott/CoVim.git`  

#### Install With [Vundle](https://github.com/gmarik/vundle):

1. `pip3 install twisted argparse service_identity`
2. Add `Plugin 'FredKSchott/CoVim'` to your `~/.vimrc`
3. `vim +PluginInstall +qall`

#### Install Manually:

1. `pip3 install twisted argparse service_identity`
2. Add `CoVimClient.vim` & `CoVimServer.py` to `~/.vim/plugin/`

> If Vim is having trouble finding modules (twisted, argparse, etc) do the following:
> 
> 1. run `pip3 show MODULE_NAME` and get the `Location:` path
> 2. add the following line to your .vimrc: `python3 import sys; sys.path.append("/module/location/path/")` using the module path found in step 1.
> 3. Repeat until all modules are included in your path
> 
> If you're still having trouble, [visit the wiki](https://github.com/FredKSchott/CoVim/wiki) for additional troubleshooting & FAQ 

## Usage
__To start a new CoVim server:__ `:CoVim start [port] [name]` (or, from the command line: `./CoVimServer.py [port]`)  
__To connect to a running server:__ `:CoVim connect [host address / 'localhost'] [port] [name]`  
__To disconnect:__ `:CoVim disconnect`  
__To quit Vim while CoVim is connected:__ `:CoVim quit` or `:qall!`


## Customization
#### Add any the following to your .vimrc to customize CoVim:

```
let CoVim_default_name = "YOURNAME"
let CoVim_default_port = "YOURPORT"  
```

## Links
__[Announcement Post](http://www.fredkschott.com/post/50510962864/introducing-covim-collaborative-editing-for-vim)__  
__[FAQ](https://github.com/FredKSchott/CoVim/wiki#faq)__  
__[Troubleshooting](https://github.com/FredKSchott/CoVim/wiki#troubleshooting)__


## Special Thanks
Tufts Professor [Ming Chow](http://www.linkedin.com/in/mchow01) for leading the [Senior Capstone Project](http://tuftsdev.github.io/SoftwareEngineering/) that CoVim was born in.  

[![Analytics](https://ga-beacon.appspot.com/UA-39778226-2/CoVim/Readme.md)](https://github.com/igrigorik/ga-beacon)


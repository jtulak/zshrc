My ZSH config
===============
This config is a preconfigured package with [Oh My Zsh](https://ohmyz.sh), with a modified Agnoster theme.

![A screenshot with the config](screenshot.png)

Installation
------------
There are some dependencies, all are packed in, but need to be installed:
 
 - powerline fonts (`cd /dependencies/powerline-fonts; ./install.sh`)
 - solarized color theme for terminal - just a soft dependency, iterm2 already has it as a built-in option
    - I have included `/custom_solarized.itermcolors` color theme for Iterm2 to make Solarized a bit more contrasting.

To use this config, run
```
git clone git@github.com:jtulak/zshrc.git $HOME/.zsh
$HOME/.zsh/install.sh
```

Alternatively, you can do the steps manually:
 
```
git clone git@github.com:jtulak/zshrc.git $HOME/.zsh
$HOME/.zsh/dependencies/powerline-fonts/install.sh
mv $HOME/.zshrc $HOME/.zshrc.backup
ln -s $HOME/.zsh/zshrc $HOME/.zshrc
chsh /bin/zsh
```

Description
------------
How it differs from a plain oh-my-zsh + Agnoster
- display time
    - when you run a command, the last prompt will update its time to `now` 
    - if a command runs more than a few seconds, its duration will be printed out in the following prompt
- slightly modified git status, to be more verbose about local/remote differences
- easily extendable status segment
    - create `/private/agnoster_private_status.zsh` and everything that this script prints out will be added to the dark segment right after time
- useful scripts
    - `show_all_colors` will print a table of available colors, so you can use it to tune the colors to your taste
    - `is_host_reachable` checks with ping the availability of a hostname, prints it out nicely and returns an appropriate exit code
    - `gl` is an `git log` wrapper
    - Aliases are in `/rc/alias.rc`


Directories and paths
---------------------
All settings put into `/private/` directory are ignored by git and can be used stuff that should not be published, be it passwords (plaintext is bad) or proprietary stuff. `/private/private.rc` file is sourced automatically, so you can link everything from it.

The directories `/bin/` and `/private/bin/` are included in `$PATH`.

You can use a shared global `.gitconfig` if you link it with `/rc/gitconfig` (I suggest using include, not a symlink here - just like the private config is included) and it will be extended with `/private/gitconfig`. However, note that these included configs are NOT set/shown for `--global` git flag. Only the very first file in the chain is considered so. 

In general, if a file has `.rc` suffix, it's intended to be sourced. If `.zsh` or something else, it's runnable file or some other config.

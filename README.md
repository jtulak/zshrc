My ZSH config
===============
This config is a preconfigured package with [Oh My Zsh](https://ohmyz.sh), with a modified Agnoster theme.

![A screenshot with the config](screenshot.png)

Installation
------------
There are some dependencies, all are packed in, but need to be installed:
 
 - powerline fonts (`cd /dependencies/powerline-fonts; ./install.sh`)
 - solarized color theme for terminal - just a soft, nice looking dependency, iterm2 already has it as a built-in option
    - I have included `/custom_solarized.itermcolors` color theme for Iterm2. It's based on solarized, but I keep tweaking it and it slowly drifts away from the original theme.

There are some additional plugins for oh-my-zsh. To download them when you clone this repo, run:
```
git submodule update --init --recursive
```


To use this config, run
```
git clone git@github.com:jtulak/zshrc.git $HOME/.zsh
$HOME/.zsh/install.sh
```
When you have it installed locally, you run a simplified installation for root user as well with: `sudo ./install_for_root.sh`. However, this takes some shortcuts, because it assumes you are going to use root only through `sudo` and so it skips the fonts. If you log in to root directly, you might need to do a full installation.

Alternatively, you can run the installation manually:
 ```
git clone git@github.com:jtulak/zshrc.git $HOME/.zsh
$HOME/.zsh/dependencies/powerline-fonts/install.sh
mv $HOME/.zshrc $HOME/.zshrc.backup
ln -s $HOME/.zsh/zshrc $HOME/.zshrc
chsh /bin/zsh
```

Post-install
------------
After you installed the configs, you should change at least `DEFAULT_USER` in `zshrc` to the user for which you want to hide `user@hostname` part of the prompt. If you want to have different colors for different hosts/users, use `before_zsh.rc` file (either in `/rc` or in `/private`) to set `PROMPT_CONTEXT_FG_COLOR` and `PROMPT_CONTEXT_BG_COLOR`.

If you want to use Python 3 virtual environments, install `virtualenv` and `mkvenv` packages (e.g. through pip), and, if you don't have `python` executable in your `PATH` (like if you are on a Mac), put `export AUTOSWITCH_DEFAULT_PYTHON="/usr/bin/python3"` into `/private/before_zsh.rc`.

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
All settings put into `/private/` directory are ignored by git and can be used stuff that should not be published, be it passwords (plaintext is bad, use system wallets) or proprietary stuff. `/private/private.rc` file is sourced automatically, so you can link everything from it.

The directories `/bin/` and `/private/bin/` are included in `$PATH`.

You can use a shared global `.gitconfig` if you link it with `/rc/gitconfig` (I suggest using include, not a symlink here - just like the private config is included) and it will be extended with `/private/gitconfig`. However, note that these included configs are NOT set/shown for `--global` git flag. Only the very first file in the chain is considered so. 

In general, if a file has `.rc` suffix, it's intended to be sourced. If `.zsh` or something else, it's runnable file or some other config. Almost all `.rc` files are sourced *after* ZSH prompt was rendered. The only exception is `before_zsh.rc`, which you can use to alter oh-my-zsh config just before it gets loaded.

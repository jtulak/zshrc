# Ops cheatsheet

Daily
- New tmux session or attach: tmux new -As main (see [tmux.conf](tmux.conf))
- Reload ZSH after edits: exec zsh
- List active aliases: alias

oh-my-zsh
- Check update reminder configuration in [zshrc](zshrc:56) and frequency in [zshrc](zshrc:59)
- Plugin set lives in [zshrc](zshrc:106) and customizations under [oh-my-zsh-custom/](oh-my-zsh-custom/)

SSH agent
- Lazy ssh-agent behavior is configured in [zshrc](zshrc:95)
- Verify loaded keys: ssh-add -l

Ansible
- See [memory/ansible.md](memory/ansible.md) for flows and pointers.

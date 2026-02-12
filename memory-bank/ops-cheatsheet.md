# Ops cheatsheet

Daily
- New tmux session or attach: tmux new -As main (see [tmux.conf](tmux.conf))
- Reload ZSH after edits: exec zsh
- List active aliases: alias

oh-my-zsh
- Check update reminder configuration in [zshrc](zshrc:56) and frequency in [zshrc](zshrc:59)
- Plugin set lives in [zshrc](zshrc:106) and customizations under [oh-my-zsh-custom/](oh-my-zsh-custom/)

Colors
- Preview current theme: [bin/show_all_colors](bin/show_all_colors:1)
- Semantic mapping: [rc/colors.rc](rc/colors.rc:1); detection: [rc/prompt-capabilities.rc](rc/prompt-capabilities.rc:1). Overrides: PROMPT_COLOR_MODE, SOLARIZED_THEME.
 
 SSH agent
- Lazy ssh-agent behavior is configured in [zshrc](zshrc:95)
- Verify loaded keys: ssh-add -l
 
 Ansible
- See [memory/ansible.md](memory/ansible.md) for flows and pointers.

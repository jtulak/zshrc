# ZSH setup and prompt

Overview
- This environment uses oh-my-zsh with a custom theme and layered configuration.
- Main entrypoint: [zshrc](zshrc:1)

Core paths and variables
- MAIN_ZSH is set in [zshrc](zshrc:29)
- ZSH (oh-my-zsh location) is set in [zshrc](zshrc:30)
- ZSH_CUSTOM is set in [zshrc](zshrc:92)

Theme
- Selected theme: my_agnoster configured in [zshrc](zshrc:36)
- Custom theme implementation and overrides live under [oh-my-zsh-custom/](oh-my-zsh-custom/)

Plugins
- Plugins configured in [zshrc](zshrc:106):
  - macos
  - dotenv
  - zsh-256color
  - autoswitch_virtualenv
  - ssh-agent
  - iterm2
  - pyenv

Update policy and performance
- oh-my-zsh update reminder configured in [zshrc](zshrc:56) with frequency in [zshrc](zshrc:59)
- VCS status optimization DISABLE_UNTRACKED_FILES_DIRTY set in [zshrc](zshrc:82)
- Lazy ssh-agent is enabled via zstyle in [zshrc](zshrc:95)

Layering and sourcing order
- Early hooks: [rc/before_zsh.rc](rc/before_zsh.rc:1) if present, and optional [private/before_zsh.rc](private/before_zsh.rc:1), referenced in [zshrc](zshrc:98)
- oh-my-zsh core is loaded in [zshrc](zshrc:108)
- Main snippets sourced from [zshrc](zshrc:139):
  - [rc/options.rc](rc/options.rc:1)
  - [rc/env.rc](rc/env.rc:1)
  - [rc/alias.rc](rc/alias.rc:1)
- Optional machine-local: [private/private.rc](private/private.rc:1), referenced in [zshrc](zshrc:143)

Notes
- Files under [private/](private/) are deliberately untracked and out of scope for this memory bank.
- To apply changes, open a new shell or run exec zsh in your terminal.

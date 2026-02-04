# Decisions (ADR-lite)

ADR-0001: Theme selection
- Decision: Use custom theme my_agnoster configured in [zshrc](zshrc:36)
- Rationale: Enhanced visibility of git status and prompt aesthetics; consistent across machines via [oh-my-zsh-custom/](oh-my-zsh-custom/)

ADR-0002: Plugin set
- Decision: Use plugins configured in [zshrc](zshrc:106): macos, dotenv, zsh-256color, autoswitch_virtualenv, ssh-agent, iterm2, pyenv
- Rationale: Productivity on macOS and Linux, environment management, color handling, and SSH usability

ADR-0003: Update cadence and performance
- Decision: oh-my-zsh update reminder mode configured in [zshrc](zshrc:56) with frequency in [zshrc](zshrc:59); speed optimizations via [zshrc](zshrc:82)
- Rationale: Keep base up to date while minimizing startup overhead in large repositories

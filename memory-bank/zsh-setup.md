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
  - `uv` on every platform
  - `ssh-agent` on non-macOS hosts only; macOS uses its system-managed agent

Update policy and performance
- oh-my-zsh update reminder configured in [zshrc](zshrc:56) with frequency in [zshrc](zshrc:59)
- VCS status optimization DISABLE_UNTRACKED_FILES_DIRTY set in [zshrc](zshrc:82)
- Git prompt branch and tracked state are refreshed once per prompt from a porcelain-v2 status snapshot. With `DISABLE_UNTRACKED_FILES_DIRTY=true`, untracked presence is refreshed asynchronously and the active ZLE prompt is safely redrawn when the marker changes; foreground programs are not affected. `AGNOSTER_GIT_UNTRACKED_CACHE_TTL` controls idle refreshes and defaults to five seconds (`0` probes after every prompt; commands always schedule a probe).
- Upstream ahead/behind counts are cached for five seconds by default and can be overridden with non-negative integer `AGNOSTER_GIT_REMOTE_CACHE_TTL` (`0` disables caching; invalid values use five seconds).
- The optimized Git prompt requires Git 2.17 or newer and never fetches from a remote.
- ZLE records the displayed row count across the primary editor and any secondary-prompt continuation sessions. Once `preexec` confirms that the complete command will execute, it uses that count to update the original timestamp and restores the output cursor. If the original prompt has scrolled outside the terminal viewport, the rewrite is skipped rather than risking visible corruption.
- Lazy ssh-agent is enabled via zstyle on non-macOS hosts in [zshrc](zshrc:95)

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
- Colors: semantic COLOR_* variables are defined in [rc/colors.rc](rc/colors.rc:1) with capability detection (truecolor/256/16) from [rc/prompt-capabilities.rc](rc/prompt-capabilities.rc:1). Override PROMPT_COLOR_MODE or SOLARIZED_THEME if required. Preview with [bin/show_all_colors](bin/show_all_colors:1).
- To apply changes, open a new shell or run exec zsh in your terminal.

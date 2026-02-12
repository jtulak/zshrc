# Agent guidance for ~/.zsh repository

Purpose
- This repository contains a portable ZSH environment for macOS and Linux using oh-my-zsh with an enhanced Agnoster theme, layered configs, helper scripts, and Ansible automation. Some OS-specific features such as keyring integration may use alternate code paths or be unavailable depending on the platform.

Start here
- Read this file fully, then consult the memory bank in [memory-bank/](memory-bank/).
- Key anchors in the repo:
  - Main shell config: [zshrc](zshrc:1)
  - Multiplexer config: [tmux.conf](tmux.conf)
  - Automation: [ansible/](ansible/)
  - Utilities: [bin/](bin/)
  - Config snippets: [rc/](rc/)
  - Oh My Zsh customizations: [oh-my-zsh-custom/](oh-my-zsh-custom/)
  - Vendored deps: [dependencies/](dependencies/)

Memory bank
- Location: [memory-bank/](memory-bank/). Use this for durable context and decisions.
- Entry docs:
  - Overview and map: [memory-bank/repo-overview.md](memory-bank/repo-overview.md)
  - ZSH and prompt setup: [memory-bank/zsh-setup.md](memory-bank/zsh-setup.md)
  - Ansible usage: [memory-bank/ansible.md](memory-bank/ansible.md)
  - Daily ops cheatsheet: [memory-bank/ops-cheatsheet.md](memory-bank/ops-cheatsheet.md)
  - Conventions and style: [memory-bank/conventions.md](memory-bank/conventions.md)
  - Do-not-track policy: [memory-bank/do-not-track.md](memory-bank/do-not-track.md)
  - Decisions (ADR-lite): [memory-bank/decisions.md](memory-bank/decisions.md)

Critical constraints for agents
- Never access or reference contents of [private/](private/). This directory is intentionally out of scope for VCS and documentation.
- Do not run tests, builds, or long-running processes unless explicitly instructed.
- Prefer read-first workflows. Summarize intent, propose a plan, and get confirmation before making edits.
- Keep changes minimal, portable, and idempotent.
- Respect the host OS environment; default shell is zsh. Typical locations: macOS [/bin/zsh], Linux [/usr/bin/zsh] or as installed by the distro.

Conventions that affect tools and linking
- Use clickable links for files and code with the format [name](relative/path:line optional). Examples: [zshrc](zshrc:1), [ansible/install_here.yaml](ansible/install_here.yaml:1).
- When referring to theme, plugins, and colors, note that:
  - Theme is set to my_agnoster in [zshrc](zshrc:36)
  - Plugins are configured in [zshrc](zshrc:106)
  - oh-my-zsh core load occurs at [zshrc](zshrc:108)
  - Layered sourcing occurs around [zshrc](zshrc:98) and [zshrc](zshrc:139)
  - Semantic prompt colors are centralized in [rc/colors.rc](rc/colors.rc:1) and depend on detection in [rc/prompt-capabilities.rc](rc/prompt-capabilities.rc:1) (PROMPT_COLOR_MODE, SOLARIZED_THEME). The theme consumes COLOR_* variables.

Recommended analysis workflow
- Identify task and scope boundaries.
- Review [zshrc](zshrc:1) for the relevant settings and sourcing order.
- Consult the appropriate memory-bank document under [memory-bank/](memory-bank/) for background and conventions.
- If automation is involved, prefer dry runs and idempotence. For Ansible, see [memory-bank/ansible.md](memory-bank/ansible.md) and review [ansible/](ansible/) structure before execution.
- Avoid assumptions about machine-local secrets; if needed, assume they live under [private/](private/) and are not to be read.

When adding or updating knowledge
- Update the relevant document under [memory-bank/](memory-bank/).
- Record rationale in [memory-bank/decisions.md](memory-bank/decisions.md) when you make non-trivial changes.
- Ensure all links are clickable using the [name](relative/path:line optional) format.

Operational notes
- Primary workstation is macOS Tahoe (26). Linux distributions are also supported; OS-specific features such as keyring integration and path defaults may differ.
- oh-my-zsh path is set via ZSH in [zshrc](zshrc:30) and custom path via ZSH_CUSTOM in [zshrc](zshrc:92).
- SSH agent is configured to be lazy via zstyle in [zshrc](zshrc:95).

Out of scope
- Do not index, read, or write inside [private/](private/). Reference only its existence.

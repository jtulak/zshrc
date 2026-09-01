# Memory bank for ~/.zsh repository

Owner: Jan Tulak <jan.tulak@oracle.com>

Scope and intent
- Purpose: durable, navigable knowledge about this repository to speed setup, maintenance, and transfer across hosts.
- Boundaries: do not include secrets; do not reference or mirror anything inside [private/](private/). That directory is intentionally out of scope for VCS and for this memory bank.
- Audience: future you on a fresh Mac, and trusted collaborators.

Repository anchors
- Primary entrypoints and notable directories:
  - [zshrc](zshrc:1) — main ZSH configuration, sources snippets from [rc/](rc/) and sets oh-my-zsh defaults from [dependencies/](dependencies/) and [oh-my-zsh-custom/](oh-my-zsh-custom/).
  - [tmux.conf](tmux.conf) — tmux configuration for terminal multiplexing.
  - [ansible/](ansible/) — automation for setup/update/upload to another host.
  - [bin/](bin/) — shell utilities used interactively and by automation.
  - [rc/](rc/) — configuration snippets layered by [zshrc](zshrc:1).
  - [oh-my-zsh-custom/](oh-my-zsh-custom/) — enhanced theme and plugin overrides for oh-my-zsh.
  - [install_ansible.sh](install_ansible.sh) — bootstrap helper; [install_for_root.sh](install_for_root.sh) deliberately rejects root installation.
  - [.gitmodules](.gitmodules) — only oh-my-zsh and powerline-fonts are maintained as submodules.

Index of memory topics
- Overview and map: [memory-bank/repo-overview.md](memory-bank/repo-overview.md)
- ZSH and prompt setup: [memory-bank/zsh-setup.md](memory-bank/zsh-setup.md)
- Ansible usage and workflows: [memory-bank/ansible.md](memory-bank/ansible.md)
- Daily ops cheatsheet: [memory-bank/ops-cheatsheet.md](memory-bank/ops-cheatsheet.md)
- Conventions and style: [memory-bank/conventions.md](memory-bank/conventions.md)
- Do-not-track and secrets policy: [memory-bank/do-not-track.md](memory-bank/do-not-track.md)
- Decisions (ADR-lite): [memory-bank/decisions.md](memory-bank/decisions.md)

Quickstart bootstrap
- New machine minimal path:
  - Review [install_ansible.sh](install_ansible.sh) and [install_for_root.sh](install_for_root.sh).
  - Run Ansible per [memory-bank/ansible.md](memory-bank/ansible.md) to achieve idempotent setup.
  - Verify shell loads [zshrc](zshrc:1) and applies theme/plugins from [oh-my-zsh-custom/](oh-my-zsh-custom/).

Update workflow for this memory bank
- When adding or changing behavior, record:
  - What changed in [memory-bank/decisions.md](memory-bank/decisions.md) (brief context and rationale).
  - Where it lives (link files like [zshrc](zshrc:1), [rc/](rc/), or [ansible/](ansible/)).
  - How to use it (update the relevant topic doc above).
- Keep references workspace-relative and clickable, e.g. [zshrc](zshrc:1) or [ansible/README.md](ansible/README.md).

Conventions
- Never place secrets in this repo. Use environment variables, OS keychains, or machine-local files under [private/](private/) which is not tracked.
- Prefer portable shell and idempotent automation.
- Keep links clickable and stable: [name](relative/path:line optional). Include a line anchor when linking to code blocks inside files like [zshrc](zshrc:1).

Current plugin set
- `uv` is loaded on every platform.
- `ssh-agent` is loaded lazily on non-macOS hosts only; macOS uses its system-managed agent.

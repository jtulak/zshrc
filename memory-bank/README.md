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
  - [install_ansible.sh](install_ansible.sh) and [install_for_root.sh](install_for_root.sh) — bootstrap helpers.

Index of memory topics
- Overview and map: [memory/repo-overview.md](memory/repo-overview.md)
- ZSH and prompt setup: [memory/zsh-setup.md](memory/zsh-setup.md)
- Ansible usage and workflows: [memory/ansible.md](memory/ansible.md)
- Daily ops cheatsheet: [memory/ops-cheatsheet.md](memory/ops-cheatsheet.md)
- Conventions and style: [memory/conventions.md](memory/conventions.md)
- Do-not-track and secrets policy: [memory/do-not-track.md](memory/do-not-track.md)
- Decisions (ADR-lite): [memory/decisions.md](memory/decisions.md)

Quickstart bootstrap
- New machine minimal path:
  - Review [install_ansible.sh](install_ansible.sh) and [install_for_root.sh](install_for_root.sh).
  - Run Ansible per [memory/ansible.md](memory/ansible.md) to achieve idempotent setup.
  - Verify shell loads [zshrc](zshrc:1) and applies theme/plugins from [oh-my-zsh-custom/](oh-my-zsh-custom/).

Update workflow for this memory bank
- When adding or changing behavior, record:
  - What changed in [memory/decisions.md](memory/decisions.md) (brief context and rationale).
  - Where it lives (link files like [zshrc](zshrc:1), [rc/](rc/), or [ansible/](ansible/)).
  - How to use it (update the relevant topic doc above).
- Keep references workspace-relative and clickable, e.g. [zshrc](zshrc:1) or [ansible/README.md](ansible/README.md).

Conventions
- Never place secrets in this repo. Use environment variables, OS keychains, or machine-local files under [private/](private/) which is not tracked.
- Prefer portable shell and idempotent automation.
- Keep links clickable and stable: [name](relative/path:line optional). Include a line anchor when linking to code blocks inside files like [zshrc](zshrc:1).

Planned documents
- This README intentionally links to documents that will be created next:
  - [memory/repo-overview.md](memory/repo-overview.md): high-level directory map and Mermaid diagram.
  - [memory/zsh-setup.md](memory/zsh-setup.md): oh-my-zsh, enhanced Agnoster theme "my_agnoster", plugins, and layering from [rc/](rc/) and [oh-my-zsh-custom/](oh-my-zsh-custom/).
  - [memory/ansible.md](memory/ansible.md): playbooks and typical flows.
  - [memory/ops-cheatsheet.md](memory/ops-cheatsheet.md): routine commands.
  - [memory/conventions.md](memory/conventions.md): scripting and layout expectations.
  - [memory/do-not-track.md](memory/do-not-track.md): policy and examples.
  - [memory/decisions.md](memory/decisions.md): ADR-lite log.

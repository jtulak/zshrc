# Ansible usage

Purpose
- Automate setup, updates, and configuration upload for macOS and Linux hosts.

Location and bootstrap
- Automation lives in [ansible/](ansible/)
- Bootstrap helpers at repo root:
  - [install_ansible.sh](install_ansible.sh)
  - [install_for_root.sh](install_for_root.sh)
- A Python venv for modern Ansible may exist at [.venv/ansible-modern/](.venv/ansible-modern/)

Typical flows (light docs)
- Local bootstrap
  - Inspect [install_ansible.sh](install_ansible.sh) for dependencies and environment preparation.
  - Optionally install or activate [.venv/ansible-modern/](.venv/ansible-modern/).
- Apply configuration
  - Use ansible-playbook against the target host or localhost for idempotent changes.
  - Review inventory and variables under [ansible/](ansible/) before execution.
- Update host
  - Re-run the appropriate playbook. Expect idempotence with no-op runs when already configured.

Conventions
- Dry run first: ansible-playbook ... --check
- Increase verbosity only as needed: -v or -vv
- Keep secrets outside VCS under [private/](private/) and use Ansible vars or environment references where appropriate.

Notes
- Exact playbook names and structure may evolve; this memory-bank intentionally keeps the overview high-level and avoids enumerating every file.

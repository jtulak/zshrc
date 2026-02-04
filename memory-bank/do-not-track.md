# Do-not-track and secrets policy

Scope
- The [private/](private/) directory is intentionally excluded from version control and from this memory bank.

Patterns
- Early and local overrides may reside in [private/before_zsh.rc](private/before_zsh.rc:1), referenced in [zshrc](zshrc:98)
- Machine-local settings may reside in [private/private.rc](private/private.rc:1), referenced in [zshrc](zshrc:143)

Guidance
- Never commit secrets, tokens, or machine-unique files.
- Prefer OS keychain, environment variables, or untracked files under [private/](private/).
- When documenting behavior here, reference only the existence of private hooks, not their contents.

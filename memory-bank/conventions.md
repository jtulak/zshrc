# Conventions and style

General
- Keep configuration portable across macOS and Linux machines.
- Layer configuration: base in [zshrc](zshrc:1), shared snippets in [rc/](rc/), oh-my-zsh customizations in [oh-my-zsh-custom/](oh-my-zsh-custom/), machine-local in [private/](private/).

Shell scripting
- Prefer POSIX-compatible constructs where reasonable; document zsh-specific features when used.
- Avoid leaking secrets or machine-specific paths into tracked files.
- Keep scripts idempotent when they modify system state.

Repository layout
- Use [rc/options.rc](rc/options.rc:1) for setopt and shell options, [rc/env.rc](rc/env.rc:1) for environment variables, and [rc/alias.rc](rc/alias.rc:1) for aliases.
- Theme and plugin customizations live under [oh-my-zsh-custom/](oh-my-zsh-custom/); core is loaded by [zshrc](zshrc:108).

Documentation
- Keep links clickable using the pattern [name](relative/path:line optional) and include a line when referring to a specific directive in files like [zshrc](zshrc:36).

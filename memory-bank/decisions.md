# Decisions (ADR-lite)

ADR-0001: Theme selection
- Decision: Use custom theme my_agnoster configured in [zshrc](zshrc:36)
- Rationale: Enhanced visibility of git status and prompt aesthetics; consistent across machines via [oh-my-zsh-custom/](oh-my-zsh-custom/)

ADR-0002: Plugin set
- Decision: Use the portable plugins configured in [zshrc](zshrc:106): ssh-agent and uv.
- Rationale: Retain lazy SSH-agent management and Python environment support without loading unused terminal-specific helpers or rewriting terminal capability declarations.

ADR-0003: Update cadence and performance
- Decision: oh-my-zsh update reminder mode configured in [zshrc](zshrc:56) with frequency in [zshrc](zshrc:59); speed optimizations via [zshrc](zshrc:82)
- Rationale: Keep base up to date while minimizing startup overhead in large repositories

ADR-0004: Semantic color mapping
- Decision: Centralize prompt colors in [rc/colors.rc](rc/colors.rc:1) with capability-driven fallbacks (truecolor/256/16) via [rc/prompt-capabilities.rc](rc/prompt-capabilities.rc:1). The theme consumes COLOR_* variables.
- Rationale: Consistent, portable colors with graceful degradation; single source of truth for theme colors.

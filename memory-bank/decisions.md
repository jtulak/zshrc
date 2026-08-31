# Decisions (ADR-lite)

ADR-0001: Theme selection
- Decision: Use custom theme my_agnoster configured in [zshrc](zshrc:36)
- Rationale: Enhanced visibility of git status and prompt aesthetics; consistent across machines via [oh-my-zsh-custom/](oh-my-zsh-custom/)

ADR-0002: Plugin set
- Decision: Load `uv` on every platform and the lazy `ssh-agent` plugin only on non-macOS hosts, as configured in [zshrc](zshrc:106).
- Rationale: macOS provides a system-managed SSH agent, while Linux hosts still benefit from lazy agent startup. Keep Python environment support portable without loading unused terminal-specific helpers.

ADR-0003: Update cadence and performance
- Decision: oh-my-zsh update reminder mode configured in [zshrc](zshrc:56) with frequency in [zshrc](zshrc:59); speed optimizations via [zshrc](zshrc:82)
- Rationale: Keep base up to date while minimizing startup overhead in large repositories

ADR-0004: Semantic color mapping
- Decision: Centralize prompt colors in [rc/colors.rc](rc/colors.rc:1) with capability-driven fallbacks (truecolor/256/16) via [rc/prompt-capabilities.rc](rc/prompt-capabilities.rc:1). The theme consumes COLOR_* variables.
- Rationale: Consistent, portable colors with graceful degradation; single source of truth for theme colors.

ADR-0005: Git prompt snapshot and remote cache
- Decision: Refresh branch and tracked Git state once per prompt through a `precmd` hook and render the prompt from that snapshot. When untracked files do not affect dirty coloring, detect them in one generation-tagged background worker and redraw only through ZLE after completion; keep synchronous detection when they do affect dirty coloring. Compute ahead/behind counts with one `rev-list --left-right --count` call and cache them for five seconds by repository, branch/upstream, and HEAD identity. Configure the remote TTL with `AGNOSTER_GIT_REMOTE_CACHE_TTL` and the idle untracked refresh with `AGNOSTER_GIT_UNTRACKED_CACHE_TTL`; `0` disables the respective cache interval.
- Rationale: Preserve current tracked status while removing synchronous untracked enumeration from large repositories. ZLE owns asynchronous redraws, so multiline edit buffers are preserved and foreground programs are untouched. Remote means the locally fetched upstream reference; the prompt never performs network operations. The optimized path requires Git 2.17 or newer.

ADR-0006: Execution-time prompt timestamp redraw
- Decision: Use composable ZLE `line-init` and `line-finish` hooks only to accumulate `BUFFERLINES` across the primary editor and any secondary-prompt continuation sessions. Perform the timestamp rewrite from `preexec`, after Zsh has accepted the complete command, using the measured row distance and save/restore cursor escapes. Skip the rewrite if the original prompt has scrolled outside the terminal viewport.
- Rationale: `line-finish` is also called when an incomplete line transitions from `PS1` to `PS2`, so it cannot identify command execution. `preexec` has the correct lifecycle semantics, while ZLE's `BUFFERLINES` supplies layout information that includes visual wrapping without reconstructing terminal rows from command text.

ADR-0007: Portable default shell and root installation
- Decision: Discover the installed Zsh executable from the target host's `PATH` after prerequisite installation instead of assuming `/bin/zsh`. Keep `install_for_root.sh` as an explicit failing guard rather than installing this environment for root.
- Rationale: Zsh can live at different absolute paths across supported macOS and Linux hosts. Root should retain a minimal, independently managed login environment rather than inheriting this user-oriented configuration.

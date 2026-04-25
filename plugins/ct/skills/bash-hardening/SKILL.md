---
name: bash-hardening
description: >
  Deep bash correctness intuition — the subtle traps in `set -euo pipefail`,
  IFS / word-splitting, quoting, parameter expansion, `[[ ]]` vs `[ ]` vs `(( ))`,
  trap inheritance, process substitution, arrays, version-gated features, and
  ShellCheck-flagged "looks right but isn't" patterns.
  Load ONLY when the task is writing or hardening non-trivial bash scripts —
  installers, CI pipelines, ops tooling, anything that must run unattended.
  Do NOT load for "what is a shell", basic if/while/for syntax, one-shot
  interactive commands, or zsh/fish/POSIX-sh-only work — those don't need this skill.
  Triggers on: "set -e not triggering", "errexit edge case", "pipefail",
  "nounset empty array", "IFS word splitting", "trap ERR", "trap EXIT cleanup",
  "process substitution", "PIPESTATUS", "associative array bash 3.2",
  "macOS bash", "shellcheck SC2086", "SC2155", "harden bash script",
  "robust bash", "shebang strict mode".
---

# Bash Hardening Guide

Concise correctness pointers for non-trivial bash. Surface the traps LLMs reliably miss when emitting "robust" scripts.

Assumes you can already write `if`/`while`/`for`, run `chmod +x`, and read a stack trace. This skill covers the **correctness layer** — the parts models gloss over: `set -e` exceptions, IFS, quoting, parameter expansion, trap inheritance, array gotchas, version differences.

## When to use

Load when the task is:
- Writing/auditing installers, CI scripts, ops tooling, release scripts
- Diagnosing a script that "should work" but silently does the wrong thing
- Adding `set -euo pipefail` or strict-mode hardening
- Trap / cleanup / signal handling
- Array manipulation with empty-array / strict-mode interactions
- Cross-platform bash (macOS 3.2 vs Linux 4+/5+)
- ShellCheck triage (SC2086, SC2046, SC2155, SC2015, SC2128, SC2178, SC2207)

**Do NOT load** for: trivial one-liners, interactive shell use, "what is `$PATH`", POSIX-sh-only constraints (dash/ash), zsh/fish — those don't need this skill.

## `set -euo pipefail` — what each option misses

`set -e` (errexit) does **not** trigger when the failing command is:
- Inside `&&` / `||` / `!` chains. `cmd1 && cmd2` — if `cmd1` fails, script continues.
- The condition of `if`, `while`, `until`. `if cmd; then ...` masks `cmd`'s failure.
- Inside a function called from any of the above contexts. Once disabled at the call site, errexit stops applying inside the function body.
- Inside command substitution: `foo=$(cmd_that_fails)` — exit status discarded. Use `set -o errexit; foo=$(cmd) || exit` or check `$?` immediately.
- Inside process substitution: `cat <(cmd_that_fails)` — exit silently discarded.

`set -E` (errtrace) propagates the `ERR` trap into functions, command substitutions, subshells. **Pair `set -eE` if you have an `ERR` trap** — without `-E`, the trap fires only at top level.

`set -u` (nounset) edge cases:
- `${var:-default}` and `${var-default}` are safe under `-u`.
- `"${arr[@]}"` of an empty array errors under `-u` in bash 4.3 and earlier (and was buggy through 5.0). Defensive form: `"${arr[@]:+${arr[@]}}"` or `"${arr[@]+${arr[@]}}"`.
- Always initialise arrays explicitly: `arr=()` — never assume `declare -a arr` is enough under `-u`.

`set -o pipefail`:
- Without it: `false | true` exits 0 (only last command's status counts).
- With it: pipeline exits with the rightmost non-zero status.
- For per-segment exit codes use `${PIPESTATUS[@]}` immediately after the pipeline (resets on next command).

`(( expr ))` and `let` return **non-zero when the result is zero**. Under `set -e`, `(( count = 0 ))` aborts the script. Defensive form: `(( count = 0 )) || true` or `count=0` plain assignment.

`local var=$(cmd)` masks `cmd`'s exit code — `local` itself returns 0. Same for `declare`, `export`, `readonly`. Split: `local var; var=$(cmd)`.

Recommended top-of-script: `set -Eeuo pipefail; IFS=$'\n\t'`.

## IFS and word splitting

- Default IFS is `$' \t\n'` (space, tab, newline). Unquoted expansions are split on **any** of these, then glob-expanded.
- `IFS=$'\n\t'` (Bash strict-mode idiom) defangs space-splitting — filenames with spaces survive `for f in $files`. Cost: any code that genuinely splits on spaces breaks.
- IFS is **global** — set inside a function, it leaks. Use `local IFS=...` inside functions.
- `"${arr[*]}"` joins elements with the **first character of IFS** (so with default IFS, a space). `"${arr[@]}"` keeps elements separate. Different operations, never interchangeable.
- `"$@"` (quoted) preserves each positional arg as one word; `$@` unquoted word-splits — same trap as `$*`.
- `read` honours IFS. `while IFS= read -r line` strips nothing — quoted-empty IFS preserves leading/trailing whitespace; `-r` disables backslash interpretation.

## Quoting reflexes

- Always quote variable expansions: `"$var"`, `"${arr[@]}"`, `"$(cmd)"`, `"${var/old/new}"`. Unquoted = word-split + glob.
- `[[ ]]` does **not** word-split RHS — `[[ $foo = bar ]]` works without quotes around `$foo`. `[ ]` does word-split — quote or you'll get "too many arguments" on values with spaces or empty values.
- Inside `[[ $a = $b ]]`, `$b` is treated as a **glob pattern**. Quote to compare literally: `[[ $a = "$b" ]]`. Inside `=~`, quoting the RHS makes it literal — for regex, leave RHS unquoted (or store the pattern in a variable and reference unquoted).
- Backticks `` `cmd` `` — use `$(cmd)` instead. Nestable, no backslash-escape weirdness.
- Tilde expansion does **not** happen inside double quotes: `"~/file"` is literal. Use `"$HOME/file"`.
- Heredoc: `<<EOF` expands `$var` and `$(cmd)`. `<<'EOF'` (quoted delimiter) treats body literally. `<<-EOF` strips **leading tabs only** (not spaces) — useful for indentation in scripts.

## `[[ ]]` vs `[ ]` vs `(( ))`

- `[[ ]]` — bash builtin. No word splitting on RHS, regex `=~`, glob match in `==`/`!=` (don't quote pattern), short-circuit `&&` / `||`. Bash/ksh/zsh only — not POSIX.
- `[ ]` — equivalent to `/usr/bin/test`. Subject to word splitting; **must** quote vars. POSIX. Avoid `-a`/`-o` (deprecated, ambiguous) — chain with `&&`/`||`: `[ -e "$f" ] && [ -r "$f" ]`.
- `(( ))` — arithmetic. Integer math, C-style (`++`, `**`, `%`, ternary). Variables auto-dereferenced — `(( x = y + 1 ))` not `(( x = $y + 1 ))`. Returns non-zero when result is 0 — see `set -e` interaction above.

## Parameter expansion (replace sed/awk for simple ops)

- `${var:-default}` — default if unset **or empty**.
- `${var-default}` — default if **unset only** (empty stays empty).
- `${var:=default}` — assign default if unset/empty.
- `${var:?msg}` — print `msg` to stderr and exit if unset/empty. Useful for required-arg checks.
- `${var:+alt}` — `alt` if set/non-empty (inverse of `:-`).
- `${#var}` — string length. `${#arr[@]}` — array element count.
- `${var:offset:length}` — substring. Negative offset needs space or parens: `${var: -3}` or `${var:(-3)}`.
- `${var#pat}` — strip shortest prefix match. `${var##pat}` — longest. (Mnemonic: `#` is at start of comments.)
- `${var%pat}` — strip shortest suffix. `${var%%pat}` — longest. (Mnemonic: `%` is at the end.)
- `${var/pat/repl}` — replace first match. `${var//pat/repl}` — replace all. `${var/#pat/repl}` — match at start. `${var/%pat/repl}` — match at end.
- `${var^^}` / `${var,,}` — upper/lower (bash 4+). `${var^}` / `${var,}` — first char only.
- `${!prefix*}` / `${!prefix@}` — names of variables matching prefix. `${!arr[@]}` — array indices/keys.

## Arrays

- Indexed: `arr=(a b "c d")`. Access: `${arr[0]}`, all elements `"${arr[@]}"`, indices `"${!arr[@]}"`, count `${#arr[@]}`.
- Associative: `declare -A m; m[key]=val` — **bash 4.0+**. macOS default bash is 3.2.57 (Apple stuck at last GPLv2 release) — `brew install bash` for 5+ or fall back to parallel indexed arrays.
- Append: `arr+=(d e)`. Single-element append: `arr+=(x)` not `arr+=x` (the latter concatenates to element 0).
- `"${arr[@]}"` — each element a separate word. `"${arr[*]}"` — single string joined by `IFS[0]`. Different.
- `mapfile -t lines < file` (or `readarray`) — read file into array, one line per element, `-t` trims newline. Bash 4+.
- A **bare `arr=value`** assigns to index 0 of an existing array — silent footgun if you meant to overwrite.

## Trap semantics

- Syntax: `trap 'cmd' EXIT INT TERM HUP ERR`. **Last `trap` for a signal wins** — they don't stack. To chain, read `trap -p SIG` and prepend.
- `EXIT` fires on **any** exit (clean, error, signal-after-handler). Idiomatic cleanup:
  ```bash
  tmpdir=$(mktemp -d)
  trap 'rm -rf -- "$tmpdir"' EXIT
  ```
- `ERR` fires only when `set -e` would. Without `set -E` (errtrace), it does **not** fire inside functions, command substitutions, or subshells — even though the failing command is "in" the script.
- `set -T` (functrace) similarly inherits `DEBUG` and `RETURN` traps into functions.
- Subshells (`( cmd )`, command substitution, pipeline segments) reset signal traps to their inherited disposition unless `-E`/`-T` set; `INT`/`TERM` are reset to default unless explicitly re-trapped.
- Ignore a signal during a critical section: `trap '' INT; critical_cmd; trap - INT` (`-` restores default).

## Process substitution and pipelines

- `<(cmd)` — bash makes `cmd`'s stdout available as a file path (`/dev/fd/N` or named FIFO). `>(cmd)` — same but for stdin. **Not POSIX** — bash/ksh/zsh only; don't use under `#!/bin/sh`.
- Exit status of the substituted command is **not propagated**. `cat <(false)` — `cat` reports success.
- Use it to fix the **subshell-loop trap**: `cmd | while read x; do count=$((count+1)); done` runs the loop in a subshell — `count` outside is unchanged. Rewrite as `while read x; do ...; done < <(cmd)` to keep the loop in the parent shell.
- Alternative: `shopt -s lastpipe` (bash 4.2+, only when job control is off — i.e. non-interactive scripts) makes the last pipeline segment run in the parent.

## Globbing options

- Default: a glob with no matches expands to the **literal pattern** — `for f in *.txt` iterates once with `f="*.txt"` if no `.txt` files exist.
- `shopt -s nullglob` — unmatched glob expands to nothing. Loop iterates zero times. Sane default for scripts.
- `shopt -s failglob` — unmatched glob is a hard error.
- `shopt -s globstar` — `**` matches recursively. Bash 4+.
- `shopt -s extglob` — `?(...)`, `*(...)`, `+(...)`, `@(...)`, `!(...)` extended patterns.
- `shopt -s dotglob` — globs match dotfiles.

## Common dangerous patterns

- `cmd | while read; do ...; done` — loop runs in subshell; mutations don't escape. Fix: `while read; do ...; done < <(cmd)` or `shopt -s lastpipe`.
- `eval "$user_input"` — almost always wrong. Replace with arrays, `declare -n` namerefs (bash 4.3+), or restructure.
- `[ "$a" = "$b" -a "$c" = "$d" ]` — `-a`/`-o` are deprecated and ambiguous. Use `[ "$a" = "$b" ] && [ "$c" = "$d" ]` or `[[ $a = $b && $c = $d ]]`.
- `cd $dir; rm -rf *` without quotes — word-splits and globs `$dir`. Quote: `cd "$dir"`.
- `A && B || C` is **not** if-then-else. If `A` succeeds and `B` fails, `C` runs anyway. Use a real `if`.
- `local var=$(cmd)` — `local` masks `cmd`'s exit. Split into two lines.
- `echo -n` / `echo -e` — non-portable (BSD `echo` differs). Use `printf '%s' "$var"` / `printf '%s\n' "$var"`.
- `find . -name '*.tmp' | xargs rm` — breaks on filenames with spaces/newlines. Use `find ... -print0 | xargs -0 rm` or `find ... -delete` or `find ... -exec rm {} +`.
- Backticks. Use `$( )`.

## Locale and portability

- `LC_ALL=C sort` (and `grep`, `comm`, `uniq`, `awk`) — deterministic byte-order, faster, avoids locale-dependent collation surprises (`A` vs `a` ordering, `[a-z]` not matching what you expect).
- `LC_NUMERIC=C printf '%f' 1.5` — decimal point stays `.`. Without it, locales like `de_DE` use `,` and `printf` errors.
- `#!/bin/bash` vs `#!/usr/bin/env bash` — the latter follows `$PATH`, picks up `brew install bash`'s 5.x on macOS instead of the 3.2.57 in `/bin/bash`.
- macOS-shipped bash is **3.2.57** — no associative arrays, no `mapfile`, no `${var^^}`, no `**` globstar, no `&>>`. Either require bash 4+ in your shebang/preamble or write to 3.2 floor.

## Tooling

- **ShellCheck** — run on every script. Top rules to internalise:
  - `SC2086` — quote variable expansions to prevent globbing/word-splitting.
  - `SC2046` — quote command substitution to prevent same.
  - `SC2155` — declare-and-assign masks exit code (`local x=$(cmd)`).
  - `SC2015` — `A && B || C` is not if-then-else.
  - `SC2128` — using array name without index gets element 0 only.
  - `SC2178` — assigning string to array variable.
  - `SC2207` — use `mapfile` or array assignment instead of `arr=( $(cmd) )`.
  - `SC2034` — variable defined but never used (often a typo).
- **shfmt** — formatter; pin a version in CI, run `shfmt -d` for diff-only check.
- **bats-core** — bash test framework when scripts get non-trivial.
- `set -x` — trace. Pair with `PS4='+ ${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]:-main}: '` for richer output.

## Authoritative references

**Official Bash manual** (`gnu.org/software/bash/manual`):
- [Shell Parameter Expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)
- [The Set Builtin](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html)
- [Arrays](https://www.gnu.org/software/bash/manual/html_node/Arrays.html)
- [The Shopt Builtin](https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html)

**Greg's Wiki / BashFAQ** (`mywiki.wooledge.org`):
- [BashFAQ/105 — Why doesn't `set -e` do what I expected?](https://mywiki.wooledge.org/BashFAQ/105)
- [BashPitfalls](https://mywiki.wooledge.org/BashPitfalls)
- [IFS](https://mywiki.wooledge.org/IFS)
- [BashFAQ/100 — String manipulation](https://mywiki.wooledge.org/BashFAQ/100)
- [SignalTrap](https://mywiki.wooledge.org/SignalTrap)
- [ProcessSubstitution](https://mywiki.wooledge.org/ProcessSubstitution)
- [ArithmeticExpression](https://mywiki.wooledge.org/ArithmeticExpression)
- [BashGuide/Practices](https://mywiki.wooledge.org/BashGuide/Practices)

**ShellCheck wiki** — every `SCxxxx` has its own page at `shellcheck.net/wiki/SCxxxx` (e.g. [SC2155](https://www.shellcheck.net/wiki/SC2155), [SC2015](https://www.shellcheck.net/wiki/SC2015)).

## Guardrails

Before recommending a non-trivial bash pattern (strict-mode preamble, trap, array idiom, parameter-expansion trick):

1. Quote the **specific** option / builtin / expansion form by name.
2. State the **bash version floor** if it matters (3.2 macOS / 4.0 / 4.3 / 4.4 / 5.0).
3. Cite the BashFAQ / Bash manual / ShellCheck rule for non-obvious behaviour.
4. Run `shellcheck` on the produced script and address every finding — silence only with an inline `# shellcheck disable=SCxxxx` plus a one-line reason.

**A bash script that passes ShellCheck is the floor, not the ceiling.**

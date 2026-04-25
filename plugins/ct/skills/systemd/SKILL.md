---
name: systemd
description: >
  Deep systemd / Linux init operational intuition — unit dependency semantics,
  service Type= internals, restart-throttle math, cgroup v2 resource control,
  hardening directive interactions, socket/timer activation, journald filtering,
  failure-mode triage (stuck-in-activating, restart loops, dependency cycles).
  Load ONLY when the task is about authoring or debugging systemd unit files,
  service-startup failure diagnosis, restart-loop triage, cgroup v2 limits,
  hardening sandbox tuning, socket/timer activation, or journalctl forensics.
  Do NOT load for ordinary `systemctl start|stop|status` usage, simple
  ExecStart edits, or basic boot questions — those don't need this skill.
  Triggers on: "stuck in activating", "restart loop", "start-limit hit",
  "Type=notify", "Type=forking", "PIDFile", "sd_notify", "BindsTo vs Requires",
  "PartOf", "DefaultDependencies", "ordering cycle", "MemoryMax",
  "MemoryHigh throttle", "CPUQuota", "CPUWeight", "ProtectSystem strict",
  "NoNewPrivileges", "SystemCallFilter", "socket activation",
  "Accept=yes template", "OnCalendar Persistent", "drop-in override",
  "systemctl edit", "systemd-analyze security", "systemd-analyze verify",
  "journalctl filter", "loginctl enable-linger", "user unit no XDG_RUNTIME_DIR",
  "cgroup v2 accounting".
---

# systemd Operational Guide

Concise operational pointers for systemd unit authoring, sandboxing, and incident triage on Linux.

Assumes you already know basic `systemctl` (start/stop/enable), can write a trivial `ExecStart=` line, and recognise unit file sections. This skill covers the **operational layer** — directive semantics that look the same and aren't, throttle math that surprises, cgroup v2 accounting, hardening combinatorics, and the failure modes models reliably mis-diagnose.

## When to use

Load when the question is about:
- Choosing between `Wants=`/`Requires=`/`Requisite=`/`BindsTo=`/`PartOf=` for cascade behaviour
- Picking `Type=` (`simple`/`exec`/`forking`/`oneshot`/`notify`/`dbus`/`idle`) and its ready-state contract
- Restart loops, start-limit hits, `RestartSec` / `StartLimitIntervalSec` / `StartLimitBurst` math
- Service stuck in `activating` (notify mis-config, forking PID race, dbus name not acquired)
- Resource limits via cgroup v2 (`MemoryMax`, `MemoryHigh`, `CPUQuota`, `CPUWeight`, `IOWeight`, `TasksMax`, `IPAccounting`)
- Hardening directives and their interactions (`NoNewPrivileges`, `Protect*`, `Private*`, `SystemCallFilter`, `Capability*`)
- Socket activation (`ListenStream`, `Accept=yes` template instances, `sd_listen_fds` protocol)
- Timer scheduling (`OnCalendar`, `Persistent`, `RandomizedDelaySec`, `AccuracySec`)
- Drop-in overrides via `systemctl edit`
- journald filtering, retention, vacuum, rate-limiting
- User units, `loginctl enable-linger`, `XDG_RUNTIME_DIR`
- Diagnostics: `systemd-analyze blame|critical-chain|verify|security|dot`

**Do NOT load** for: simple `systemctl status`, writing trivial `ExecStart=`, basic enable/disable, asking what a `.service` file is — those don't need this skill.

## Unit types — what each represents

- `service` — process(es); main lifecycle target
- `socket` — IPC/network listener, triggers a service on traffic (socket activation)
- `target` — synchronisation point, no processes; pulls in other units (`multi-user.target`, `basic.target`, `sysinit.target`, `shutdown.target`)
- `timer` — calendar/monotonic trigger for another unit (default: same name with `.service`)
- `mount` / `automount` — generated from `/etc/fstab` or written manually; `automount` lazy-mounts on access
- `path` — inotify watch on a path; activates a unit when the condition fires (`PathExists=`, `PathChanged=`, `DirectoryNotEmpty=`)
- `slice` — cgroup hierarchy node; **contains no processes**, only organises scopes/services. Default: `system.slice` for system units
- `scope` — externally-created cgroup wrapping non-systemd-spawned processes (login sessions, container runtimes); never written as a unit file
- `swap` — swap partition/file activation
- `device` — udev-backed; you don't author these

## Dependency directives — only one cascades both ways

Ordering (`Before=`/`After=`) and activation (`Wants=`/`Requires=`/...) are **independent axes**. `Requires=` without `After=` lets the dependent start in parallel and possibly succeed before its dep is ready.

| Directive | Forward start? | Failure of dep blocks me? | Stop of dep stops me? | Notes |
|---|---|---|---|---|
| `Wants=` | yes | no | no | Recommended default; weakest |
| `Requires=` | yes | only with `After=` | no | "Hard" only when ordered |
| `Requisite=` | **no** — fails immediately if dep not already active | yes | no | Pair with `After=` to avoid race |
| `BindsTo=` | yes | yes (with `After=`) | **yes** — dep going away takes me with it | Only directive that triggers on implicit dep state changes |
| `PartOf=` | **no** | no | stop/restart of dep cascades to me | One-way; useful for "child" services that should die with their parent |
| `Upholds=` | continuously restarts dep if it fails while I'm up | no | no | systemd 249+ |
| `Conflicts=` | starting either stops the other | n/a | n/a | Add `After=` to control order during the swap |
| `Before=`/`After=` | **ordering only** — does NOT pull in the unit | n/a | n/a | Reverses on shutdown |
| `JoinsNamespaceOf=` | shares `/tmp`, IPC, network ns with listed units | n/a | n/a | Requires `Private*=yes` on both sides; v209+ |
| `OnFailure=` / `OnSuccess=` | activates listed units on transition to failed/inactive | n/a | n/a | `OnFailureJobMode=replace` default |

`DefaultDependencies=yes` (default) auto-adds `Requires=sysinit.target` + `After=sysinit.target` + `After=basic.target` + `Conflicts=shutdown.target` + `Before=shutdown.target`. Setting `=no` is for **early-boot or late-shutdown units only** — silently disables the shutdown-conflict, so misuse leaves your service running through `poweroff`.

**Ordering cycle**: `systemd-analyze verify your.service` detects cycles. systemd breaks them by dropping a non-`Requires` ordering edge — which can boot a system in a state nobody designed.

## Service `Type=` — exact ready-state contract

| `Type=` | Considered "started" when… | Common mis-use |
|---|---|---|
| `simple` (default if `ExecStart=` set) | immediately after `fork()`, before the binary loads | Race: dependents start before the binary has even loaded |
| `exec` | after the binary has been loaded into memory | Less racy than `simple`; cheap upgrade |
| `forking` | parent process **exits** | Requires `PIDFile=`; without it systemd guesses MAINPID and often picks the wrong child. Double-fork daemons race against systemd reading the PID file |
| `oneshot` | main process **exits**; combine with `RemainAfterExit=yes` (default `no`) to keep the unit `active` instead of jumping `activating → dead` | Forgetting `RemainAfterExit=yes` makes follow-up `Wants=` from another unit re-trigger the script |
| `notify` | daemon sends `READY=1` over `$NOTIFY_SOCKET` via `sd_notify(3)` | If binary doesn't actually call `sd_notify`, unit hangs in `activating` until `TimeoutStartSec` (default `90s` from `DefaultTimeoutStartSec`). `NotifyAccess=main` (default) drops messages from non-main PIDs — set `=all` if a child notifies |
| `notify-reload` | like `notify`, plus systemd sends `SIGHUP` on `systemctl reload` and waits for `RELOADING=1`/`READY=1` (v253+) | |
| `dbus` | bus name in `BusName=` is acquired | Forgetting `BusName=` |
| `idle` | like `simple`, but execution deferred until other jobs dispatched | Cosmetic — for tidy boot logs, not a real ordering tool |

Restart triggers: `Restart=` ∈ `{no, always, on-success, on-failure, on-abnormal, on-watchdog, on-abort}`. Default `no`. `on-failure` fires for non-zero exit, signal, timeout, watchdog. **`always` ignores `SIGTERM` from `systemctl stop` — it does NOT restart on clean stop.**

`ExecReload=` is required for `systemctl reload` to do anything; without it, `reload` errors out. SIGHUP convention is just convention — only `Type=notify-reload` makes systemd send SIGHUP itself.

## Restart throttle math — the part that hangs your service

- `RestartSec=` default `100ms` (delay between attempts).
- Throttle: `StartLimitIntervalSec=` default `10s`, `StartLimitBurst=` default `5`. Exceeding moves unit to `failed` with `start-limit-hit`. **These two go in `[Unit]`, not `[Service]` — silently ignored if mis-placed.**
- `systemctl reset-failed unit.service` clears the burst counter (and the `failed` state). Manual `systemctl start` calls **count toward the limit**.
- Once in `failed`, `Restart=always` does **not** retry — you must `reset-failed` or wait for `StartLimitIntervalSec`.
- For an indefinitely-restarting service: bump `StartLimitBurst=0` (disable) or set `StartLimitIntervalSec=0`.
- Back-off: prefer `RestartSec=` proportional to crash class, e.g. `5s`–`30s`; sub-second restart with `RestartSec=100ms` and a 5-burst limit guarantees `failed` in <1s on a crashloop.

## Cgroup v2 resource control

cgroup v2 is the unified hierarchy (single tree, multiple controllers). systemd auto-enables a controller when any unit configures it; no need to mount manually.

- `MemoryMax=` — **hard cap**, OOM-killer fires at the limit. No default (unlimited).
- `MemoryHigh=` — **throttle**, processes slowed and aggressive reclaim above this; OOM does **not** fire. Recommended primary control. No default.
- `MemoryLow=` / `MemoryMin=` — protection floor; reclaim avoids dipping below. `Min` is hard, `Low` is best-effort.
- `MemorySwapMax=` — bytes of swap; unlimited if unset.
- `CPUQuota=` — percent of one CPU, e.g. `200%` = 2 cores. Period configurable via `CPUQuotaPeriodSec=` (default `100ms`, clamped 1ms–1000ms).
- `CPUWeight=` — relative share, range **1–10000, default 100**. Doubling weight ≈ doubles share **only under contention**; idle, both can use the full CPU. `StartupCPUWeight=` overrides during early boot.
- `IOWeight=` — same model, range 1–10000, default 100. Per-device tuning via `IODeviceWeight=`.
- `TasksMax=` — PID/thread cap. No default per-unit; system-wide default ~`15%` of `/proc/sys/kernel/threads-max`.
- `IPAccounting=true` — enables per-unit IPv4/IPv6 byte/packet counters (visible in `systemctl status`); off by default because it costs measurable BPF overhead at high pps.
- `IPAddressAllow=` / `IPAddressDeny=` — eBPF firewall per unit; deny takes precedence; empty = allow all.
- `Slice=` — places unit in named slice (default `system.slice` for system units, `app.slice`/`user.slice` for user). Slices nest: `foo.slice` → `foo-bar.slice`.
- `AllowedCPUs=` / `AllowedMemoryNodes=` — CPU/NUMA pinning; v2-only.
- `ManagedOOMMemoryPressure=auto|kill` + `ManagedOOMSwap=auto|kill` — opt-in to systemd-oomd PSI-based OOM (kills under sustained memory pressure before kernel OOM).

cgroup v1 is deprecated upstream since systemd 252; on v1 hosts the modern memory directives degrade silently.

## Hardening — directives that implicitly turn on others

Apply in this order: (1) `NoNewPrivileges=true`, (2) filesystem `Protect*`/`Private*`/path lists, (3) capability set, (4) syscall filter. Validate with `systemd-analyze security UNIT` (score 0.0 fully sandboxed → 10.0 unrestricted).

- `NoNewPrivileges=true` — prevents `setuid`/file-caps gaining privileges via process replacement. Default `false`. **Implicitly enabled** when you set any of: `SystemCallFilter=`, `SystemCallArchitectures=`, `RestrictAddressFamilies=`, `RestrictNamespaces=`, `PrivateDevices=`, `ProtectKernelTunables=`, `ProtectKernelModules=`, `MemoryDenyWriteExecute=`, `RestrictRealtime=`, `RestrictSUIDSGID=`, `DynamicUser=`, `LockPersonality=`.
- `ProtectSystem=` ∈ `false` (default) | `true` (/usr+/boot ro) | `full` (+ /etc ro) | `strict` (entire fs ro except /dev /proc /sys, plus your `ReadWritePaths=`).
- `ProtectHome=` ∈ `false` (default) | `true` (/home /root /run/user inaccessible) | `read-only` | `tmpfs`.
- `PrivateTmp=true` — private `/tmp` and `/var/tmp` (tmpfs); default `false`. `disconnected` variant fully isolates.
- `PrivateDevices=true` — minimal `/dev`; removes `CAP_MKNOD`, `CAP_SYS_RAWIO`, blocks `@raw-io` syscalls.
- `PrivateNetwork=true` — only loopback in unit's net ns.
- `PrivateUsers=true` — user namespace; UIDs outside the unit map to nobody. Useful with `User=`/`DynamicUser=`.
- `DynamicUser=true` — transient UID/GID, **implies** `ProtectSystem=strict`, `ProtectHome=read-only`, `NoNewPrivileges=yes`, `RemoveIPC=yes`, `RestrictSUIDSGID=yes`, disables D-Bus name allocation.
- `RestrictAddressFamilies=` — allowlist; `RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6` is typical for network daemons. **Empty value = permit all** (opposite of most directives).
- `SystemCallFilter=@system-service` — pre-defined groups (`@network-io`, `@file-system`, `@privileged`, etc.); prefix `~` to invert (deny-list mode).
- `CapabilityBoundingSet=` — whitespace list; `~CAP_SYS_ADMIN CAP_NET_ADMIN` removes both. Multiple lines OR-merge unless prefixed `~` (then AND).
- `AmbientCapabilities=` — what unprivileged children inherit; auto-adds `keep-caps` to SecureBits.
- `ReadWritePaths=` / `ReadOnlyPaths=` / `InaccessiblePaths=` — space-separated; `-` prefix to ignore missing, `+` for `RootDirectory=`-relative. Nesting allowed (writable inside read-only is honoured).
- `MemoryDenyWriteExecute=true` — blocks `mmap(PROT_WRITE|PROT_EXEC)` and `mprotect(...PROT_EXEC)`. **Breaks JITs** (V8, JVM, LuaJIT, .NET).
- `LockPersonality=true` — blocks `personality(2)` syscall (no x86-on-x86_64 emulation switches).
- `ProtectKernelTunables=true` — `/proc/sys`, `/proc/sysrq-trigger`, `/sys` read-only.
- `ProtectKernelModules=true` — blocks `init_module`/`finit_module`/`delete_module`.
- `ProtectControlGroups=true` — `/sys/fs/cgroup` read-only.
- `ProtectProc=invisible` — hides other users' processes in `/proc`; requires `User=` or `DynamicUser=yes`.
- `RestrictNamespaces=true|user net ipc...` — blocks `unshare`/`clone` for listed ns types.

## Exec line prefixes

`ExecStart=`, `ExecStartPre=`, `ExecStartPost=`, `ExecStopPost=`, `ExecReload=` accept prefixes (combine in this order: `@`, `-`, `:`, `+`/`!`/`!!`):

- `-` — non-zero exit treated as success (failure ignored)
- `@` — argv[0] override; the second token becomes argv[0] passed to the binary
- `:` — disable environment variable expansion (`$FOO` left literal)
- `+` — run with **full** privileges, bypassing `User=`, `Group=`, `Capability*=`, `Private*=`, `Protect*=` for **this command only**
- `!` — run as `User=`/`Group=` but **without** PrivateUsers / capability-dropping / ambient-caps logic (still applies most sandbox)
- `!!` — same as `!` on systems without ambient capability support, otherwise equivalent to no prefix

`ExecStartPre=` failure aborts the start unless `-` prefixed. `ExecStopPost=` runs even on failed start (use it for cleanup).

## Socket activation

- `ListenStream=` (TCP/AF_UNIX stream/vsock), `ListenDatagram=` (UDP), `ListenSequentialPacket=`, `ListenFIFO=`, `ListenSpecial=`, `ListenNetlink=`, `ListenMessageQueue=`. Multiple per unit; all FDs passed.
- `Accept=no` (default) — single service handles all connections; service receives the **listening** FDs and `accept(2)`s itself. Suits long-lived daemons.
- `Accept=yes` — systemd `accept(2)`s and spawns a **per-connection instance** of the matching `@.service` template. Service unit name is the socket's basename + `@` + counter (e.g. `foo.socket` → `foo@1.service`). Inetd-style; high overhead — use `MaxConnections=` (default `64`).
- `Service=` overrides the spawned service name; **only valid when `Accept=no`**.
- `FileDescriptorName=` names FDs; the service reads `LISTEN_FDNAMES` (colon-separated) alongside `LISTEN_FDS`/`LISTEN_PID`. Use `sd_listen_fds_with_names(3)`.
- sd_listen_fds protocol: child checks `LISTEN_PID == getpid()`, then `LISTEN_FDS` FDs start at FD 3.
- `BindIPv6Only=default|both|ipv6-only` — defaults to system `/proc/sys/net/ipv6/bindv6only`.
- `SocketMode=0666` default; tighten for AF_UNIX with `SocketUser=`/`SocketGroup=`.
- Activation parallelises boot: opening the socket up-front lets dependents `connect()` and block until the daemon is ready, eliminating ordering churn.

## Timer activation

- `OnCalendar=` — wallclock; syntax: `Mon..Fri *-*-* 03:00:00`, aliases `daily`/`weekly`/`hourly`/`monthly`/`yearly`. Validate with `systemd-analyze calendar 'Mon *-*-* 03:00'`.
- `OnBootSec=` / `OnStartupSec=` / `OnUnitActiveSec=` / `OnUnitInactiveSec=` — monotonic offsets.
- `RandomizedDelaySec=0` default — uniform jitter to spread fleet-wide cron stampedes. `FixedRandomDelay=true` (v247+) makes the offset deterministic per machine-id (so a given host always picks the same slot — useful for staggered rollouts).
- `Persistent=false` default — for `OnCalendar=` only. With `=true`, systemd records last-run timestamp; on boot, if a calendar elapse was missed (powered off through the slot), the unit fires once to catch up. Reset with `systemctl clean --what=state TIMER`.
- `AccuracySec=1min` default — coalescing window for power-saving wake-up. Set `=1us` if you actually need the slot.
- `WakeSystem=false` default — `=true` resumes from suspend at elapse; uses `CLOCK_BOOTTIME`.
- `Unit=` defaults to same name with `.service` suffix. Override for fan-out.
- `RemainAfterElapse=true` default — keep timer state queryable. `=false` for transient one-shots.

## Drop-ins (the only safe way to override vendor units)

- `systemctl edit foo.service` writes `/etc/systemd/system/foo.service.d/override.conf` and runs `daemon-reload`. Use `--full` to copy the entire vendor unit (rare).
- `--drop-in=NAME` chooses a non-`override` filename — useful for layered configs (`50-cpu.conf`, `60-network.conf`).
- Editing `/lib/systemd/system/foo.service` directly is wiped on package upgrade. Don't.
- After a manual edit: `systemctl daemon-reload` then `systemctl restart foo` (reload alone re-reads units, doesn't restart them).
- List-style directives (`ExecStartPre=`, `Environment=`) accumulate in drop-ins. To **clear** before re-adding, set the directive to empty first: `ExecStartPre=` then `ExecStartPre=/new/cmd`.
- Inspect effective unit: `systemctl cat foo.service` shows vendor + drop-ins concatenated.

## journald — filtering and retention

- `journalctl -u UNIT` — by unit; supports globs (`-u 'docker-*'`), repeatable.
- `--since='1h ago'` / `--until='2026-04-25 14:00'` — accept relative and absolute.
- `-p err` — priority ≤ err (errors and worse); range syntax `-p warning..err`. Levels: emerg(0) alert(1) crit(2) err(3) warning(4) notice(5) info(6) debug(7).
- `-f` — follow (tail -f equivalent); `--lines=N`/`-n` cap initial output.
- `-b` current boot, `-b -1` previous, `--list-boots` enumerate.
- `-k` — kernel only (dmesg view).
- `--grep=PATTERN` — server-side regex; cheaper than piping to `grep` because it filters before formatting.
- Field filters: `_PID=`, `_UID=`, `_SYSTEMD_UNIT=`, `_SYSTEMD_CGROUP=`, `_BOOT_ID=`, `_TRANSPORT=`. AND across distinct fields, OR within same field; `+` between groups.
- `--user-unit=UNIT` for `--user` instances.
- Retention: `Storage=persistent` in `/etc/systemd/journald.conf` (default `auto` — persistent only if `/var/log/journal` exists). `SystemMaxUse=`, `SystemKeepFree=`, `SystemMaxFileSize=`. Defaults size to 10% of `/var/log` filesystem, capped at 4 GB.
- `journalctl --vacuum-size=500M` / `--vacuum-time=2weeks` / `--vacuum-files=10` to reclaim. `--rotate` forces a rotation.
- `RateLimitIntervalSec=30s` + `RateLimitBurst=10000` (defaults) per service — exceeding **silently drops** messages with a "Suppressed N messages" notice. Bump for chatty services.

## User units

- `systemctl --user start foo.service` runs from `~/.config/systemd/user/` and `/etc/systemd/user/`.
- `XDG_RUNTIME_DIR` (typically `/run/user/$UID`) **must** be set; without it `systemctl --user` errors with "No such device or address". `sudo su - user` does NOT set it; use `machinectl shell user@` or `loginctl` to enter properly.
- Without lingering, the user manager dies when the last login session ends — killing all `--user` units. `sudo loginctl enable-linger USER` makes the user manager auto-start at boot and persist after logout. Required for rootless Podman, long-running personal services.
- User units are subject to all the same `Protect*`/`Private*`/cgroup directives, but `User=`/`Group=` are obviously fixed and `PrivateUsers=true` requires `kernel.unprivileged_userns_clone=1`.

## Diagnostics — order of triage

1. `systemctl status UNIT` — last 10 log lines + cgroup + result code.
2. `journalctl -u UNIT -b --no-pager` — full current-boot log; add `-p err` to skim.
3. `systemctl cat UNIT` — the merged unit (vendor + drop-ins).
4. `systemd-analyze verify UNIT` — syntax errors, missing deps, ordering cycles.
5. `systemd-analyze blame` — slowest units this boot; `critical-chain UNIT` shows the time-critical activation path.
6. `systemd-analyze security UNIT` — sandbox exposure score 0.0–10.0 with per-directive breakdown.
7. `systemd-analyze dot --order UNIT | dot -Tsvg > x.svg` — dependency graph (needs graphviz).
8. `systemd-cgls` — cgroup tree with processes; `systemd-cgtop` — live cgroup resource view.
9. `systemctl list-dependencies --all UNIT` and `--reverse` for what depends on this.

## Common failure modes

- **Stuck in `activating`** — `Type=notify` without an `sd_notify(READY=1)` call; or `NotifyAccess=main` (default) when the notifying PID is a child fork. Switch to `=all` or implement `sd_notify`. Confirm with `strace -f -e write` and look for writes to `$NOTIFY_SOCKET`. `Type=dbus` with no `BusName=` or wrong bus name behaves identically.
- **Restart loop into `failed`** — `RestartSec=100ms` × `StartLimitBurst=5` exhausts in 500ms. Fix root cause OR raise `StartLimitBurst`/`StartLimitIntervalSec`/`RestartSec`. `systemctl reset-failed` to recover; manual `start` counts toward burst.
- **`Type=forking` MAINPID wrong** — daemon double-forks and exits parent before writing PID file; systemd's PID-file race picks an intermediate. Fixes (best→worst): convert to `Type=notify` and call `sd_notify`; ensure parent only exits **after** child has written PIDFile; set `GuessMainPID=no` and provide `PIDFile=` reliably.
- **`Wants=foo.service` runs but my unit didn't wait** — `Wants=` does NOT imply `After=`. Add explicit `After=foo.service`.
- **Ordering cycle on boot** — `systemd-analyze verify` finds it; systemd silently breaks one edge to make progress. Symptom: random unit starts before its dep on some boots. Fix the cycle, don't rely on the auto-break.
- **Drop-in seems ignored** — forgot `daemon-reload`, or wrote it under `/run/systemd/system/...d/` (transient, lost on reboot) instead of `/etc/systemd/system/...d/`. Verify with `systemctl cat`.
- **`Restart=always` won't restart on `systemctl stop`** — by design; only stops triggered by failure/signal/watchdog count. Use `Restart=always` + a separate process manager only if you really want stop-resistant.
- **Hardening broke the service** — `MemoryDenyWriteExecute` on a JIT, `SystemCallFilter` missing a syscall the daemon makes, `ProtectSystem=strict` blocking a write path not in `ReadWritePaths=`. Diagnose with `journalctl -u UNIT` (search for `Operation not permitted`, `signal=SIGSYS`) and `systemd-analyze security UNIT` for combinatorics.

## Authoritative references

**Manpages** (Debian mirror, freedesktop.org canonical):
- [systemd.unit(5)](https://manpages.debian.org/testing/systemd/systemd.unit.5.en.html) — dependency directives, `DefaultDependencies=`, conditions
- [systemd.service(5)](https://manpages.debian.org/testing/systemd/systemd.service.5.en.html) — `Type=`, `Restart=`, `Exec*=`, `WatchdogSec=`, `NotifyAccess=`
- [systemd.exec(5)](https://manpages.debian.org/testing/systemd/systemd.exec.5.en.html) — hardening directives, namespaces, `Capability*=`
- [systemd.resource-control(5)](https://manpages.debian.org/testing/systemd/systemd.resource-control.5.en.html) — cgroup v2 limits
- [systemd.kill(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.kill.html) — `KillMode=`, `KillSignal=`, `TimeoutStopSec=`
- [systemd.socket(5)](https://manpages.debian.org/testing/systemd/systemd.socket.5.en.html) — socket activation
- [systemd.timer(5)](https://manpages.debian.org/testing/systemd/systemd.timer.5.en.html) — timer scheduling
- [systemd.special(7)](https://man7.org/linux/man-pages/man7/systemd.special.7.html) — well-known targets
- [systemd-analyze(1)](https://manpages.debian.org/testing/systemd/systemd-analyze.1.en.html) — `blame`, `critical-chain`, `verify`, `security`, `calendar`
- [journalctl(1)](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html) — log query
- [sd_notify(3)](https://www.freedesktop.org/software/systemd/man/latest/sd_notify.html) / [sd_listen_fds(3)](https://www.freedesktop.org/software/systemd/man/latest/sd_listen_fds.html)

**Wikis (reliable secondary sources)**:
- [Arch Wiki: systemd](https://wiki.archlinux.org/title/Systemd) and [systemd/User](https://wiki.archlinux.org/title/Systemd/User), [systemd/Sandboxing](https://wiki.archlinux.org/title/Systemd/Sandboxing), [systemd/Journal](https://wiki.archlinux.org/title/Systemd/Journal), [Cgroups](https://wiki.archlinux.org/title/Cgroups)
- [Red Hat: cgroups-v2 + systemd](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/assembly_configuring-resource-management-using-systemd_managing-monitoring-and-updating-the-kernel) and [Mastering systemd: sandboxing](https://www.redhat.com/en/blog/mastering-systemd)
- [kernel.org: cgroup v2](https://docs.kernel.org/admin-guide/cgroup-v2.html) — controller semantics

**Authors worth reading**:
- Lennart Poettering (0pointer.de) — original-author blog, especially [Socket Activation](http://0pointer.de/blog/projects/socket-activation.html)
- Chris Down — cgroup v2 / kernel memory management talks
- Michael Stapelberg — practical operations notes (e.g. [indefinite restarts](https://michael.stapelberg.ch/posts/2024-01-17-systemd-indefinite-service-restarts/))

## Guardrails

Before recommending a non-trivial unit change (hardening directive, cgroup limit, restart policy, dependency type):

1. Quote the **exact directive name** and its **default value**.
2. Cite the manpage section (`systemd.exec(5)`, `systemd.resource-control(5)`, etc.).
3. Make the recommendation conditional on observed evidence — `journalctl` output, `systemd-analyze security` score, cgroup metrics — never blanket-tune.
4. For hardening: run `systemd-analyze security UNIT` **before and after** to quantify the change. Verify the service still works (a sandboxed-broken service scores 0.0 and is also dead).
5. Drop-in over edit: never modify vendor `/lib/systemd/system/*.service`. Always `systemctl edit` or write under `/etc/systemd/system/UNIT.d/`.

**A directive that "looks right" and silently does nothing is the systemd default failure mode.** Verify with `systemctl cat`, `systemd-analyze verify`, and reproduction.

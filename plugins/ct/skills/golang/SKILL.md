---
name: golang
description: >
  Deep Go operational intuition — race detector cost, GC tuning (GOGC/GOMEMLIMIT),
  GOMAXPROCS in containers, escape analysis, pprof/trace workflow, goroutine leak
  diagnosis, context propagation, channel/sync gotchas, govulncheck reachability,
  module replace scope, memory model formalisms.
  Load ONLY when the task is about runtime tuning, profiling/leak diagnosis, GC
  pressure, scheduler latency, race-detector decisions, escape-analysis review,
  or module/build operational quirks. Do NOT load for ordinary Go code writing,
  goroutine/channel syntax help, idiomatic style debates, or "how do I write a
  test" — those don't need this skill.
  Triggers on: "race detector cost", "GOMEMLIMIT", "GOGC tuning", "GOMAXPROCS container",
  "automaxprocs", "escape analysis", "pprof mutex profile", "block profile", "goroutine leak",
  "lost cancel", "errgroup vs WaitGroup", "gctrace", "schedtrace", "govulncheck",
  "go module replace", "memory model", "happens-before".
---

# Go Operational Guide

Concise operational pointers for Go runtime tuning, profiling, and concurrency diagnosis.

Assumes you already know goroutines, channels, error handling, and module basics. This skill covers the **operational layer** — the parts models tend to gloss over: race detector economics, GC/scheduler tuning under containers, profiling configuration, leak forensics, escape analysis, memory-model edges.

## When to use

Load when the question is about:
- Race detector cost / when to disable in CI / false-negative window
- GC tuning (`GOGC`, `GOMEMLIMIT`, `gctrace` interpretation, GC CPU cap)
- Scheduler / `GOMAXPROCS` in containers (cgroup detection, automaxprocs, Go 1.25 default)
- pprof workflow (mutex/block off-by-default knobs, labels, debug levels, `runtime/trace`)
- Goroutine leaks (the canonical four patterns, `goroutineleak` profile in 1.26)
- Context cancellation correctness (lost cancel, errgroup vs WaitGroup, deadline propagation)
- Escape analysis (`-gcflags='-m'` output, interface boxing, closure capture)
- `sync.Pool` retention, slice capacity GC retention, defer-in-loop accumulation, nil/closed channel semantics
- `govulncheck` reachability vs `gosec` / `staticcheck` scope
- `go.mod` `replace` directive scope, `GOFLAGS`, `GOPRIVATE`/`GONOSUMDB`, vendor caveats
- Go memory model 1.19 happens-before semantics for atomics/sync primitives

**Do NOT load** for: writing idiomatic Go, picking between `chan` and `sync.Mutex` for a new feature, project layout debates, generic test scaffolding, basic error-wrapping style.

## Race detector

- **Cost**: memory ~5-10x, CPU 2-20x. Don't leave `-race` on for production binaries by default. CI lane is the right home.
- **Defer/recover hidden cost**: 8 extra bytes per `defer`/`recover` retained until the goroutine exits. Long-lived goroutines with tight `defer/recover` loops grow without bound — invisible in `runtime.ReadMemStats` and `runtime/pprof` heap profiles.
- **Detection window**: only races that occur during execution are reported. Running `-race` once is not "I checked for races" — it's "I checked the code paths I exercised this run." Pair with stress tests (`go test -race -count=N`).
- **GORACE knobs**: `halt_on_error=1` exits on first race (CI default); `history_size=N` widens the per-goroutine memory history (default 1, max 7) — raise only if you see "race detected (history truncated)"; `exitcode=66` is the default — set non-66 if 66 collides with your runner.
- **Platforms**: cgo required. `linux/amd64`, `linux/arm64`, `linux/ppc64le`, `linux/s390x`, `linux/loong64`, `darwin/amd64`, `darwin/arm64`, `windows/amd64`, `freebsd/amd64`, `netbsd/amd64`. No 32-bit support.
- **CI integration**: separate job for `-race` because the binary is fundamentally different (instrumented). Don't compare benchmarks between race and non-race builds.

## GC tuning: GOGC and GOMEMLIMIT

- **GOGC default 100**: target heap = live heap + (live + roots) × GOGC/100. Roots counted as of Go 1.18 — older mental models that omit roots are wrong. `GOGC=off` disables proportional triggering entirely.
- **GOMEMLIMIT (Go 1.19+)**: soft cap on `runtime.MemStats.Sys - HeapReleased` (i.e. total Go-managed memory, not just heap). Set via env or `runtime/debug.SetMemoryLimit`. Soft means "best effort" — runtime will exceed it rather than thrash.
- **Combine GOGC=off with GOMEMLIMIT** when you want maximum throughput up to a known ceiling — common pattern: `GOGC=off GOMEMLIMIT=8GiB` lets the heap grow to 8GiB and only GCs to stay under that. Reduces GC frequency dramatically when memory headroom is the binding constraint.
- **GC CPU cap**: when memory pressure forces frequent GC, runtime caps GC at ~50% CPU over a `2 × GOMAXPROCS` CPU-second window. Worst-case slowdown ~2x; runtime prefers OOM/limit-overshoot to indefinite stall.
- **Death spiral**: GOMEMLIMIT below working set → continuous GC → effective stall. Leave 5-10% headroom in containers. The 50% CPU cap is the escape hatch — without it, a misconfigured limit would freeze the program.
- **gctrace=1** output format: `gc # @s %: ms clock, ms cpu, MB→MB→MB, MB goal, MB stacks, MB globals, P`. `→MB→MB→MB` = pre-GC heap → post-GC heap → live. Goal is the next-cycle target. If `goal` keeps shrinking and time-in-GC % climbs, you're approaching memlimit thrash.

## Scheduler and GOMAXPROCS

- **Default before Go 1.25**: `runtime.NumCPU()` returns the host's logical CPUs, ignoring cgroup CPU quota. In a 100-core node with a 2-CPU container limit, GOMAXPROCS=100 → severe throttling (cgroup CFS throttles), p99 latency tanks. Uber benchmarks: 4x p50, 25x p99 improvement when matched.
- **Go 1.25+**: container-aware default. Reads cgroup CPU quota; rounds **up** for fractional limits (1.5 → 2). Periodically re-checks and adjusts on quota change. Setting `GOMAXPROCS` env or calling `runtime.GOMAXPROCS()` overrides.
- **Pre-1.25 fix**: `import _ "go.uber.org/automaxprocs"` reads `cpu.cfs_quota_us`/`cpu.cfs_period_us` (cgroup v1) or `cpu.max` (cgroup v2). No-op on macOS/Windows. Call before any goroutine that depends on parallelism.
- **CPU requests are invisible** to both 1.25 and automaxprocs — only **limits** are read. Pods with requests-only get host core count. Set limits if you want bounded parallelism.
- **Diagnosis**: `GODEBUG=schedtrace=1000` emits scheduler state every 1 s. Watch `runqueue` (global) and `[N M ...]` (per-P local queues). Add `scheddetail=1` for per-goroutine state — verbose, use briefly.

## pprof and runtime/trace

- **Profiles available** (`runtime/pprof.Lookup` / `/debug/pprof/`): `goroutine`, `heap`, `allocs`, `threadcreate`, `block`, `mutex`, `goroutineleak` (1.26+).
- **Mutex/block profiles are off by default**. Enable explicitly:
  - `runtime.SetMutexProfileFraction(N)` — reports 1/N contention events. Common: 100 in dev, 1000-10000 in prod. `0` disables; negative reads current.
  - `runtime.SetBlockProfileRate(N)` — samples 1 event per N nanoseconds blocked. `1` = every event (expensive); `10000` (10 µs) is a safer prod default; `0` disables.
- **pprof labels**: `pprof.Do(ctx, pprof.Labels("op", "ingest", "tenant", id), func(ctx) {...})`. Labels propagate through derived contexts and to goroutines spawned inside `Do`. Slice profiles by label in pprof: `-tagfocus=op:ingest`. Crucial for sharing a multi-tenant binary's profile.
- **WriteTo `debug` parameter**: `0` = pprof protobuf (use this for `go tool pprof`). `1` = text with addresses. `2` = goroutine profile in panic-style stack format — best for human reading of `goroutine` profile.
- **Execution tracer** (`runtime/trace`, `go tool trace`): captures scheduling, syscalls, GC pauses, network poll. Different from pprof — use for "why is wall-clock slow when CPU is fine" (lock contention, GC stalls, syscall blocking). Heavy: 100s of MB/s for busy programs. Bound runs to seconds.
- **CPU profile**: `pprof.StartCPUProfile(w)` / `StopCPUProfile()`. Default sampling rate ~100 Hz (10 ms). Adjust via `runtime.SetCPUProfileRate` before start.

## Goroutine leak diagnosis

- **Symptom**: `runtime.NumGoroutine()` climbs monotonically; heap profile shows steady growth tied to goroutine-owned objects; `/debug/pprof/goroutine?debug=2` reveals N goroutines on the same blocked frame.
- **Four canonical leak patterns** (from Uber LeakProf):
  1. Send on unbuffered channel with no receiver (sender blocks `chan send` forever)
  2. `range` over a channel that's never `close`d (receiver blocks `chan receive`)
  3. Premature return from one participant in a multi-party protocol (others wait forever)
  4. `select { case <-ch: ... case <-ctx.Done(): return }` where the producer goroutine still tries to send on `ch` after `ctx` cancels — the producer leaks (sender doesn't observe ctx)
- **Diagnosis flow**:
  1. `curl /debug/pprof/goroutine?debug=2 > goroutines.txt`
  2. Sort by stack — N goroutines with identical frames = same leak site
  3. Top frame names the primitive blocked on (`runtime.chansend1`, `runtime.gopark`)
- **Go 1.26 `goroutineleak` profile**: explicit leak detector (off by default; experimental). Triggers a special GC cycle, returns only goroutines whose blocking primitive is unreachable from any non-blocked goroutine. Cuts noise dramatically vs `goroutine` profile.
- **Common fixes**:
  - Always `defer ticker.Stop()`, `defer cancel()` when creating `time.Ticker`/`context.WithCancel`. Failing to call `cancel` doesn't leak a goroutine itself but defeats deadline propagation, causing downstream leaks.
  - Buffer-of-1 the result channel in fan-out-with-timeout patterns — otherwise the producer blocks on send when the consumer has already returned via timeout.

## Context propagation

- **Lost cancel**: `_, ok := context.WithTimeout(ctx, d)` discards `cancel`. The `cancel` must be called (typically `defer cancel()`) **even if the deadline fires** — failing to cancel keeps the timer alive until the parent context cancels, leaking timer state. `go vet` catches this (`lostcancel`).
- **`ctx.Err()` vs `<-ctx.Done()`**: `Done()` is the channel for select; `Err()` returns `context.Canceled` or `context.DeadlineExceeded` post-cancel — `nil` before. Always check `Err()` after `Done()` fires to distinguish the cause.
- **Deadlines compose minimally**: `WithTimeout(parent, 10s)` clamps to whichever is sooner — parent's deadline or now+10s. Never extends.
- **`errgroup.WithContext`**: derived ctx is canceled on **first** error from any `Group.Go` callee, or when `Wait` returns. Other goroutines must observe `ctx.Done()` themselves — errgroup does NOT preempt them. The first non-nil error is what `Wait` returns; later errors are dropped.
- **`SetLimit(n)`**: `Group.Go` blocks when n goroutines are active. `TryGo` returns false instead of blocking. Must not change limit while goroutines are running.
- **errgroup vs `sync.WaitGroup`**: WaitGroup is dumb counting (no errors, no cancel). errgroup adds error capture + ctx cancellation. Don't reach for WaitGroup unless you genuinely have no error path and no cancellation need.

## Channels and sync gotchas

- **Channel axioms** (Cheney):
  - send to nil channel: blocks forever
  - receive from nil channel: blocks forever
  - send to closed channel: **panics** (no recover at the sender — guard with select-case-with-default or coordinate close ownership)
  - receive from closed channel: zero value, immediately, forever
- **Nil channel in select**: case is permanently disabled. Pattern for "drain this source then stop listening": `ch = nil` after observing close, so the case never fires again.
- **Closed channel in select**: always ready (returns zero). Combined with the above: `for { select { case v, ok := <-ch: if !ok { ch = nil; continue } ... } }` is the correct merge-and-disable idiom.
- **`sync.Pool` GC cycles**: pooled objects survive at least 2 GC cycles (a victim cache mechanism added in 1.13 prevents post-GC empty-pool stampede). Don't pool huge variable-sized buffers — `Pool.Get` returns an arbitrary item, so a 16-byte caller may get a 16 MB buffer. Discard oversized items rather than `Put`-ing them back.
- **Slice-of-pointer GC retention**: `s = s[:0]` keeps cap and the underlying array alive — and pointer elements past `len` are still referenced by GC. Set `s[i] = nil` for indices in `[len:cap]` you want released, or reslice with explicit copy: `s = append([]T(nil), s[:n]...)`.
- **Defer in a loop**: each iteration appends to the per-goroutine defer stack; nothing runs until the function returns. `for _, f := range files { defer f.Close() }` holds N file handles. Refactor to a per-iteration function so deferreds fire each loop.
- **`time.Ticker` requires explicit `Stop()`**. Falling out of scope does not stop the underlying goroutine — leaks until program exit.

## Escape analysis

- **Inspect with `go build -gcflags='-m -m' ./...`**. Single `-m` is one level; double prints reasoning chains. Look for `moved to heap`, `escapes to heap`, `parameter X leaks to {return value, heap}`.
- **Forced-heap patterns**:
  - Returning `&local` (caller may outlive callee) — escape mandatory
  - Storing into a globally reachable slot, including a slice element addressed by a heap-resident pointer
  - Capturing in a closure that escapes (returned closure, goroutine'd closure)
  - Boxing into `interface{}` — often heap because compiler can't prove the call site keeps it on the stack. Generic `T any` can box too if T is large or pointer-shaped.
  - Slice/map literals beyond compiler-determined size threshold (current threshold ~64 KB)
- **`*T` return value escapes** the called function's frame — but doesn't necessarily heap-allocate if inlined. Check inlining decisions: `-gcflags='-m=2'`.
- **Falsy escapes**: short-lived large structs may escape due to `interface{}` boxing in `fmt.Sprintf` etc. — avoid in hot paths or pre-format with typed builders.
- **Benchmark with `-benchmem`** and compare `allocs/op` before/after. Escape analysis output is necessary but not sufficient — measure.

## Tooling: vet, vulnerability, lint

- **`go vet`**: ships with the toolchain; runs by default during `go test`. Checks include `lostcancel`, `printf`, `nilness`, `copylocks`, `unreachable`. Always-on baseline.
- **`govulncheck`**: official (golang.org/x/vuln). Reachability-based — only reports CVEs whose vulnerable functions are actually called by your code (static call graph). Two modes: `-mode=source` (gives full call stacks; needs source) and `-mode=binary` (symbol-table based; no call stacks). Caveats: reflection-mediated calls invisible (false negatives); `unsafe` may also be invisible. Exit non-zero on findings except `-format=json|sarif|openvex` which always exits 0.
- **`gosec`**: pattern-based (regex/AST) on **source** for CWE patterns (hardcoded creds, weak crypto, command injection). Different scope than govulncheck — gosec catches anti-patterns regardless of CVE; govulncheck catches reachable CVEs regardless of code style. Use both.
- **`staticcheck`**: maintained by Dominik Honnef (third-party but de-facto standard, integrated with gopls). Checks numbered SA*, S*, ST*. Includes `errcheck`-equivalent error-return checking. Bundled in `golangci-lint`.
- **`errcheck`**: standalone, checks all error returns are handled. Subsumed by staticcheck for most.
- **`golangci-lint`**: aggregator; runs many linters in parallel with shared loading — strictly faster than running them serially. Project-level config in `.golangci.yml`.

## Modules, build, replace

- **`replace` directive scope**: only the **main** module's `go.mod` `replace` lines are honored. Replaces in dependency `go.mod`s are ignored. Means: forking a dep's dep requires `replace` in your top-level `go.mod`, even if the upstream dep also `replace`s it.
- **`replace` to a local path** (`replace foo => ../foo`) requires the path be outside any vendored tree. CI without that local checkout will fail unresolved.
- **`GOFLAGS=-mod=vendor`** uses `vendor/` and ignores `go.mod` resolution; `-mod=mod` resolves; `-mod=readonly` forbids implicit `go.mod` mutation (CI-friendly).
- **`GOPROXY`**: comma-separated; `direct` means VCS, `off` blocks remote fetch. Common: `GOPROXY=https://proxy.golang.org,direct`. Use `off` to enforce reproducible builds with already-cached modules only.
- **`GOPRIVATE` / `GONOSUMDB` / `GONOPROXY`**: `GOPRIVATE` is a glob list; sets defaults for the other two. Modules matching skip checksum-DB verification (sumdb) and may bypass the proxy. Required for private VCS hosts.
- **`go mod why <pkg>`**: prints the import chain proving why `<pkg>` is in your build. Use to debug "why did this transitive dep show up."
- **`go mod tidy -e`**: continue past errors; useful when one module is unreachable but you want to clean the rest.
- **Vendor caveats**: `vendor/modules.txt` must match `go.mod`; otherwise `-mod=vendor` fails. Replace directives + vendor coexist but dependencies-of-replaced-modules still need to be in `vendor/`.

## Memory model (1.19 update)

- **DRF-SC**: a data-race-free Go program's outcomes can only be explained by some sequentially consistent goroutine interleaving. Race-y programs have implementation-defined behavior bounded by Go's runtime — not C-style undefined.
- **Atomics (1.19+)**: `sync/atomic` operations are sequentially consistent. "If A is observed by B, then A happens-before B." Same model as Java `volatile` and C++ SC atomics. Do NOT mix with non-atomic accesses to the same variable — that's still a race.
- **Mutex/RWMutex**: nth `Unlock()` happens-before mth `Lock()` returns, for n < m. RLock is similar via the `n+1`th Lock relationship.
- **Channel HB rules**:
  - **Buffered send happens-before corresponding receive completes**.
  - **Unbuffered: receive happens-before send completes** (direction reversed — surprising; the receiver is "earlier").
  - **Channel close happens-before a receive that returns the zero value**.
  - For capacity C: kth receive happens-before (k+C)th send.
- **Once.Do**: completion of `f` happens-before any other `Do(f)` returns.
- **WaitGroup, Cond, Map, Pool**: HB rules in 1.19+ are now formally documented per-type (previously implicit).
- **Lazy init pattern**: `sync.Once` is correct; "double-checked" patterns with naked reads/writes are not — even if "the variable is just a pointer" and "writes are atomic on x86." The race detector flags these.

## Authoritative references

**Official Go docs** (`go.dev`):
- [Race Detector](https://go.dev/doc/articles/race_detector)
- [GC Guide](https://go.dev/doc/gc-guide)
- [Memory Model](https://go.dev/ref/mem)
- [Diagnostics](https://go.dev/doc/diagnostics)
- [Container-aware GOMAXPROCS (1.25)](https://go.dev/blog/container-aware-gomaxprocs)
- [Vulnerability Management](https://go.dev/doc/security/vuln/)
- [Go Modules Reference](https://go.dev/ref/mod)

**Runtime / pprof packages**:
- [`runtime`](https://pkg.go.dev/runtime) — `SetMutexProfileFraction`, `SetBlockProfileRate`, `NumGoroutine`, GODEBUG vars
- [`runtime/pprof`](https://pkg.go.dev/runtime/pprof) — profile types, labels, `Do`
- [`golang.org/x/sync/errgroup`](https://pkg.go.dev/golang.org/x/sync/errgroup)
- [`golang.org/x/vuln/cmd/govulncheck`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck)

**Community deep-dives (reliable authors)**:
- Dave Cheney — [GODEBUG tour](https://dave.cheney.net/2015/11/29/a-whirlwind-tour-of-gos-runtime-environment-variables), [Channel Axioms](https://dave.cheney.net/2014/03/19/channel-axioms)
- Russ Cox — [Updating the Go Memory Model](https://research.swtch.com/gomm)
- Uber Engineering — [LeakProf goroutine leak detection](https://www.uber.com/blog/leakprof-featherlight-in-production-goroutine-leak-detection/)
- Uber `automaxprocs` — [github.com/uber-go/automaxprocs](https://github.com/uber-go/automaxprocs)
- Staticcheck — [staticcheck.dev](https://staticcheck.dev/)

## Guardrails

Before recommending a non-trivial operational change (GOGC/GOMEMLIMIT, profile fractions, GOMAXPROCS override, replace directive):
1. Quote the parameter/flag/function name and its current default
2. Cite the official Go doc section (or runtime source) supporting the claim
3. Make the recommendation conditional on observed metrics (gctrace output, pprof samples, container limits) — never blanket-tune
4. Verify the Go version. Many defaults shifted (GOMEMLIMIT in 1.19, generics-related escape behavior in 1.18+, container-aware GOMAXPROCS in 1.25, `goroutineleak` profile in 1.26)

**Tuning without measurement is worse than defaults.**

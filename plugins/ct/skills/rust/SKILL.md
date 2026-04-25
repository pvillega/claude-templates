---
name: rust
description: >
  Deep Rust operational intuition — advanced borrow checker patterns, lifetime variance,
  Pin/Unpin and async state machines, Send/Sync auto-traits, tokio scheduler quirks,
  unsafe invariants, miri, build-time and runtime profiling, allocator swaps, no_std.
  Load ONLY when the task is about borrow-checker workarounds, async pin/state-machine
  pitfalls, unsafe/UB diagnosis, miri runs, tokio runtime tuning, build-time triage,
  release-profile or panic-strategy tuning, allocator selection, or no_std/embedded.
  Do NOT load for ordinary Rust coding, basic ownership/Result/Option questions, simple
  trait design, or beginner cargo workflows — those don't need this skill.
  Triggers on: "borrow checker error", "lifetime variance", "self-referential future",
  "pin projection", "Send/Sync error", "tokio task starvation", "spawn_blocking",
  "block_in_place", "miri", "stacked borrows", "tree borrows", "MaybeUninit",
  "cargo expand", "cargo flamegraph", "samply", "release profile", "lto", "codegen-units",
  "panic = abort", "global_allocator", "jemalloc", "no_std", "panic_handler",
  "cargo build --timings", "mold linker", "sccache", "cargo audit", "cargo deny",
  "Polonius", "NLL".
---

# Rust Operational Guide

Concise operational pointers for deep Rust troubleshooting and tuning.

Assumes you already know ownership, traits, `Result`/`Option`, basic `async`/`.await`. This skill covers the **operational layer** — borrow-checker corners, lifetime variance, async state machines, unsafe invariants, build/runtime profiling, allocators.

## When to use

Load when the question is about:
- Advanced borrow-checker patterns: split borrows, indexed mutation, `Cell` vs `RefCell` vs `Mutex`
- Lifetime variance / subtyping (`&'a mut T` invariance, fn arg contravariance)
- NLL / Polonius / 2024-edition borrow-checker behavior
- `Pin`/`Unpin`, self-referential futures, `pin!` vs `Box::pin`
- `Send`/`Sync` auto-trait failures, `PhantomData<*const ()>` opt-out
- tokio scheduler: `spawn_blocking`, `block_in_place`, runtime flavor, task starvation
- `unsafe` + UB: aliasing rules, `MaybeUninit`, `ptr::read`/`ptr::write`
- miri: what it catches, what it can't
- Macro debugging: `cargo expand`, `trace_macros!`
- Release-profile tuning: `lto`, `codegen-units`, `panic = "abort"`
- Profiling: `cargo flamegraph`, `samply`, `tracy`, `[profile.release] debug = true`
- Allocator swap: jemalloc, mimalloc, arena allocators
- Build performance: sccache, mold, `-Zshare-generics`, `cargo build --timings`
- Supply-chain: `cargo audit`, `cargo deny`, `cargo vet`
- `no_std` / `alloc` / embedded; `#[panic_handler]`, `#[global_allocator]`

**Do NOT load** for: idiomatic Rust style, beginner ownership errors, basic `Result`/`Option` chaining, choosing between `Vec`/`HashMap`, simple lifetime elision questions — those don't need this skill.

## Borrow checker — advanced workarounds

- **Split borrows on disjoint fields**: `&mut self` blocks all other borrows, but `&mut self.a` + `&self.b` is fine on a *struct field path*. Field-disjointness is checked syntactically — through a `getter()` method it fails. Workaround: expose `(&mut a, &b)` tuple accessors, or refactor methods to take individual fields.
- **Two-phase borrows**: `vec.push(vec.len())` compiles since 2018 because the reservation phase of `&mut vec` is suspended while the argument is evaluated. Won't help if the argument calls a method that needs `&mut vec` itself.
- **Indexed mutation pattern**: when you need mutable access to two `Vec` elements, use `slice::split_at_mut(idx)` to obtain two non-overlapping `&mut [T]`. For arbitrary index pairs, use `[T]::get_disjoint_mut([i, j])` (stable 1.83, formerly `get_many_mut`). Index-based loops with `for i in 0..len { vec[i].mutate() }` sidestep iterator-invalidation entirely.
- **`Cell<T>`** — single-threaded interior mutability for `Copy` (or move-in/move-out) only. No `&` to inner. Zero runtime cost. Use for `Cell<u32>` counters, parent pointers, anywhere you'd reach for `&mut` but the borrow checker says no.
- **`RefCell<T>`** — single-threaded, runtime-checked. Multiple `borrow()` OR one `borrow_mut()`; conflict **panics** (`already borrowed`), does not deadlock. Cost: one word per cell + a runtime check. Use sparingly — a panic in production is rarely better than a refactor.
- **`Mutex<T>`** — thread-safe. On the same-thread re-lock the behavior is *unspecified* (may deadlock or panic). Poisons on panic-while-held: subsequent `lock()` returns `Err(PoisonError)`; recover with `into_inner()` or `clear_poison()` (stable 1.77). For most cases, `parking_lot::Mutex` is faster and does *not* poison.
- **`OnceCell<T>` / `OnceLock<T>`** (stable 1.70) — set-once interior mutability. `OnceLock` is the thread-safe variant; replaces the `lazy_static!` and `once_cell::sync::Lazy` patterns in std.

## Lifetime variance

Variance determines what subtype substitutions are sound. Wrong variance = unsoundness.

| Construct | Variance |
|---|---|
| `&'a T` | covariant in `'a` and `T` |
| `&'a mut T` | covariant in `'a`, **invariant in `T`** |
| `*const T` | covariant in `T` |
| `*mut T` | invariant in `T` |
| `fn(T) -> ()` | **contravariant in `T`** |
| `fn() -> T` | covariant in `T` |
| `Cell<T>` / `UnsafeCell<T>` | invariant in `T` |
| `PhantomData<T>` | covariant in `T` |
| `PhantomData<*const T>` / `PhantomData<fn() -> T>` | covariant, but opts out of `Send`/`Sync` differently |

- **Why `&mut T` is invariant in `T`**: a `&mut Vec<&'static str>` cannot subtype to `&mut Vec<&'a str>`, otherwise the callee could overwrite with shorter-lived strings then the caller reads them as `'static` → UB.
- **`&'static mut T` rule of thumb**: extremely restrictive; you can have at most one ever, and once handed out you never get it back. Most APIs that *look* like they want `&'static mut` actually want `Box::leak()` or a `OnceLock`.
- **Signaling variance with `PhantomData`**: lifetime-only generics (`struct Foo<'a>` with no `'a` use in fields) need `PhantomData<&'a ()>` to be covariant in `'a`. To opt *out* of `Send`/`Sync` while keeping a type generic, use `PhantomData<*const T>` (sometimes spelled `PhantomData<Cell<T>>` for invariance + !Sync).

## Borrow-checker generations: NLL, edition 2024, Polonius

- **NLL** (lexical → flow-sensitive) is the default since Rust 2018; ends a borrow at the last *use* not the end of scope.
- **Edition 2024** (Rust 1.85, Feb 2025) introduces `if let` temporary scope changes and `let ... else` cleanup paths that close several "the borrow ends after the brace" papercuts.
- **Polonius** is the next-gen borrow checker; on track to land but not stable. Accepts NLL Problem Case #3 — the conditional return of a mutable reference: `if let Some(v) = map.get_mut(&k) { return v; } map.insert(...);` — currently rejected by NLL because the `&mut` from `get_mut` is held across the `else` arm. Try with `RUSTFLAGS="-Zpolonius=next"` on nightly.
- **Workarounds while waiting**: `entry()` API for the map case; `unsafe { &mut *(ptr as *mut _) }` after `.get_mut().is_some()` (correct, but unsafe); or split into two passes.

## Pin/Unpin and async state machines

- `async fn` desugars to a struct holding all locals across `.await` points; locals that hold `&` to other locals make the future **self-referential**, hence !Unpin.
- **`Pin<P>`** is a wrapper guaranteeing the pointee won't move. Library contract — compiler does *not* enforce; `unsafe` code (executors, `pin-project`) upholds it.
- **`Unpin`** is an auto-trait: types where `Pin<&mut T>` provides no extra guarantee over `&mut T`. Most types are `Unpin`. Hand-rolled futures usually are *not*.
- **`pin!` (stable 1.68)** — stack-pins a value: `let fut = pin!(async { ... });` returns `Pin<&mut F>`. Cheaper than `Box::pin` but tied to current scope.
- **`Box::pin`** — heap-pins. Use when the future must outlive the current frame (returning, storing in a struct field, sending to `tokio::spawn`).
- **`PhantomPinned`** — zero-sized marker that opts a struct *out* of `Unpin`.
- **Pin projection** — going from `Pin<&mut Outer>` to `Pin<&mut Inner>`. Two rules: a field is *structurally pinned* if you project pin-to-pin; otherwise it's *not*. Mixing both correctly requires `unsafe` or — preferred — the **`pin-project`** / `pin-project-lite` crates.
- **The landmine**: implementing `Future` by hand and calling `inner.poll(cx)` without projecting pin → won't compile, but workarounds via `Pin::new_unchecked` are easy to get wrong (moving the inner field after first poll = UB).
- **`Pin<&mut T>` to `&mut T`**: only safe if `T: Unpin`. Otherwise `unsafe { Pin::get_unchecked_mut() }` and you must not move out.

## Send/Sync auto-traits

- `Send`: safe to transfer ownership across threads. `Sync`: `&T` is `Send` (i.e., shareable). Both auto-derived if all fields are.
- **Not `Send` and not `Sync`**: `Rc<T>`, `Cell<T>`, `RefCell<T>`, `UnsafeCell<T>`, `*const T`/`*mut T` (raw pointers). `MutexGuard<T>` is `Sync` but **not `Send`** (must be released by the locking thread on some platforms).
- **Holding a non-`Send` across `.await` makes the future non-`Send`** — the most common spawn-error. `tokio::spawn` requires `Send`. Common culprits: `Rc`, `RefCell`, `MutexGuard` from `std::sync::Mutex` (use `tokio::sync::Mutex` or release before await).
- **Opt-in `unsafe impl Send for T {}`** when you've manually verified safety (e.g., wrapping a raw pointer to thread-safe C state).
- **Opt out**: stable way is `PhantomData<*const ()>` field, or `PhantomData<Cell<()>>` for !Sync only. Negative impls (`impl !Send for T {}`) are unstable.

## Tokio scheduler

- **Runtime flavors**: `multi_thread` (default, work-stealing across worker threads = `available_parallelism()`) and `current_thread` (single-threaded; futures only progress while you `block_on`).
- **`tokio::spawn`** schedules onto worker threads; requires `Future: Send + 'static` on multi_thread.
- **`spawn_blocking(f)`**: runs `f` on a separate **blocking thread pool**. Default `max_blocking_threads = 512`; idle threads time out after `thread_keep_alive` (10s). For sync I/O, CPU-heavy work, third-party blocking libs. Returned `JoinHandle` is *not* abortable.
- **`block_in_place(f)`**: runs `f` on the *current* worker thread but signals tokio to migrate other tasks to peers. Multi-thread only — panics on `current_thread`. Suspends concurrent code in the *same* task (e.g., other arms of `join!`). Use sparingly; prefer `spawn_blocking`.
- **Task starvation symptom**: long synchronous computation inside an async task delays *every* other task on that worker. Tokio cooperatively yields only at `.await` points. Fix: chunk work with `tokio::task::yield_now().await`, or move to `spawn_blocking`.
- **Async vs sync `Mutex`**: `tokio::sync::Mutex` allows the lock to be held across `.await` (its guard is `Send`). `std::sync::Mutex` guard held across `.await` makes future !Send and risks priority inversion under contention. For brief critical sections, prefer `std::sync::Mutex` and release before any `.await`.
- **`tokio-console`** (subscribe via `console-subscriber` crate, `RUSTFLAGS="--cfg tokio_unstable"`) — instrumented runtime view: idle/poll times, blocked tasks, lock contention.

## Unsafe and undefined behavior

- **Aliasing rules** (the Rust abstract machine, enforced by the compiler's noalias annotations to LLVM):
  - Any number of `&T` may coexist; while a `&T` exists, no `&mut T` to overlapping memory anywhere.
  - A `&mut T` is exclusive: no other `&` or `&mut` to the same memory may exist or be derivable.
  - Raw pointers don't carry these rules but converting back to `&`/`&mut` reinstates them.
- **Stacked Borrows / Tree Borrows**: the (still experimental) operational model that defines exactly when raw-pointer/reference interleavings are UB. Tree Borrows (newer, more permissive) is what miri runs by default since 2024. Run with `MIRIFLAGS="-Zmiri-tree-borrows"` to be explicit.
- **`MaybeUninit<T>`**: the *only* sound way to hold uninitialized `T`. Plain `mem::uninitialized()` is deprecated and instant-UB for almost any `T`. Even `MaybeUninit::<bool>::uninit().assume_init()` is UB (`bool` must be 0 or 1; reading uninitialized = invalid value).
- **`ptr::write(p, val)`** vs `*p = val`: `*p = val` *drops* the old value first. For uninitialized memory you must use `ptr::write` (or `MaybeUninit::write`) — `*p = val` would drop garbage.
- **`ptr::read(p)`**: bitwise copy; original memory becomes logically uninitialized. After `ptr::read`, do not let the original be dropped.
- **`#[repr(C)]`** vs default `#[repr(Rust)]`: only `repr(C)`, `repr(transparent)`, `repr(u*)` give a stable layout. Default Rust layout is unspecified — never assume field order in `unsafe`.
- **Provenance**: a pointer carries identity; casting `usize`-back-to-pointer may lose it on strict-provenance targets. Prefer `ptr.with_addr(new_addr)` over `(ptr as usize) | flag`.

## miri

- **Runs**: `rustup +nightly component add miri && cargo +nightly miri test` (or `miri run`).
- **Detects**: out-of-bounds, use-after-free, misaligned access, data races, uninitialized reads, invalid enum discriminants, alignment violations of `*const T`, leaks, Stacked/Tree Borrows violations, `unreachable_unchecked` reached, overlapping `copy_nonoverlapping`.
- **Cannot detect**: FFI calls (skipped or stubbed), `std::process` interactions, real network/file I/O (use `MIRIFLAGS=-Zmiri-disable-isolation` to allow some), platform-specific syscalls, anything that depends on actual memory addresses.
- **Slow**: 10–100x. Run on a tight unit-test subset; not feasible for full integration suites.
- **Tip**: `MIRIFLAGS="-Zmiri-strict-provenance"` to catch sloppy `usize`↔pointer conversions.

## Macro debugging

- **`cargo expand`** (cargo subcommand) — expands all macros in a crate to the final tokens the compiler sees. Install: `cargo install cargo-expand`. Requires nightly toolchain installed (uses `-Zunpretty=expanded`).
- **`trace_macros!(true)`** — built-in nightly-only `macro_rules!` tracer; prints each expansion as the compiler matches.
- **`log_syntax!`** — nightly-only; prints the tokens it receives during expansion. Useful when a `macro_rules!` arm matches the wrong branch.
- **proc-macro debugging**: `cargo install cargo-expand`; for panics in proc macros, `RUST_BACKTRACE=1 cargo build` and add `eprintln!` to the proc-macro source — they print at compile time.

## Build profiles and codegen

- **Defaults (release)**: `opt-level = 3`, `debug = false`, `lto = false`, `codegen-units = 16`, `panic = "unwind"`, `incremental = false`. Defaults (dev): `opt-level = 0`, `debug = true`, `codegen-units = 256`, `incremental = true`.
- **`lto = "fat"`**: whole-program LTO across all crates. 5–20% perf, large binary-size win, **3–10x slower** link. `lto = "thin"`: ~80% of fat's win, much faster. `lto = false` *still* does ThinLocal LTO unless `codegen-units = 1`.
- **`codegen-units = 1`** + `lto = "fat"` is the small-binary recipe. Disables parallel codegen; build time blows up.
- **`panic = "abort"`**: drops `catch_unwind`, removes unwinding tables, ~10% binary-size win, kills `Result`-pretending-via-panic crates. Required for `no_std` typically. Set per-profile: `[profile.release] panic = "abort"`. Note: tests/benches force `unwind` regardless.
- **`[profile.release] debug = true`**: keep DWARF symbols *without* losing optimizations — required for useful flamegraphs/perf reports. Adds ~50% binary size; ship stripped.
- **`strip = "symbols"` / `"debuginfo"`**: strip in cargo (stable 1.59) without external `strip(1)`.
- **`-C target-cpu=native`** (`RUSTFLAGS=-Ctarget-cpu=native`): emits SIMD/AVX for *your* CPU. Binary won't run on older chips. For distributed binaries, target a baseline (`x86-64-v3` is a common 2026 choice).

## Profiling and observability

- **`cargo flamegraph`** (cargo subcommand, install `cargo install flamegraph`): wraps `perf` (Linux), `xctrace` (macOS), or `dtrace`. Default sample rate 997 Hz. Needs `[profile.release] debug = true` for symbols. Flag `--no-inline` if everything inlines into `main`.
- **`samply`** — modern alternative; opens results in Firefox Profiler (richer flame view than svg). `cargo install samply && samply record ./target/release/bin`.
- **`tracy`** — frame-oriented, real-time profiler; instrumentation via `tracing-tracy` or the `tracy-client` crate. Best for game/render/realtime work.
- **`pprof-rs`** — in-process CPU profiler usable inside HTTP services; emits pprof or flamegraph on demand.
- **Always pair with**: `RUSTFLAGS="-C force-frame-pointers=yes"` for accurate stacks on optimized code.

## Allocators

- **Default allocator** is the system allocator (glibc malloc on Linux, libSystem on macOS, HeapAlloc on Windows). Long-running services see fragmentation and tail-latency spikes under multithreaded churn.
- **jemalloc** swap (`tikv-jemallocator` crate, 0.6+):
  ```rust
  #[global_allocator]
  static GLOBAL: tikv_jemallocator::Jemalloc = tikv_jemallocator::Jemalloc;
  ```
  Better fragmentation, per-thread arenas, ~5–15% latency improvements on contended workloads.
- **mimalloc** (`mimalloc` crate): smaller code, often best on Windows; competitive on Linux.
- **Arena allocators** (`bumpalo`, `typed-arena`): single-bump-pointer, drop-everything-at-once. Massive wins for request-scoped allocations in servers, parser ASTs, ECS frame allocations. Caveat: items aren't dropped individually — careful with `Drop` types.
- **Detecting it's worth it**: RSS growth over 24h with steady workload, or `jemalloc`'s `stats.print` showing high external fragmentation. Don't swap without a baseline.

## no_std and embedded

- **`#![no_std]`**: links against `core` only, not `std`. No heap, no threads, no `Vec`, no `String`, no `println!`.
- **`extern crate alloc;`** + a `#[global_allocator]` re-enables `Box`/`Vec`/`String`/`BTreeMap` without full `std`. Common embedded allocators: `embedded-alloc`, `linked_list_allocator`, `talc`.
- **`#[panic_handler]`** is **mandatory** in `no_std` binaries — no default exists. Common crates: `panic-halt`, `panic-abort`, `panic-semihosting`, `panic-probe` (defmt).
- **`#[global_allocator]`** mandatory if you `extern crate alloc;` in `no_std`.
- **Floats**: `core::f32` lacks transcendentals (`sin`, `cos`, `exp`) — use `libm` crate.
- **`#![no_main]`** + `#[entry]` from `cortex-m-rt` (or equivalent) replace the standard `main`.

## Build performance

- **`cargo check`** is 2–3x faster than `cargo build` — runs frontend + borrow check, skips codegen. Use in editors/CI for fast feedback.
- **`cargo build --timings`** generates `target/cargo-timings/cargo-timing.html` — Gantt of dep parallelism. Look for sequential bottlenecks (build-script crates that block everything).
- **`mold` linker** (Linux): `RUSTFLAGS="-C link-arg=-fuse-ld=mold"` or `[target.x86_64-unknown-linux-gnu] linker = "clang"; rustflags = ["-C", "link-arg=-fuse-ld=mold"]`. **5–10x faster link** on big binaries.
- **`lld`**: cross-platform LLVM linker. `-C link-arg=-fuse-ld=lld`. Slower than mold on Linux; fine on macOS via `-C link-arg=-fuse-ld=lld` if installed.
- **`sccache`**: shared compilation cache, best for CI and multi-project workstations. `RUSTC_WRAPPER=sccache cargo build`. Less useful for incremental local builds (cargo's own incremental is faster).
- **`-Z share-generics`** (nightly): share monomorphizations across crates. `RUSTFLAGS="-Zshare-generics=y"`. ~10–20% rebuild win on big workspaces.
- **`-Z threads=N`** (nightly): parallel frontend. `RUSTFLAGS="-Zthreads=8"`. Up to 50% wall-clock win on cold builds.
- **Incremental gotcha**: incremental compilation caches in `target/debug/incremental` can corrupt and produce baffling errors. `cargo clean -p <crate>` if a single crate misbehaves; `rm -rf target/debug/incremental` for full reset.
- **Per-file build-script optimization**: `[profile.dev.build-override] opt-level = 3` — proc-macros and build scripts run optimized even in dev.

## Supply-chain

- **`cargo audit`** (`cargo install cargo-audit`): scans `Cargo.lock` against the RustSec advisory database. CI-friendly, exits non-zero on findings.
- **`cargo deny`** (`cargo install --locked cargo-deny`): broader than audit. Four checks: `licenses` (allow/deny SPDX list), `bans` (forbid specific crates, detect duplicates), `advisories` (RustSec), `sources` (only registry crates from approved registries / git URLs). Single `deny.toml` config.
- **`cargo vet`** (Mozilla): per-dependency human review attestations, audit imports from other orgs (e.g., import Mozilla's audits). Heavier than `audit`/`deny`; intended for orgs that ship to end users.
- **`cargo update --precise X.Y.Z -p crate`**: pin a single transitive dep to dodge an advisory without bumping everything else.

## Authoritative references

**Official docs** (`doc.rust-lang.org`):
- [The Rustonomicon](https://doc.rust-lang.org/nomicon/) — `unsafe`, aliasing, drop check, variance
- [Rust Reference: Subtyping & Variance](https://doc.rust-lang.org/reference/subtyping.html)
- [`std::pin`](https://doc.rust-lang.org/std/pin/index.html)
- [`std::mem::MaybeUninit`](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html)
- [`std::sync::Mutex`](https://doc.rust-lang.org/std/sync/struct.Mutex.html)
- [Async Book](https://rust-lang.github.io/async-book/)
- [Embedded Rust Book](https://docs.rust-embedded.org/book/)
- [Cargo profiles](https://doc.rust-lang.org/cargo/reference/profiles.html)
- [Edition 2024 guide](https://doc.rust-lang.org/edition-guide/rust-2024/)

**Tooling**:
- [tokio docs](https://docs.rs/tokio/) — `spawn_blocking`, `block_in_place`, runtime flavors
- [miri](https://github.com/rust-lang/miri) — UB detection
- [pin-project](https://docs.rs/pin-project/) — sound pin projection
- [cargo-deny book](https://embarkstudios.github.io/cargo-deny/) / [RustSec advisory DB](https://rustsec.org/)
- [flamegraph-rs](https://github.com/flamegraph-rs/flamegraph), [samply](https://github.com/mstange/samply)

**Authoritative blogs**:
- Niko Matsakis — [smallcultfollowing.com/babysteps](https://smallcultfollowing.com/babysteps/) (Polonius, NLL, lang-team rationale)
- Amos / fasterthanlime — pin, async, ergonomic deep-dives
- without.boats — async fundamentals, Pin design history
- Yoshua Wuyts — async ecosystem, traits
- Ralf Jung — UB, Stacked/Tree Borrows, miri internals
- Nicholas Nethercote — [The Rust Performance Book](https://nnethercote.github.io/perf-book/)
- corrode.dev (Matthias Endler) — compile-time and ergonomics

## Guardrails

Before recommending a non-trivial operational change (allocator swap, panic strategy, codegen-units, RUSTFLAGS, `unsafe` code):
1. Quote the specific flag/setting and its default
2. Cite the official Rust doc / Reference / Nomicon / Async Book section
3. Make the recommendation conditional on observed evidence — never blanket-tune

**Tuning without measurement is worse than defaults.** And: every `unsafe` block must list the invariants it upholds in a `// SAFETY:` comment.

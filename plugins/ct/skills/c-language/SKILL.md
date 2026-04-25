---
name: c-language
description: >
  Deep C operational intuition — undefined behavior landmines, sanitizer workflows
  (ASan/UBSan/TSan/MSan), Valgrind tooling, hardening flag stacks, strict aliasing,
  alignment, atomics and memory ordering, static analysis, and ABI quirks.
  Load ONLY when the task is about UB diagnosis, sanitizer setup, hardened build
  flags, data-race investigation, alignment/atomics correctness, fuzzing harnesses,
  or porting/ABI debugging. Do NOT load for ordinary C coding, simple stdio, basic
  malloc/free, or syntax help — those don't need this skill.
  Triggers on: "undefined behavior", "strict aliasing", "signed overflow",
  "AddressSanitizer", "UBSan", "ThreadSanitizer", "MemorySanitizer", "Valgrind",
  "data race", "use-after-free", "memory corruption", "alignment fault",
  "type punning", "_FORTIFY_SOURCE", "stack canary", "hardening flags",
  "memory_order", "atomic", "restrict keyword", "libFuzzer", "AFL++",
  "clang-tidy", "scan-build", "ABI", "calling convention".
---

# C Language Operational Guide

Concise pointers for C undefined-behavior diagnosis, sanitizer/fuzzer workflows, and hardened builds.

Assumes you already know pointers, structs, malloc/free, and basic stdio. This skill covers the **operational layer** — the parts models gloss over: UB landmines that compilers weaponize, sanitizer combinations and their costs, hardening flag stacks, and ABI/alignment quirks.

## When to use

Load when the question is about:
- Undefined behavior (signed overflow, strict aliasing, shifts, alignment, sequence)
- Sanitizer selection / combining (ASan + UBSan vs TSan vs MSan)
- Hardening flags for production builds (`_FORTIFY_SOURCE`, RELRO, CFI, PIE)
- Memory corruption / use-after-free / data-race diagnosis
- Atomics, memory orderings, when `volatile` is and isn't valid
- Static analysis (clang-tidy, scan-build, Coverity, CodeQL)
- Fuzzing (libFuzzer, AFL++, OSS-Fuzz harness)
- Cross-platform ABI / calling convention / glibc-vs-musl porting

**Do NOT load** for: writing basic C, simple `printf`/`scanf`, struct layout walk-throughs, learning malloc/free — defaults are fine.

## UB landmines compilers weaponize

Compilers treat UB as `assume(no UB)` and delete code paths assuming the assumption held. Stating the rule: **once UB happens, the entire execution is meaningless** (Regehr).

- **Signed integer overflow is UB** (`INT_MAX + 1`). Compiler may delete the bounds check `if (x + 1 < x) abort()` because the only way `x+1<x` is via overflow which "can't happen." Tame with `-fwrapv` (defines wrap as two's complement) or trap with `-ftrapv`. Detect at runtime via `-fsanitize=signed-integer-overflow`.
- **Integer promotion bites silently**: `uint16_t a = 0xFFFF; a*a` promotes to `int` first → `0xFFFE0001` overflows signed `int` on 32-bit `int`. UB. Force unsigned: `(uint32_t)a * a`.
- **Shifts**: `x << n` with `n >= width(x)` is UB. So is shift of negative signed value. `1 << 31` on 32-bit `int` is UB (sign-bit). Use `1u << 31` or `(uint32_t)1 << 31`.
- **Strict aliasing (C11 6.5p7)**: an object's stored value may only be accessed via lvalue of (a) compatible type, (b) qualified version, (c) signed/unsigned variant, (d) aggregate containing it, or (e) **character type**. Casting `int*` to `float*` and dereferencing is UB. Compilers use this for TBAA optimizations and will reorder writes through "incompatible" pointers.
- **Type punning — portable form is `memcpy`**: `float f; uint32_t u; memcpy(&u, &f, sizeof u);` Compilers recognize this and emit zero copies at `-O1`+. Union punning is implementation-defined in C99 but well-defined in C11 §6.5.2.3 footnote — still avoid for portability across C++ and odd compilers. Pointer-cast punning is UB except via `char*`.
- **Strict-aliasing escape hatches**: `-fno-strict-aliasing` (Linux kernel ships with this), `__attribute__((may_alias))` on a typedef to mark it as aliasing-permissive, or `memcpy` for one-off pun.
- **Null pointer reorder hazard**: `int x = p->a; if (p) ...` — the deref *before* the null check tells the compiler `p` is non-null, so it deletes the `if`. CVE-2009-1897 (Linux tun driver) was exactly this. Tame with `-fno-delete-null-pointer-checks`.
- **Uninitialized auto reads are UB** even if the value isn't used arithmetically. MSan catches; `-Wuninitialized` catches some at compile time.
- **Sequence points / unsequenced**: `i = i++ + 1;`, `a[i] = i++;` are UB pre-C11 and unsequenced/UB in C11. `-Wsequence-point` warns.
- **Out-of-bounds (OOB)**: even computing `arr + n+1` (one past *one past*) is UB. ASan catches reads/writes; UBSan with `-fsanitize=bounds` catches indexing.
- **Effective type rule** (6.5p6): a malloc'd region's "effective type" is set by the first store; subsequent accesses must match aliasing rules.

## Sanitizer matrix — pick one per build

| Sanitizer | Flag | Slowdown | Memory | Detects | Notes |
|---|---|---|---|---|---|
| ASan | `-fsanitize=address` | ~2x | up to 3x stack, 16+ TB virt | heap/stack/global OOB, UAF, double-free | Leak detection on Linux by default; `ASAN_OPTIONS=detect_leaks=1` on macOS |
| UBSan | `-fsanitize=undefined` | small | minimal | signed overflow, shifts, alignment, null deref, bad enum, vptr | Pair with `-fno-sanitize-recover=undefined` to abort on first hit |
| TSan | `-fsanitize=thread` | 5–15x | 5–10x | data races, lock-order issues | 64-bit only; PIE required; **cannot** combine with ASan |
| MSan | `-fsanitize=memory` | ~3x (1.5–2x more w/ origins) | 2–3x | uninitialized reads | clang-only; needs instrumented libc++/dependencies; `-fsanitize-memory-track-origins=2` |
| LeakSan | `-fsanitize=leak` | tiny | tiny | leaks only | Subset of ASan |

- **Combine ASan+UBSan** in dev/CI: `-fsanitize=address,undefined -fno-omit-frame-pointer -g -O1`. Keep `-O1` minimum so inlined frames remain readable but optimizations aren't disabled (some bugs only manifest under opt).
- **Cannot combine TSan with ASan** — separate build configurations.
- **Static linking unsupported** for ASan/TSan; PIE required for TSan.
- Production: never ship ASan-instrumented binaries — info disclosure risk per upstream guidance.

## Valgrind — when sanitizers don't fit

- **memcheck** (default): heap OOB, UAF, leaks, uninitialized reads. ~20–30x slowdown.
- **helgrind**: data races via lockset analysis (different algorithm than TSan).
- **drd**: alternative data-race detector, lighter on false positives for some patterns.
- **callgrind**: call-graph + cache profiling (use `kcachegrind` to view).
- **massif**: heap profiler — peak usage and call-stack attribution.
- **cachegrind**: instruction-level cache simulation.
- **Cannot run Valgrind on an ASan-instrumented binary** — they fight over the same address-space tricks. Build a vanilla binary for Valgrind.
- Use Valgrind when: ASan can't run (uninstrumented prebuilt deps), need cache/heap *profiling* not just bug detection, embedded targets without sanitizer runtime.

## Hardening flag stack for production

Stack these in release builds:

```
-O2 -D_FORTIFY_SOURCE=3 \
-fstack-protector-strong -fstack-clash-protection \
-fcf-protection=full \
-fPIE -pie \
-Wl,-z,relro,-z,now -Wl,-z,noexecstack
```

- `-D_FORTIFY_SOURCE=2`: compile-time + runtime checks on `str*`, `mem*`, `*printf` using `__builtin_object_size`.
- `-D_FORTIFY_SOURCE=3` (glibc ≥ 2.34, GCC ≥ 12): uses `__builtin_dynamic_object_size` — protects ~2.4x more call sites than =2 with no measured perf impact (Fedora SPEC2017 data). Default in Fedora/Arch.
- `-fstack-protector-strong`: canaries on functions with arrays or address-taken locals (better coverage than plain `-fstack-protector`, less overhead than `-all`).
- `-fstack-clash-protection`: probes each page on large allocations, defeats stack-clash (CVE-2017-1000366 class).
- `-fcf-protection=full` (x86-64): IBT/SHSTK, Intel CET — defends ROP/JOP. ARM equivalent: `-mbranch-protection=standard`.
- `-fPIE -pie`: enables ASLR for the executable text. Required on most modern distros.
- `-Wl,-z,relro,-z,now`: full RELRO — GOT made read-only, lazy binding disabled. Defeats GOT overwrite.
- `-Wl,-z,noexecstack`: NX bit on stack pages.
- GCC 14+ has `-fhardened` as a single switch enabling these.

## Warnings worth turning on (and treating as errors)

```
-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wsign-conversion \
-Wformat=2 -Wformat-security -Wstrict-prototypes \
-Wold-style-definition -Wmissing-prototypes -Wmissing-declarations \
-Wcast-align -Wcast-qual -Wpointer-arith -Wnull-dereference \
-Wdouble-promotion -Wfloat-equal -Wundef -Wwrite-strings \
-Werror=implicit-function-declaration -Werror=incompatible-pointer-types
```

- `-Werror=implicit-function-declaration` is critical: pre-C99 implicit `int` declarations silently corrupt `long`/`size_t` returns on 64-bit. C23 removes implicit declarations — catch them now.
- `-Wstrict-prototypes` + `-Wold-style-definition`: forbid K&R `f()` (which means "unspecified args", not "no args" pre-C23). C23 makes `f()` mean `f(void)` — code relying on K&R semantics breaks.
- `-Wcast-align`: catches alignment-reducing casts that segfault on ARMv7/SPARC and are *silently slow* on x86.

## Alignment and `restrict`

- **Natural alignment**: `_Alignof(T)` (C11). Misaligned access is UB even on x86 where it merely tanks perf; on ARMv7 it traps. ARMv8 + Linux usually fixes up but spends µs each.
- `_Alignas(N) T x;` requests alignment. For dynamic: `aligned_alloc(N, size)` (C11) or POSIX `posix_memalign(&p, N, size)`. `N` must be a power of two and ≥ `sizeof(void*)`.
- `__builtin_assume_aligned(p, 16)` tells the compiler `p` is 16-aligned — enables vectorized loads. UB if false.
- `__attribute__((packed))` on a struct: removes padding, but member loads through `&s->member` are now misaligned reads — UB on strict-alignment archs unless accessed through the struct expression itself. Prefer `memcpy` for packed-struct field access.
- **`restrict`** (C99): function parameter `T *restrict p` is a *promise by the caller* that no other pointer in scope reaches the same object during `p`'s lifetime. Lets compiler skip aliasing-pessimization (vectorize, hoist loads). Violating is UB. `memcpy` and `strcpy` use `restrict` — calling with overlapping ranges is UB; use `memmove` for overlap.

## Atomics and memory ordering

`<stdatomic.h>` (C11). Not for "make it threadsafe" — for *lock-free shared state* and for breaking out of memory-ordering races. Locking already implies the right barriers.

- `_Atomic T x;` — declare. `atomic_load_explicit(&x, mo)`, `atomic_store_explicit`, `atomic_fetch_add_explicit`, `atomic_compare_exchange_strong_explicit`.
- Memory orders, weakest → strongest:
  - `memory_order_relaxed`: counter increments, no ordering. Only when ordering doesn't matter.
  - `memory_order_acquire`: paired with release; prevents reads after acquire from reordering before it. Used on the load side of a lock-free handoff.
  - `memory_order_release`: prevents writes before release from reordering after it. Used on the store side. **Pair with acquire on a matching variable.**
  - `memory_order_acq_rel`: for read-modify-write (CAS, fetch_add) where both sides matter.
  - `memory_order_seq_cst` (default for non-`_explicit` ops): single total order across all threads. Most expensive — full fence on x86, dmb-ish on ARM.
  - `memory_order_consume`: deprecated/effectively `acquire` on all real compilers.
- `atomic_thread_fence(mo)`: standalone fence when you want the ordering without any specific atomic op.
- `atomic_compare_exchange_weak` may spuriously fail on LL/SC archs (ARM/PPC) — must be in a loop. `_strong` retries internally; use when you can't loop.
- **`volatile` is NOT for threading.** It only suppresses optimization on a single thread — gives no atomicity, no inter-thread ordering, no cross-CPU coherency. Use atomics. `volatile` is correct for: memory-mapped I/O registers, variables touched by `setjmp`/signal handlers (must be `volatile sig_atomic_t`), `asm volatile` to prevent dead-code elimination of side-effect asm. Linux kernel adds: I/O accessors, the `jiffies` legacy variable, DMA-coherent buffers.

## Static analysis and fuzzing

- **clang-tidy**: enable `bugprone-*`, `cert-*`, `clang-analyzer-*`, `misc-*`. Run via `clang-tidy -checks='bugprone-*,cert-*,clang-analyzer-*' src/*.c -- -I include`. CERT aliases redirect to the underlying check (e.g., `cert-int30-c` = `bugprone-misplaced-widening-cast` family).
- **scan-build** (clang static analyzer): `scan-build make` — path-sensitive symbolic execution, finds null derefs, leaks, dead stores. Best for catching things UBSan misses at compile time.
- **cppcheck**: complementary to clang-tidy — fewer false positives on classic mistakes, catches things in unparseable preprocessor regions.
- **CodeQL** (`github/codeql-action`): semantic queries; great for taint analysis and finding patterns across a repo.
- **Coverity**: commercial, deeper interprocedural; free for OSS via Synopsys.
- **libFuzzer** (`-fsanitize=fuzzer`): in-process, coverage-guided. Define `int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size)`. Combine with sanitizers: `-fsanitize=fuzzer,address,undefined`. Target must be deterministic, fast (sub-ms), tolerate malformed input, and not modify global state. No `exit()` in the harness.
- **AFL++**: out-of-process fuzzer, persistent mode for speed (`AFL_PERSISTENT`), supports CmpLog and structure-aware mutators. Compile with `afl-clang-lto`. Pair with ASan/UBSan via `AFL_USE_ASAN=1`.
- **OSS-Fuzz / ClusterFuzzLite**: continuous fuzzing infra. ClusterFuzzLite runs in GitHub Actions per-PR.

## Debugging tooling

- **gdb**: enable `set print pretty on`, `set print object on`. Pretty-printers via `python` block in `~/.gdbinit` (libstdc++/libc++ ship them; for C structs write your own). For mixed inline frames: `-Og -g3` rather than `-O0`.
- **rr** (record/replay): `rr record ./prog && rr replay` — reverse-execute (`reverse-cont`, `reverse-step`) to walk backwards from a crash. Linux/x86-64 only. Indispensable for non-deterministic bugs.
- **perf**: `perf record -g ./prog && perf report` for sampling profiles. `perf stat -e cache-misses,cycles,instructions` for HW counters.
- **ftrace / bpftrace**: kernel-side syscall tracing without instrumentation.
- Core-dump triage: `coredumpctl debug` (systemd), or `gdb prog core.NN`. Build with `-g` always (strip later for distribution); `-fno-omit-frame-pointer` for usable stacks under sampling profilers.

## ABI, libc, and portability

- **System V AMD64** (Linux/macOS/BSD): args in `rdi, rsi, rdx, rcx, r8, r9`, return in `rax`, callee-saved `rbx, rbp, r12-r15`. **Windows x64** different: `rcx, rdx, r8, r9`, more callee-saved, shadow space — never assume calling conv when JIT'ing or writing inline asm.
- `extern "C"` (when used from C++) only fixes name mangling — does *not* normalize calling conv across OS. For ABI-stable C APIs, document layout: pin struct sizes with `static_assert(sizeof(s) == N)` (C11 `_Static_assert`).
- **glibc vs musl** gotchas:
  - `getline`, `strdupa`, `qsort_r` differ or are absent on musl.
  - musl's `pthread_*` doesn't ship the same symbol versions; `LD_PRELOAD` interposers built against glibc may break.
  - musl's `name_max` and `PATH_MAX` handling stricter; some `getaddrinfo` corners differ.
  - musl uses fully-static-friendly threading; glibc's `pthread_create` has TLS quirks under `dlopen`.
- `errno` is **thread-local** (per `_REENTRANT`/`__thread`) but **not signal-safe** to read across signal handlers reliably without `volatile sig_atomic_t` flagging. Almost any libc call may clobber `errno` — capture it immediately after the call.
- `size_t` is unsigned; `ssize_t` (POSIX) is signed; `ptrdiff_t` is the result of pointer subtraction. Mixing in arithmetic with signed widths leads to surprising promotion. `-Wsign-conversion` flags it.
- `time_t`: 32-bit on some legacy systems → 2038 problem. Modern glibc defaults 64-bit.

## Authoritative references

**Compilers**:
- [GCC Instrumentation Options](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html) — sanitizers, `-fstack-protector*`, `-fcf-protection`, `-fhardened`
- [GCC Optimize Options](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html) — `-fwrapv`, `-fno-strict-aliasing`, `-fno-delete-null-pointer-checks`
- [GCC Warning Options](https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html) — full warning catalog
- [Clang AddressSanitizer](https://clang.llvm.org/docs/AddressSanitizer.html)
- [Clang UndefinedBehaviorSanitizer](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html)
- [Clang ThreadSanitizer](https://clang.llvm.org/docs/ThreadSanitizer.html)
- [Clang MemorySanitizer](https://clang.llvm.org/docs/MemorySanitizer.html)
- [LLVM libFuzzer](https://llvm.org/docs/LibFuzzer.html)

**Standards & rules**:
- [SEI CERT C Coding Standard](https://wiki.sei.cmu.edu/confluence/display/c/SEI+CERT+C+Coding+Standard) — INT/MEM/EXP rules
- ISO C drafts: N1570 (C11), N2310 (C17), N3096 (C23)

**UB deep-dives**:
- [John Regehr — A Guide to Undefined Behavior in C and C++](https://blog.regehr.org/archives/213)
- [Regehr — Type Punning, Strict Aliasing, and Optimization](https://blog.regehr.org/archives/959)
- [Regehr — The Strict Aliasing Situation is Pretty Bad](https://blog.regehr.org/archives/1307)
- [Shafik Yaghmour — What is Strict Aliasing](https://gist.github.com/shafik/848ae25ee209f698763cffee272a58f8)

**Hardening**:
- [Red Hat — _FORTIFY_SOURCE=3](https://developers.redhat.com/articles/2022/09/17/gccs-new-fortification-level)
- [Fedora — _FORTIFY_SOURCE=3 distribution flag](https://fedoraproject.org/wiki/Changes/Add_FORTIFY_SOURCE=3_to_distribution_build_flags)

**Tooling**:
- [Valgrind manual](https://valgrind.org/docs/manual/manual.html) — memcheck, helgrind, drd, callgrind, massif
- [clang-tidy checks](https://clang.llvm.org/extra/clang-tidy/checks/list.html)
- [Linux kernel — volatile considered harmful](https://www.kernel.org/doc/html/latest/process/volatile-considered-harmful.html)

## Guardrails

Before recommending a non-trivial flag stack, sanitizer config, or atomics ordering:
1. Quote the exact flag/ordering name (e.g., `-fsanitize=undefined`, `memory_order_acquire`) — never paraphrase.
2. State the cost (slowdown factor, build-config exclusivity, libc requirement).
3. Cite the upstream doc (clang.llvm.org, gcc.gnu.org, kernel.org, CERT).
4. Make recommendations conditional on the bug class actually observed — do not blanket-enable TSan when the symptom is a leak, or MSan when the symptom is a race.

**Sanitizer output without root-cause diagnosis is worse than silence — it teaches the team to ignore alerts.**

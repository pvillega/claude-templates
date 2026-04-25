---
name: redis
description: >
  Deep Redis operational intuition — RDB/AOF persistence math, eviction policy
  semantics, SLOWLOG/LATENCY/MEMORY diagnostics, cluster vs Sentinel topology,
  hash slots and resharding, replication backlog tuning, ACLs, Streams vs Pub/Sub,
  fragmentation handling, and the Valkey/KeyDB/Dragonfly variant landscape.
  Load ONLY when the task is about deep operational tuning, incident diagnosis,
  persistence durability tradeoffs, eviction misbehavior, latency spikes,
  cluster/sentinel topology, replication lag, hot-key detection, ACL hardening,
  or evaluating a Redis fork. Do NOT load for ordinary key/value work, command
  syntax lookup, or "what is Redis" — those don't need this skill.
  Triggers on: "redis persistence", "RDB vs AOF", "appendfsync", "maxmemory-policy",
  "redis eviction", "redis OOM", "SLOWLOG", "LATENCY DOCTOR", "redis cluster",
  "hash slot migration", "MOVED redirect", "redis sentinel", "failover quorum",
  "replication backlog", "PSYNC full resync", "redis fragmentation", "activedefrag",
  "redis hot key", "bigkeys", "redis ACL", "redis streams", "consumer group",
  "valkey", "keydb", "dragonfly".
---

# Redis Operational Guide

Concise operational pointers for deep Redis troubleshooting and tuning.

Assumes you already know `SET`/`GET`/`EXPIRE`/`TTL` and basic data types. This skill covers the **operational layer** — the parts models tend to gloss over: persistence durability math, eviction internals, latency monitoring, cluster topology, replication, and the post-2024 fork landscape.

## When to use

Load when the question is about:
- Persistence tradeoffs (RDB snapshot vs AOF, fsync policy, hybrid preamble, durability windows)
- Eviction misbehavior (OOM errors, wrong keys evicted, LRU vs LFU semantics, sample size)
- Memory analysis (`MEMORY USAGE`/`DOCTOR`/`STATS`, `--bigkeys`, fragmentation, `activedefrag`)
- Latency / slow-query diagnosis (`SLOWLOG`, `LATENCY MONITOR`, fork stalls, AOF rewrites)
- Cluster operations (16384 slots, MOVED/ASK redirects, hash tags, resharding, multi-key ops)
- Sentinel HA (quorum, `down-after-milliseconds`, `parallel-syncs`, split-brain)
- Replication (`PSYNC` partial vs full, `repl-backlog-size`, `min-replicas-to-write`)
- Pipelining vs `MULTI`/`EXEC`/`WATCH` (atomicity, optimistic locking, RTT batching)
- Streams (consumer groups, PEL, `XCLAIM`/`XAUTOCLAIM`, at-least-once delivery)
- ACL hardening (categories, key/channel patterns, default user lockdown)
- Hot-key detection (`--hotkeys`, `INFO commandstats`, why not `MONITOR`)
- Choosing between Redis 7+, Valkey, KeyDB, Dragonfly

**Do NOT load** for: writing `SET`/`GET`/`HSET`, basic data-type questions, library client tutorials, schema-style key naming. Those don't need this skill.

## Persistence: RDB, AOF, hybrid

- **RDB** (snapshot): point-in-time binary dump (`dump.rdb`). Smallest file, fastest restart. Default trigger `save 3600 1 300 100 60 10000` (Redis 7+) — snapshot if 1 change in 1h **or** 100 in 5min **or** 10000 in 60s. `BGSAVE` for manual; `SAVE` blocks the main thread (don't use in prod).
- **AOF** (append-only file): every write logged; replayed on restart. `appendonly yes`. Fsync policy via `appendfsync`:
  - `always` — fsync per write. Strong durability, ~1k ops/s ceiling on rotational disk.
  - `everysec` — **default**. ~1s worst-case data loss window; the practical durability/perf sweet spot.
  - `no` — kernel-driven (~30s on Linux). Fastest, weakest durability.
- **AOF rewriting** to compact: `BGREWRITEAOF` manual; auto via `auto-aof-rewrite-percentage 100` + `auto-aof-rewrite-min-size 64mb` (rewrite when AOF doubles since last rewrite **and** ≥ 64 MB).
- **Hybrid preamble**: `aof-use-rdb-preamble yes` (default since Redis 4, on by default 7+). AOF starts with an RDB binary chunk, then incremental commands. Faster recovery than pure AOF, more durable than pure RDB.
- **Restart precedence**: if both AOF and RDB exist, Redis loads AOF (better durability). Don't expect RDB to win.
- **Cache mode (no persistence)**: requires BOTH `save ""` AND `appendonly no`. Setting only one leaves the other active.
- **Fork cost**: `BGSAVE`/`BGREWRITEAOF` use `fork()` — Linux CoW means the child starts with shared pages but copies on write. Peak memory can transiently approach 2× RSS during heavy write traffic. Watch `latest_fork_usec` from `INFO`.

## Eviction policies

- Set the cap: `maxmemory 4gb`. Cgroup memory limit is independent — set both to avoid OOM-kill.
- `maxmemory-policy` (default `noeviction`):
  - `noeviction` — writes fail with OOM error when full. Reads still work. **Default**, surprises users.
  - `allkeys-lru` / `allkeys-lfu` / `allkeys-random` — any key eligible.
  - `volatile-lru` / `volatile-lfu` / `volatile-random` / `volatile-ttl` — only keys with TTL eligible. **Footgun**: if no keys have TTL, behaves like `noeviction`.
- **LRU is approximated**: Redis samples `maxmemory-samples` keys (default `5`) and evicts the worst. Bump to `10` for accuracy, `3` for speed. True LRU would require tracking every access.
- **LFU** uses a logarithmic counter with decay:
  - `lfu-log-factor 10` (default) — higher = slower counter saturation; favors long-tail hot keys.
  - `lfu-decay-time 1` (default, minutes) — how fast counter decays toward 0.
  - LFU survives access bursts better than LRU; preferred for typical caches.
- **`volatile-ttl`**: evicts keys with the **shortest** remaining TTL first. Useful when TTL encodes priority.
- **Diagnostic**: `INFO stats` → `evicted_keys` counter. Rising fast → cap too low or wrong policy.

## Memory, key inspection, fragmentation

- **Per-key**: `MEMORY USAGE key [SAMPLES n]` — bytes (sampling for collections).
- **Aggregate**: `MEMORY STATS` per-pool (overhead, dataset, allocator). `MEMORY DOCTOR` — narrative summary; flags fragmentation, child-process forks, big clients.
- **Scans**:
  - `redis-cli --bigkeys` — sample-based largest-by-type. Fast, approximate.
  - `redis-cli --memkeys --memkeys-samples 0` — accurate but full-scan (heavy).
  - `redis-cli --keystats` — per-type byte/length distribution.
  - `redis-cli --hotkeys` — top accessed keys. **Requires `maxmemory-policy *-lfu`** (uses LFU counters).
- **Don't `MONITOR` in production**: streams every command server-wide, ~50 % perf hit. Use `redis-cli -i 1 -r 60 INFO commandstats` for periodic sampling; diff between samples surfaces hot patterns.
- **Hot-key mitigations**: client-side caching (`CLIENT TRACKING ON` over RESP3), key sharding (`{user:1234}:counter:{0..9}` then sum), or read replicas with `READONLY`.
- **Fragmentation**: `INFO memory` → `mem_fragmentation_ratio = used_memory_rss / used_memory`.
  - `> 1.5` → real fragmentation (jemalloc holding free pages).
  - `< 1.0` → swapping (RSS smaller than logical). Investigate `vmstat`.
- **Active defrag** (Redis 4+, jemalloc only): `activedefrag yes`. Triggers when `active-defrag-ignore-bytes 100mb` AND `active-defrag-threshold-lower 10` (% fragmentation) both met. CPU-bounded by `active-defrag-cycle-min`/`max` (1–25 % default).

## SLOWLOG and LATENCY MONITOR

- **Slow log** (per-command execution time, excluding I/O):
  - `slowlog-log-slower-than 10000` — microseconds; default 10 ms. `0` logs every command, `-1` disables.
  - `slowlog-max-len 128` — ring buffer length.
  - `SLOWLOG GET 10` last 10; `SLOWLOG LEN`; `SLOWLOG RESET`.
  - Captures command name + truncated args + duration. Args truncated to `slowlog-log-slower-than` not affecting field.
- **Latency monitor** (Redis 4+, samples *event* latency, not command):
  - `latency-monitor-threshold 100` — ms; `0` (default) disables.
  - Events: `command`, `fast-command`, `fork`, `aof-write`, `aof-fsync-always`, `aof-stat`, `aof-rewrite-diff-write`, `rdb-unlink-temp-file`, `expire-cycle`, `eviction-cycle`, `eviction-del`.
  - `LATENCY LATEST` — most recent event per type.
  - `LATENCY HISTORY <event>` — time series for one event.
  - `LATENCY GRAPH <event>` — ASCII spark chart.
  - `LATENCY DOCTOR` — narrative analysis with remediation hints.
  - `LATENCY RESET [event ...]`.
- **`MONITOR` is not a diagnostic tool**: streams every command to the client. ~50 % perf hit on the server. Use `redis-cli -i 1 -r 60 INFO commandstats` for periodic sampling instead.

## Cluster, Sentinel, replication

**Cluster** (sharded; horizontal scale + HA):
- 16384 hash slots, `slot = CRC16(key) mod 16384`. Each master owns a slot range. Min 3 masters for HA failover voting; recommended 6 nodes (3 master + 3 replica).
- Slot inspection: `CLUSTER SHARDS` (Redis 7+, structured, **prefer this**), `CLUSTER NODES` (raw), `CLUSTER SLOTS` (legacy). Per-slot: `CLUSTER COUNTKEYSINSLOT <slot>` / `CLUSTER GETKEYSINSLOT <slot> <count>`.
- Redirects: `MOVED <slot> ip:port` — permanent, refresh slot map. `ASK <slot> ip:port` — slot in migration, one-shot, do NOT cache. Smart clients cache the slot table and recompute on `MOVED`.
- Hash tags: `{tag}key` — only substring inside `{...}` is hashed. Forces same-slot routing for multi-key ops.
- Multi-key constraint: `MGET`, `MSET`, `SINTERSTORE`, `MULTI`/`EXEC`, Lua `EVAL` — all keys must hash to same slot or `CROSSSLOT` error.
- Tooling: `redis-cli --cluster {create,check,fix,reshard,rebalance,info,call,import}`. `--cluster check` finds slot coverage gaps and stuck open slots.
- Sharded Pub/Sub (Redis 7+): `SPUBLISH`/`SSUBSCRIBE` route by hash slot; replaces broadcast `PUBLISH` which was inefficient cluster-wide.

**Sentinel** (HA for non-sharded master + replicas):
- Sentinel monitors a single master and promotes a replica on failure. **Not** a sharded topology.
- `sentinel monitor <name> <master> <port> <quorum>`. `quorum` = sentinels that must agree master is `s_down` before voting starts. Election requires **majority** of all sentinels (distinct from quorum).
- `sentinel down-after-milliseconds <name> <ms>` — unresponsive duration before `s_down` (subjective). Quorum count → `o_down` (objective) → election.
- `sentinel parallel-syncs <name> <N>` — replicas resyncing from new master simultaneously. Default 1; higher = faster convergence, more I/O on new master.
- `sentinel failover-timeout <name> <ms>` — bounds full failover; also throttles retry on failed failover. Default 180000 (3 min).
- **Odd sentinel count**: 3 or 5, never 2 or 4. Even counts can split-brain.
- Sentinels rewrite their own config file on state changes — back up before editing.

**Replication** (under both cluster and sentinel):
- `replicaof <host> <port>` (or deprecated `slaveof`). Replica is read-only by default (`replica-read-only yes`).
- **Sync types**: **full** — master `BGSAVE`s an RDB, ships, replays buffered commands. Triggered on fresh replica, ID mismatch, or backlog gap. **Partial** (`PSYNC`) — replica reconnects with last offset; if master's backlog still covers it → ship the delta.
- `repl-backlog-size` — circular buffer on master holding recent writes for partial resync. Default `1mb`. **Too small → frequent full resyncs after any blip**. Bump to 64–512 MB on busy masters with flaky networks. Cost is buffer size, master-side.
- `repl-backlog-ttl 3600` — release backlog after N seconds with no replicas connected.
- Durability gate on master: `min-replicas-to-write N` + `min-replicas-max-lag M` (seconds) — master refuses writes unless ≥ N replicas have lag ≤ M.
- Eventual consistency on read: replicas can be stale. Don't use `replicaof` topology for read-after-write without explicit fencing.
- Replication ID rotation: `failover` to a replica creates a new replication ID, forcing a full sync on any other reconnecting replica. Plan promotion windows accordingly.

## Atomicity, scripting, and messaging

**Pipelining vs transactions**:
- **Pipelining**: client sends N commands without waiting; server processes in order, replies stream back. Saves RTTs. **Not atomic** — other clients' commands can interleave.
- **`MULTI` / `EXEC` / `DISCARD`**: server queues commands after `MULTI`, executes batch atomically on `EXEC`. No interleaving. **No rollback** — each command's error reported but the rest still run, except queue-time syntax errors which abort the whole transaction.
- **`WATCH key [key ...]`** before `MULTI` — optimistic locking / CAS. If any watched key is modified before `EXEC`, `EXEC` returns nil and nothing runs. Retry loop is the caller's job. Best for low contention.
- **Pipeline + MULTI together** is idiomatic: client batches `MULTI`/queued/`EXEC` into one TCP write.

**Lua and Functions**:
- `EVAL script numkeys key1 ... arg1 ...` — atomic server-side execution. `KEYS`/`ARGV` separation is mandatory; in cluster mode all `KEYS` must hash to same slot.
- `EVALSHA <sha> ...` after `SCRIPT LOAD` — caches script by SHA1. Fall back to `EVAL` on `NOSCRIPT` (cache flushed on restart / `SCRIPT FLUSH`).
- Functions (Redis 7+, `FUNCTION LOAD`) — persistent server-side library, replicated and persisted. Replaces ad-hoc Lua-per-deploy; preferred for shared logic.

**Streams** (durable log + consumer groups):
- `XADD stream '*' field value ...` — `*` autogenerates `<ms-timestamp>-<seq>`; explicit IDs must be monotonically increasing.
- Capped: `XADD stream MAXLEN ~ 100000 ...` — `~` approximate trim (efficient), `=` exact (expensive). `MINID` trims by ID.
- `XGROUP CREATE stream g $ MKSTREAM` (`$` = current end; `0` = beginning).
- `XREADGROUP GROUP g consumer1 COUNT 10 BLOCK 5000 STREAMS stream >` — `>` = new messages only. Use `0` to re-read this consumer's pending list (PEL recovery on restart).
- **PEL** (Pending Entries List): every read via `XREADGROUP` enters PEL; remains until `XACK`.
- `XPENDING stream g` summary; `XPENDING stream g IDLE <ms> - + count [consumer]` detail.
- `XCLAIM stream g new-consumer min-idle-ms <id> ...` — reassign stuck messages.
- `XAUTOCLAIM stream g new-consumer min-idle-ms <start-id> [COUNT n]` (Redis 6.2+) — automated PEL handover. Prefer over manual `XCLAIM` loops.
- **At-least-once**, never exactly-once: crash between work and `XACK` causes redelivery. Track `times_delivered` via `XPENDING`; route to DLQ stream above N.

**Pub/Sub**:
- `SUBSCRIBE`/`PUBLISH`/`PSUBSCRIBE` — fire-and-forget, no persistence, no consumer groups. Subscribers connected at publish time get the message; everyone else loses it. For durable fan-out use Streams. In cluster, use sharded `SPUBLISH`/`SSUBSCRIBE`.

## Security and runtime control

**ACL** (Redis 6+):
- Default: single `default` user with `on nopass ~* &* +@all` — full access. Set `requirepass` **or** edit `default` ACL to lock down.
- `ACL SETUSER alice on >mypass ~app:* &events:* +@read +get +set -@dangerous`
  - `on`/`off` — enable; `>pw` add password, `<pw` remove, `nopass`, `resetpass`.
  - `~pattern` — key glob; multiple allowed; `~*` = all; `resetkeys` clears.
  - `&pattern` (Redis 6.2+) — Pub/Sub channel glob; `allchannels` / `resetchannels`.
  - `+cmd` / `-cmd` / `+@category` / `-@category`.
- Categories: `@all`, `@admin`, `@dangerous` (FLUSHALL/KEYS/CONFIG/...), `@write`, `@read`, `@keyspace`, `@connection`, `@scripting`, `@stream`, `@pubsub`, `@slow`, `@fast`, plus per-data-type (`@string`, `@hash`, `@list`, `@set`, `@sortedset`, `@geo`, `@bitmap`, `@hyperloglog`).
- Inspect: `ACL WHOAMI`, `ACL LIST`, `ACL GETUSER alice`, `ACL CAT [category]`, `ACL LOG` (recent auth/permission failures).
- Persist: `user ...` lines in `redis.conf` OR external `aclfile /path/users.acl` — not both. `ACL SAVE` writes to aclfile (only when `aclfile` is set).
- Cluster: ACLs are NOT auto-replicated. Distribute via config management.

**TLS** (Redis 6+): `tls-port 6380`, `tls-cert-file`, `tls-key-file`, `tls-ca-cert-file`. `tls-auth-clients yes` for mTLS. Compile with `make BUILD_TLS=yes` (not default in stock builds before 7).

**CLIENT control**:
- `CLIENT LIST [TYPE normal|master|replica|pubsub] [ID ...]`.
- `CLIENT KILL ID <id>` / `ADDR ip:port` / `LADDR ip:port` / `TYPE x` / `USER alice`.
- `CLIENT NO-EVICT ON` (Redis 7+) — protect this connection from `maxmemory-clients` eviction.
- `CLIENT TRACKING ON` (RESP3) — server-assisted client-side caching with invalidations.

**CONFIG**:
- `CONFIG GET <pattern>` / `CONFIG SET <param> <value>` — runtime change. Not all params are settable at runtime; some require restart.
- `CONFIG REWRITE` — persists in-memory config back to `redis.conf`, preserving comments where possible. Without it, runtime changes vanish on restart.
- `CONFIG RESETSTAT` — zeros the `INFO stats` counters.

## Variants: Redis 7+, Valkey, KeyDB, Dragonfly

- **Redis 7.4+** licensing (March 2024): dual SSPLv1 / RSALv2 — not OSI-open-source. Source-available with restrictions on managed-service competitors. Redis 8.0 (May 2025) added back AGPLv3 as a third option, but Linux Foundation still backs the fork.
- **Valkey** (valkey.io): community fork of Redis 7.2.4 under BSD-3-Clause, governed by the Linux Foundation. Drop-in wire-compatible. AWS ElastiCache, GCP Memorystore, Oracle Cloud, Azure are shipping it. **Default migration path** for OSS-only shops.
- **KeyDB** (Snap/EQ Alpha): multi-threaded fork (pre-Valkey). Multiple worker threads share the dataset with per-key locking. Performance up to ~3× single-threaded Redis on the same box. **FLASH** tiered storage (hot RAM / cold NVMe). Diverging from upstream; use with eyes open.
- **Dragonfly** (dragonflydb.io): clean-room reimplementation in C++ with shared-nothing multi-threading via `io_uring`. Single node replaces a small Redis cluster. Wire-compatible with most commands. **Caveats**: Lua support limited or absent in some versions, AOF semantics differ, no exact `SLOWLOG`/`LATENCY` parity. Vet feature coverage before adopting.
- **Choosing**: drop-in OSS replacement → Valkey. Single-node multicore throughput ceiling → Dragonfly. Tiered storage with Redis API → KeyDB. Stay on Redis only if you need Redis Stack (Search, JSON, TimeSeries, Bloom) modules and accept the license terms.

## Authoritative references

**Official Redis docs** (`redis.io/docs/latest`):
- [Persistence (RDB / AOF / hybrid)](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)
- [Key eviction policies](https://redis.io/docs/latest/develop/reference/eviction/)
- [SLOWLOG command](https://redis.io/docs/latest/commands/slowlog/)
- [Latency monitoring](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/latency-monitor/)
- [Redis cluster specification](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/)
- [Cluster tutorial](https://redis.io/docs/latest/operate/oss_and_stack/management/scaling/)
- [High availability with Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/)
- [Replication](https://redis.io/docs/latest/operate/oss_and_stack/management/replication/)
- [Streams introduction](https://redis.io/docs/latest/develop/data-types/streams/)
- [Transactions (MULTI/EXEC/WATCH)](https://redis.io/docs/latest/develop/interact/transactions/)
- [ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/)
- [HOTKEYS](https://redis.io/docs/latest/commands/hotkeys/) / [XCLAIM](https://redis.io/docs/latest/commands/xclaim/)

**Source / changelog**:
- [github.com/redis/redis](https://github.com/redis/redis) — `redis.conf` defaults, CHANGELOG.md, `src/replication.c`

**Community deep-dives**:
- antirez (Salvatore Sanfilippo) — original Redis design notes, e.g. [Streams Consumer Group Patterns](https://redis.antirez.com/fundamental/streams-consumer-patterns.html)
- Arpit Bhayani — replication backlog circular-buffer internals

**Variants**:
- [valkey.io](https://valkey.io/) — Valkey project, Linux Foundation
- [dragonflydb.io](https://www.dragonflydb.io/) — Dragonfly architecture
- [docs.keydb.dev](https://docs.keydb.dev/) — KeyDB multi-threading and FLASH

## Guardrails

Before recommending a non-trivial operational change (eviction policy, fsync, backlog size, cluster reshard, ACL, defrag):
1. Quote the specific parameter name and its **default** value.
2. Cite the official Redis doc section (or variant doc if Valkey/KeyDB/Dragonfly).
3. Make the recommendation conditional on observed metrics (`INFO`, `LATENCY`, `SLOWLOG`, `evicted_keys`, `mem_fragmentation_ratio`) — never blanket-tune.
4. For variant migrations, name the **specific feature** that justifies leaving Redis (license, multi-threading, tiered storage, modules) — don't switch on benchmarks alone.

**Tuning without measurement is worse than defaults.**

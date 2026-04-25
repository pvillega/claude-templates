---
name: sqlite-wal
description: >
  Deep SQLite operational intuition — WAL mode mechanics, checkpointing, locking,
  fsync/durability semantics, multi-process gotchas, FTS5/JSON1 internals,
  pragma tuning, and replication patterns (Litestream/LiteFS/rqlite).
  Load ONLY when the task is about WAL behavior, checkpoint tuning, SQLITE_BUSY
  diagnosis, multi-writer/multi-process concurrency, network-FS corruption risk,
  pragma-level performance tuning, FTS5 index design, or backup/replication
  strategy. Do NOT load for ordinary SQL writing, schema-first design, or basic
  indexing — those don't need this skill.
  Triggers on: "WAL mode", "wal_checkpoint", "checkpoint starvation", "-wal file growing",
  "SQLITE_BUSY", "SQLITE_BUSY_SNAPSHOT", "busy_timeout", "BEGIN IMMEDIATE",
  "synchronous=NORMAL", "PRAGMA tuning", "sqlite mmap", "sqlite over NFS",
  "sqlite corruption", "FTS5 tokenizer", "Litestream", "LiteFS", "VACUUM INTO",
  "STRICT tables", "WITHOUT ROWID", "single writer".
---

# SQLite Operational Guide

Concise operational pointers for deep SQLite tuning, WAL diagnosis, and multi-process correctness.

Assumes you already know SQL and basic SQLite usage (`.dump`, `.schema`, `EXPLAIN QUERY PLAN`). This skill covers the **operational layer** — WAL internals, fsync semantics, lock states, pragma defaults, FTS5/JSON1 quirks, network-FS hazards.

## When to use

Load when the question is about:
- WAL mechanics, checkpointing, `-wal`/`-shm` file behavior
- `SQLITE_BUSY` / `SQLITE_BUSY_SNAPSHOT` diagnosis, busy_timeout tuning
- Multi-process or multi-host SQLite (and why most attempts corrupt)
- Pragma-level perf tuning (`synchronous`, `cache_size`, `mmap_size`, `temp_store`)
- FTS5 index design (tokenizers, contentless tables, vocab tables)
- JSON1 indexing via generated columns; JSONB choice (3.45+)
- Backup correctness (`VACUUM INTO`, backup API, sqlite3_rsync)
- Replication patterns: Litestream / LiteFS / rqlite tradeoffs

**Do NOT load** for: ordinary SELECT/INSERT writing, schema-first design, "what index should I add", basic CREATE TABLE syntax — those don't need this skill.

## WAL mechanics

- **Enable**: `PRAGMA journal_mode=WAL` returns `wal` on success. **Persists across connections** in the file header — unlike every other journal mode. To revert: `PRAGMA journal_mode=DELETE` (default).
- **Three files**: `name.db`, `name.db-wal` (append-only log of new page versions), `name.db-shm` (mmap'd wal-index, ephemeral). All three are required while connections are open. Lost `-shm` is recoverable on next open.
- **Concurrency model**: many readers + **one writer concurrent**. Writers append to WAL; readers see a snapshot at txn start (their "end mark") and consult WAL pages newer than the main DB but ≤ their end mark. Rollback journal mode serializes everything; WAL does not.
- **Checkpoint** = fold WAL pages back into main DB. Not the same as commit. Commit just appends a frame to `-wal`.
- **`-shm` is mmap-only** — never required to be on disk. If the FS doesn't support shared mmap (most network FS), WAL fails. Workaround: `PRAGMA locking_mode=EXCLUSIVE` before first WAL access — `-shm` is then never created, but the connection holds the file exclusively.
- **Format version bump**: opening a WAL DB with an SQLite older than 3.7.0 fails — WAL bumps the file-format version from 1 to 2.

## Checkpointing

- **Auto-checkpoint default**: `PRAGMA wal_autocheckpoint=1000` (pages, ~4 MB at the default 4096-byte page size). Triggered at end of any commit that grows WAL ≥ N pages. Setting `0` disables.
- **Manual modes**: `PRAGMA wal_checkpoint(MODE)`:
  - `PASSIVE` (default): does whatever it can without blocking; **may not finish** if readers/writers are active.
  - `FULL`: waits for writers, then checkpoints all committed frames; may block briefly.
  - `RESTART`: like FULL, then waits for readers past the checkpoint to finish; next writer starts at WAL offset 0 (file size unchanged).
  - `TRUNCATE`: like RESTART, then truncates `-wal` to zero bytes.
- **Checkpoint starvation**: a long-running read txn pins its end mark, blocking the checkpointer from advancing past unread frames. `-wal` grows unbounded. Symptom: `-wal` >> `.db`. Fix: kill the long reader; use `PRAGMA journal_size_limit=N` (default `-1` = no limit) to bound the file *post*-checkpoint (does not prevent growth between checkpoints).
- **Litestream/LiteFS pattern**: app sets `PRAGMA wal_autocheckpoint=0` and lets the replicator drive checkpoints, so frames aren't dropped before being shipped.
- **WAL-reset bug** (3.7.0–3.51.2): two concurrent connections checkpointing/writing could corrupt. Fixed in 3.51.3 / backported 3.50.7, 3.44.6. Verify version on production.

## Synchronous and durability

- **Defaults**: `PRAGMA synchronous=FULL` (2) for rollback journal. WAL mode's effective default depends on the binary; **always set explicitly**.
- **Recommended for WAL**: `PRAGMA synchronous=NORMAL` (1). fsync's `-wal` only at checkpoint boundaries (not every commit). Power-loss safe **because WAL is append-only and torn appended frames are detected and discarded on recovery**. Throughput: typically 2–10× over `FULL`.
- **`FULL` (2)** under WAL: fsync after every commit and at checkpoint. Worst-case durability, lowest throughput. Use only if you cannot tolerate losing the last few committed transactions on power loss.
- **`OFF` (0)**: no fsync ever. **Unsafe under power loss** — both rollback and WAL modes can corrupt. Acceptable only for ephemeral/derived data.
- **macOS specific**: stock `fsync()` does NOT flush the disk write cache. Set `PRAGMA fullfsync=1` (default `OFF`, macOS-only) to use `F_FULLFSYNC`. Cost: large; benefit: actual durability on consumer SSDs.
- **Linux ext4**: default fsync is sufficient when the FS is mounted with `barrier=1` (default since ~2010). USB sticks and consumer SD cards routinely lie about sync — corruption on power loss is the storage's fault, not SQLite's.
- **Crash recovery**: hot WAL is detected on next open; uncommitted frames are discarded. **Do NOT delete `-wal` or `-shm` after a crash** — it destroys committed-but-not-checkpointed transactions. Safe deletion requires a clean shutdown (last connection closes, checkpoint runs).

## Locking and concurrency

- **Rollback-journal lock states** (`UNLOCKED → SHARED → RESERVED → PENDING → EXCLUSIVE`): WAL skips most of these. WAL writers acquire a write lock on a byte range in `-shm`; readers acquire a per-reader byte-range lock recording their end mark. Many readers + one writer truly concurrent.
- **`SQLITE_BUSY` (5)**: another connection holds an incompatible lock right now. Resolved by waiting/retrying.
- **`SQLITE_BUSY_SNAPSHOT` (517)**: WAL-specific. A read txn began with end-mark E; another connection wrote and committed beyond E; this connection now tries to upgrade its read txn to a write txn. Cannot proceed without restarting the txn — `busy_timeout` does **not** retry this. Fix: re-issue `BEGIN IMMEDIATE` and replay.
- **`PRAGMA busy_timeout=N`** (ms). Default `0` (return BUSY instantly). Production minimum: `5000`. Implementation: short polling sleeps internally, retries on `SQLITE_BUSY` only — not on `BUSY_SNAPSHOT`.
- **`BEGIN` modes**:
  - `BEGIN` / `BEGIN DEFERRED` (default): acquires no lock until first statement. Read becomes write on first DML — that upgrade is where `BUSY_SNAPSHOT` happens.
  - `BEGIN IMMEDIATE`: acquires the write lock at BEGIN. If another writer is active, fails with `BUSY` *now* (recoverable via busy_timeout). **Use this for any txn that will write.**
  - `BEGIN EXCLUSIVE`: in WAL mode, identical to IMMEDIATE. In rollback mode, blocks readers too.
- **Single-writer rule**: SQLite serializes writes per database file. Multi-process writers ⇒ funnel writes through a single process or accept BUSY/SNAPSHOT retry storms. Keep write txns short (sub-second).
- **Threading**: `SQLITE_THREADSAFE` defaults to `1` (serialized) when compiled without flags. Mode `2` (multi-thread) is safe across threads **only if each connection/prepared statement is touched by one thread at a time**. Prepared statements are NOT thread-safe regardless of mode.

## Network filesystems = corruption

- **NFS, SMB, FUSE, sshfs, GCS Fuse, S3FS, EFS**: do not host an active SQLite DB on these. POSIX advisory locking is buggy or unimplemented; `-shm` mmap does not synchronize across hosts; `fsync()` semantics are unreliable. Multi-host writes corrupt within minutes.
- **Single-host on NFS**: marginally safer with `PRAGMA locking_mode=EXCLUSIVE` (avoids `-shm`), but `fsync` reliability is still the FS's problem. Treat as best-effort, never authoritative.
- **Hard/symlinks**: opening the same DB through two distinct names yields two distinct `-wal`/`-shm` pairs ⇒ corruption.
- **Backup-while-open**: `cp` / `rsync` of an open DB captures inconsistent state. Always use `VACUUM INTO`, the backup API, or `sqlite3_rsync` (3.47+).

## Pragma tuning

- **`cache_size`**: default `-2000` (negative = KiB ⇒ ~2 MB). Positive = pages. Production: `-200000` (~200 MB) is reasonable for read-heavy workloads. Per-connection.
- **`mmap_size`**: default `0` (off). Bytes of DB file the OS will mmap into the process for reads. Reduces syscalls; bounded per connection. Set to e.g. `268435456` (256 MB) on systems with the address space. Caveat: a stray pointer write into mmap'd region corrupts the DB.
- **`temp_store`**: default `0` (compile-time `SQLITE_TEMP_STORE`). Set `2` (MEMORY) to keep temp tables / indexes / sort scratch in RAM — large win for complex queries.
- **`page_size`**: default `4096` (since 3.12.0, 2016). Must be set **before the first write** to the DB; changing later requires `VACUUM` to rewrite. Powers of two 512–65536. 4096 is correct for nearly all workloads; 8192 occasionally helps for blob-heavy DBs.
- **`foreign_keys`**: default `OFF` (per-connection!) since 3.6.19. Re-enable on every new connection: `PRAGMA foreign_keys=ON`.
- **`recursive_triggers`**: default `OFF`. Triggers fire per-row; without this pragma, a trigger that modifies the same table will not re-fire.
- **Production opening sequence** (after every `sqlite3_open`):
  ```sql
  PRAGMA journal_mode=WAL;
  PRAGMA synchronous=NORMAL;
  PRAGMA busy_timeout=5000;
  PRAGMA cache_size=-200000;
  PRAGMA temp_store=MEMORY;
  PRAGMA foreign_keys=ON;
  PRAGMA mmap_size=268435456;  -- if address space allows
  ```

## FTS5 quirks

- **Content modes**:
  - Default: full row stored in FTS5 shadow tables. Largest, simplest.
  - `content=t1, content_rowid=a`: external content. Index only; query joins back to source. Requires triggers (`AFTER INSERT/UPDATE/DELETE`) to keep in sync — easy to drift.
  - `content=''`: contentless. Smallest. No `UPDATE`/`DELETE` (use `INSERT INTO ft(ft, rowid) VALUES('delete', N)`). 3.43+ adds `contentless_delete=1` for true DELETE/INSERT-OR-REPLACE.
- **Tokenizers**:
  - `unicode61` (default): case-insensitive, strips diacritics by default (`remove_diacritics=1`). Set `0` to preserve.
  - `trigram`: required for substring (`%foo%`) / `LIKE` / `GLOB` acceleration. 3-grams as tokens.
  - `porter`: English stemming wrapper (`tokenize='porter unicode61'`).
  - `ascii`: ASCII-only fast path; non-ASCII becomes token chars.
- **MATCH syntax**: `thr*` (prefix), `^one` (initial token), `col : "phrase"` (column filter), `NEAR(a b, 5)` (within N tokens, default 10), `-` (NOT). Implicit AND beats OR.
- **`detail` knob** (size vs query power):
  - `full` (default): rowid + col + offset. Supports NEAR, phrase, snippets.
  - `column`: rowid + col. ~50% smaller; no NEAR/phrase.
  - `none`: rowid only. ~80% smaller; no NEAR/phrase/column filter.
- **Maintenance**: `INSERT INTO ft(ft) VALUES('optimize')` merges all segments — slow; one-shot. `INSERT INTO ft(ft, rank) VALUES('merge', N)` does incremental work. `automerge` defaults to `4`, `crisismerge` to `16`.
- **`fts5vocab`**: virtual table exposing `term/col/doc/cnt`. Useful for token-distribution analysis and detecting tokenizer mismatches.

## JSON and JSONB

- **JSON1 is built-in** since 3.38 (2022-02-22) — no extension load needed. Pre-3.38 builds need `-DSQLITE_ENABLE_JSON1`.
- **`->` and `->>` operators** since 3.38: `data->'$.user'` returns JSON text; `data->>'$.user.name'` returns SQL native (TEXT/INTEGER/REAL/NULL). Use `->>` for `WHERE` clauses; `->` for nested extraction.
- **Indexed JSON queries** require generated columns:
  ```sql
  ALTER TABLE events ADD COLUMN user_id TEXT
    GENERATED ALWAYS AS (data->>'$.user.id') VIRTUAL;
  CREATE INDEX events_user ON events(user_id);
  ```
  `VIRTUAL` (default) computes on read; `STORED` materializes on write. Index is identical either way; choose based on read/write ratio.
- **JSONB** (3.45+, 2024-01-15): binary on-disk format. `jsonb_*` functions return BLOB; storing JSONB columns avoids re-parsing on every read. Migration: rewrite columns with `UPDATE t SET data = jsonb(data)`. Mixing text-JSON and JSONB columns is fine — accessor functions accept either.

## Backups and replication

- **`VACUUM INTO 'file.db'`**: atomic, online, transaction-consistent. Reads with shared lock; writes a fresh DB file with no `-wal` artifacts. Recommended default for app-level backups.
- **Backup API** (`sqlite3_backup_init/step/finish`): copies pages with concurrent writes allowed; restarts pages that change mid-copy. Library-level only.
- **`sqlite3_rsync`** (3.47+): rsync-style delta copy of an open DB. Designed for low-bandwidth replication.
- **Plain file copy is safe ONLY when**: `journal_mode=DELETE` *and* no connection is open. With WAL, copying just `.db` produces a stale snapshot — must copy `.db` + `.db-wal` + `.db-shm` atomically, which a plain `cp` cannot guarantee.
- **Litestream**: tails the WAL by reading `-wal` frames; ships them to S3/blob storage. Requires `wal_autocheckpoint=0` so app-driven checkpoints don't truncate frames before shipment.
- **LiteFS**: FUSE FS that intercepts SQLite writes at the page level; multi-node primary-replica with per-DB leadership. Constraint: one writer per DB, replicas read-only.
- **rqlite / dqlite**: SQLite *behind* Raft. Each write is a Raft log entry; SQL is replayed on every node. Different correctness model — multi-master at the cost of write latency.

## Common pitfalls

- **`INTEGER PRIMARY KEY` IS the rowid** — alias for the hidden 64-bit rowid. `INT PRIMARY KEY` is NOT (subtle: `INT` ≠ `INTEGER` in this one place). Inserting NULL auto-generates.
- **Type affinity is hint-level** in default tables — `CREATE TABLE t(n INTEGER); INSERT INTO t VALUES('hello')` succeeds. Use **STRICT tables** (3.37+, 2021-11-27) to enforce: `CREATE TABLE t(n INTEGER) STRICT` — only `INT/INTEGER/REAL/TEXT/BLOB/ANY` allowed; mismatches raise `SQLITE_CONSTRAINT_DATATYPE`.
- **`WITHOUT ROWID`**: requires explicit PRIMARY KEY (NOT NULL enforced). Single B-tree (no rowid index). Best for non-integer PKs and small rows (< 1/20 of page size, ~200 B at 4 KB pages). `INTEGER PRIMARY KEY` stops being a rowid alias here. No `AUTOINCREMENT`.
- **`ATTACH DATABASE`**: cross-DB queries work, but only the **main** DB's WAL handles atomicity. Multi-DB writes are NOT atomic across files in WAL mode — use rollback journal if cross-file atomicity is required.
- **`PRAGMA foreign_keys` is per-connection**: your migration tool may have it ON, your app OFF, your repl shell different again. Pin it on every open.
- **Triggers**: per-row, fire after each affected row's modification. `recursive_triggers=OFF` by default ⇒ a trigger that re-modifies the same table won't cascade. Surprising for ORM-style soft-delete patterns.
- **Single-writer constraint**: queue all writes through a dedicated process or a per-DB mutex in your app. Long write txns (> ~100 ms) starve readers via SNAPSHOT, even though "readers don't block writers." Break large writes into chunks.

## Authoritative references

**Official SQLite docs** (`sqlite.org`):
- [WAL mode](https://www.sqlite.org/wal.html)
- [PRAGMA reference](https://www.sqlite.org/pragma.html)
- [File locking](https://www.sqlite.org/lockingv3.html)
- [Transactions / BEGIN modes](https://www.sqlite.org/lang_transaction.html)
- [How To Corrupt An SQLite Database File](https://www.sqlite.org/howtocorrupt.html)
- [Threading modes](https://www.sqlite.org/threadsafe.html)
- [FTS5](https://www.sqlite.org/fts5.html)
- [JSON1 / JSONB](https://www.sqlite.org/json1.html)
- [STRICT tables](https://www.sqlite.org/stricttables.html)
- [WITHOUT ROWID](https://www.sqlite.org/withoutrowid.html)

**Replication and operator deep-dives**:
- [Litestream tips](https://litestream.io/tips/) — WAL settings, busy_timeout, autocheckpoint disable
- [Fly.io: SQLite Internals: WAL](https://fly.io/blog/sqlite-internals-wal/) — Ben Johnson on checkpoint dynamics
- LiteFS docs (`fly.io/docs/litefs/`) — FUSE-level page replication
- rqlite / dqlite project docs — Raft-over-SQLite tradeoffs

## Guardrails

Before recommending a non-trivial pragma change or replication topology:
1. Quote the **exact** pragma name and its **default value** (per `pragma.html`).
2. Cite the official SQLite doc section.
3. Make the recommendation conditional on observed metrics — `-wal` size, `SQLITE_BUSY` count, txn duration.
4. **Verify SQLite version** (`SELECT sqlite_version()`). Many features (JSONB 3.45, STRICT 3.37, contentless_delete 3.43, sqlite3_rsync 3.47, WAL-reset fix 3.51.3) are version-gated.

**Tuning without measurement, or porting a Postgres mental model wholesale to SQLite, is worse than defaults.**

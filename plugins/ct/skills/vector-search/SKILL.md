---
name: vector-search
description: >
  Deep vector / ANN search operational intuition — HNSW (M, efConstruction, efSearch)
  and IVF (nlist, nprobe) tuning math, PQ/SQ/BQ quantization tradeoffs and ADC, distance-
  metric correctness (the cosine-via-IP normalization trap), pgvector specifics
  (halfvec, iterative_scan, maintenance_work_mem), filter-aware ANN (pre/post-filter,
  ACORN, Qdrant payload links), hybrid retrieval (BM25 + dense + RRF, SPLADE),
  DiskANN/Vamana for billion-scale, embedding-lifecycle drift handling.
  Load ONLY when the task is about ANN index sizing/tuning, recall-vs-latency tradeoffs,
  vector-DB selection, filter-aware search design, or embedding-version migration. Do
  NOT load for embedding-model fine-tuning, RAG-application design (chunking, retrieval
  evaluation), generic SQL/Postgres tuning, or LLM ranker training — those don't need
  this skill. Pairs with `rag-ops` for the application layer.
  Triggers on: "HNSW", "efSearch", "efConstruction", "IVF", "nlist", "nprobe", "PQ",
  "IVF-PQ", "scalar quantization", "SQ8", "halfvec", "binary quantization", "ADC",
  "recall@k", "ann-benchmarks", "pgvector", "iterative_scan", "hnsw.ef_search",
  "Qdrant", "Weaviate", "Milvus", "Pinecone", "Chroma", "FAISS", "hnswlib", "ScaNN",
  "DiskANN", "Vamana", "ACORN", "filterable HNSW", "RRF", "SPLADE", "BM25",
  "hybrid search", "oversampling", "rescoring", "shadow index", "embedding drift",
  "growing segment", "sealed segment", "IndexFlatIP", "cosine vs IP".
---

# Vector & ANN Search Operational Guide

Concise operational pointers for deep vector-search tuning and incident diagnosis.

Assumes you already know that ANN indexes exist, that embeddings are vectors, and basic vector arithmetic. This skill covers the **operational layer** — the parts models tend to gloss over: HNSW/IVF tuning math, quantization tradeoffs, the cosine-vs-IP normalization trap, pgvector internals, filter-aware search, hybrid retrieval, billion-scale storage, and embedding drift — current as of late 2025/early 2026.

## When to use

Load when the question is about:
- Choosing/tuning HNSW knobs (M, efConstruction, efSearch) for a real corpus
- Sizing IVF indexes (nlist, nprobe) or training-set requirements
- Memory budgeting: PQ (m, nbits), SQ8/SQ4/fp16, binary quantization with rerank
- Diagnosing recall regressions after embedder swap or model upgrade
- Picking pgvector vs Qdrant vs Weaviate vs Milvus vs Pinecone for a workload profile
- Filter-aware ANN: deciding pre-filter vs post-filter vs filterable HNSW (ACORN)
- Hybrid retrieval: BM25/SPLADE + dense, RRF k=60 fusion
- Cosine-via-IP normalization correctness audits
- Streaming/write-heavy patterns and the HNSW deletion footgun
- Disk-resident ANN (DiskANN/Vamana) when corpus exceeds RAM
- Reading ann-benchmarks recall-QPS curves
- pgvector-specific work: HNSW vs IVFFlat, halfvec, iterative_scan, `maintenance_work_mem`
- Embedding lifecycle: A/B with shadow index, dual-write, drift adapters
- Library choice: FAISS vs hnswlib vs Voyager vs ScaNN

**Do NOT load** for: embedding model selection / fine-tuning, LLM RAG prompt design, generic SQL/Postgres tuning, training neural rankers, document chunking. For RAG application-layer work see `rag-ops`.

## HNSW: knobs, math, recall behaviour

HNSW (Malkov & Yashunin) is a multi-layer proximity graph. Three knobs dominate:

- **`M`** — max neighbors per node per layer (typical 8–64; pgvector default 16; hnswlib/FAISS often 16–32). Level multiplier `mL = 1/ln(M)`. Memory ≈ `vector_bytes + M·8 B` per element. d=768 fp32 + M=16 → 768·4 + 16·8 = **3200 B/vec** for the graph alone.
- **`efConstruction`** — build-time candidate queue (typical 100–500; pgvector default 64 — **low**). Higher → better graph quality, slower build, no runtime memory cost.
- **`efSearch`** — query-time candidate queue (50–500; pgvector `hnsw.ef_search` default 40; FAISS default 16). Must satisfy `efSearch ≥ k`.

Recall@k climbs steeply with `efSearch` to a knee, then flattens. `M` mostly affects asymptotic ceiling and memory; bumping `M` past 32 yields diminishing returns on 768-d corpora. For high-recall (≥0.99) regimes, **raise `efSearch` first, then `M`**.

**Deletion footgun**: HNSW does **not** support real deletes. hnswlib offers `markDelete` (soft tombstone, replaceable on insert); FAISS HNSW has no delete at all. Tombstone density >~10–20% degrades recall — production answer is periodic rebuild or Milvus-style segment compaction.

## IVF: nlist, nprobe, quantizer variants

IVF partitions vectors into Voronoi cells via k-means; queries probe `nprobe` nearest cells.

- **`nlist`** heuristic: `~sqrt(N)` for L2/IP at moderate scale; FAISS billion-scale guidance `4·sqrt(N) ≤ nlist ≤ 16·sqrt(N)`. Balances assignment cost (`nlist·d`) against probe cost (`nprobe/nlist · N`).
- **Training set**: FAISS recommends `≥ 30·nlist` and ideally `≥ 256·nlist` to learn centroids well. `Index.train()` is mandatory before `add()`.
- **`nprobe`** 1–256 typical. Recall scales monotonically with `nprobe/nlist`. At `nprobe = nlist` you have brute force.

Variants on cell residuals:
- **IVF-Flat** — full fp32 → highest recall, full memory.
- **IVF-SQ** (SQ8) — 1 B/dim → ~99% relative recall on most workloads.
- **IVF-PQ** — `m` subquantizers × `nbits` → tiny footprint, larger recall hit.
- **IVF-PQ + refine** (FAISS `IndexRefineFlat`) — scan PQ, rerank top-r with full vectors. Standard high-scale pattern.

## Product Quantization: math + ADC

Split d-vector into `m` subvectors of length `d/m` (require `d % m == 0`); each subspace gets a codebook of `ksub = 2^nbits` centroids learned by k-means. Code size = `m·nbits/8` bytes (must be byte-aligned for fast scan; **nbits=8 → ksub=256, byte-aligned, by far the most common**). Example: d=768, m=96, nbits=8 → 96 B/vec, ~40× smaller than fp32.

**ADC** (asymmetric distance computation): query stays fp32; per-query precompute table `T[m][ksub]` of subspace distances to centroids; database distance ≈ `Σ T[i][code_i]`. **SDC** quantizes the query too — cheaper, lower recall. **ADC is the default**.

PQ is the largest single source of error in a typical IVF-PQ. Compensate via **OPQ rotation**, larger `m`, **FastScan SIMD**, or refine pass. Anisotropic workloads — **ScaNN** uses anisotropic vector quantization weighting parallel error more, ~2× QPS at fixed recall vs vanilla PQ.

## Scalar & binary quantization

- **fp16 / halfvec**: 50% memory; recall delta vs fp32 essentially zero on typical embeddings. The default "free win." pgvector ships `halfvec` (since 0.7) with HNSW directly on it.
- **SQ8 (int8)**: 75% memory; ~99% relative recall on most 768-d sentence embeddings.
- **SQ4**: 87.5% memory; useful at billion scale on low-d data, noticeable recall hit.
- **Binary Quantization (BQ)**: 1 bit/dim → 32× smaller, 32× faster Hamming. Standalone BQ recall is poor; **production pattern is BQ for candidate generation + rerank with fp32/fp16**. Qdrant: `oversampling=2-3` recommended default, `rescoring=true` mandatory; OpenSearch & Weaviate ship analogous flows. Aligns with HNSW: build the graph over binary codes, rerank top-`oversampling·k` against full vectors.

## Distance metrics & the cosine/IP footgun

Three primaries: L2, IP (inner product), cosine. **Cosine = IP when both vectors are L2-normalized** — the "must-normalize-for-cosine-via-IP" trick. FAISS `IndexFlatIP` + `faiss.normalize_L2()` is correct cosine; **forgetting the normalize is a silent recall destroyer** because IP rewards large-norm vectors.

Common bug: embedder ships unit-norm (e.g., SBERT) and the index uses L2 — works since L2 on unit vectors equals `2 − 2·cos`. But mix unit-norm queries with un-normalized DB vectors and ranking is wrong. **Audit**: query both with L2 and IP on a normalized sample; outputs must agree on order.

Reported FAISS quirk: HNSW with `METRIC_INNER_PRODUCT` had historical edge cases where graph traversal assumed metric properties that IP violates. Use cosine/L2 for HNSW unless you've validated the version.

## ann-benchmarks interpretation

Curves plot recall@k (x, often log(1−recall)) vs QPS (y, log). **Up-and-right wins.** "100% recall" in ANN means recall@k=1.0 against brute-force ground truth at the same `k` — **not** "found every relevant doc in the corpus." Always quote `k`, `efSearch`/`nprobe`, dataset (sift-1M, glove-100, deep-1B), and hardware. Pareto-dominant on glove-100 may lose on deep-1B; intrinsic dimensionality matters. ScaNN typically wins low-recall regions; HNSW wins high-recall (>0.95) at modest scale; DiskANN wins billion-scale with bounded RAM.

## pgvector

- **Index types**: `hnsw` (preferred), `ivfflat`. **Operators**: `<->` L2, `<#>` negative IP, `<=>` cosine, `<+>` L1, `<~>` Hamming (bit), `<%>` Jaccard.
- **HNSW build defaults**: `m=16`, `ef_construction=64` — `ef_construction` is **low**; bump to 200–400 for production.
- **Query GUC**: `hnsw.ef_search` default 40 — bump to 100–200 for typical recall targets.
- **IVFFlat**: `lists ≈ rows/1000` for <1M, `sqrt(rows)` for >1M; `ivfflat.probes` default 1.
- **`halfvec`** (0.7): same operators, half storage; HNSW indexes directly. `bit` and `sparsevec` (≤1000 nonzeros) for binary/sparse.
- **Iterative scans (0.8)**: `hnsw.iterative_scan ∈ {off (default), strict_order, relaxed_order}`; bounds `hnsw.max_scan_tuples=20000`, `hnsw.scan_mem_multiplier=1`. **Solves the classic "WHERE filter eats results, k under-fills" pre-filter pathology** by re-entering the index until `k` valid rows accumulate.
- **Filter pushdown**: planner picks index scan vs seq scan based on selectivity. Highly selective filter (<~1%) frequently flips to seq scan — feature, not bug, but unexpected when you "have an HNSW index." Tune `enable_seqscan` for diagnosis only.
- **Hybrid**: `tsvector` + `vector` in the same row, fuse client-side via RRF.
- **Build memory**: set `maintenance_work_mem` large enough to hold the entire graph (rule of thumb `M·16 + d·4` bytes per row); spill-to-disk is dramatic.

## Filter-aware search

- **Pre-filter**: scan with predicate first, brute-force or limited ANN over the matching subset. Great recall when filter is selective (<<1%); slow when broad.
- **Post-filter**: ANN, then drop non-matching. **Destroys recall** when filter is selective — top-k may contain zero matches; reduce-then-shrink.
- **Filterable HNSW**: build the graph aware of payload. **Qdrant** payload filtering injects extra intra-category links so deleting a "color=red"-only neighbor set doesn't disconnect the graph. **Weaviate** `acorn` strategy (vs legacy `sweeping`) and **Vespa** ACORN-1: keep unpruned edges, two-hop expansion to skip filtered nodes, randomly seed entry points satisfying the filter. Stabilizes latency and preserves recall under correlated/highly selective predicates. **Pinecone** serverless: bitmap-indexed metadata folder per slab; low-cardinality bitmaps cached, high-cardinality streamed.

## Hybrid search

Dense + lexical. Two fusion strategies:
- **RRF**: per-system rank `r`, score `= 1 / (k + r)`, sum across systems, default `k=60`. Score-free → robust to score-scale mismatches; **the practical default**.
- **Normalized score combination**: min-max or z-score per system, weighted sum. Sensitive to outliers, requires tuning.

Sparse families: classical **BM25** (Lucene, OpenSearch, Vespa); **learned sparse** SPLADE / SPLADE-v2 / SPLADE-v3 / SPLADE++ / Mistral-SPLADE — transformer-produced sparse term vectors with expansion. Stored as inverted index in Elastic/OpenSearch/Vespa or as `sparsevec` in pgvector. SPLADE-v3 (2024) approaches cross-encoder rerank quality.

## Disk-based ANN

- **DiskANN / Vamana** (Microsoft): graph on SSD, in-RAM PQ codes for routing. Build: `R` (max degree, ~64–128), `L` (search list, 75–400, `L ≥ R`), `alpha` (1.0–1.5; 1.2 typical). Paper recommends two passes: alpha=1.0 then alpha=1.2. Hits billion-scale on a single node; also in Milvus DISKANN, NVIDIA cuVS.
- **FAISS IVFADC / IVF-PQ on disk**: cells served from mmap; high-`nlist` keeps per-cell read small.

## Streaming / write-heavy

- **Milvus segment model**: writes land in **growing** in-memory segment (no index). Flush threshold seals → **sealed** segment, async builds HNSW/IVF, persists to S3/MinIO. Deletes are tombstone-marked; **compaction** auto-rebuilds when tombstones >20% of a segment. Search merges across growing+sealed.
- HNSW elsewhere: rebuild-on-deletion-bloat or use Qdrant's mutable segments + optimization.

## Embedding lifecycle & drift

Mixing v1 and v2 vectors in one index is a top-3 production bug — same query lands in different neighborhoods per doc. Mitigations:

1. **Full reindex with alias swap** (Pinecone/Weaviate/Qdrant aliases): build v2 cold, switch alias atomically.
2. **Dual-write + dual-read shadow indexing**: write to both v1, v2; read both, fuse via RRF; cut over when v2 metrics dominate.
3. **Lazy re-embed**: parallel v2 index for new docs; route by `model_tag` filter; backfill old docs as budget allows.
4. **Drift-Adapter (2025)**: lightweight learnable map projecting v2 queries into v1 space; recovers 95–99% of full-reindex recall at <10 µs query overhead, ~100× cheaper than reindex. Useful as bridge during migration.

API providers (OpenAI etc.) sometimes silently retrain endpoints — pin model versions where possible and monitor query embedding norm/centroid drift over time.

## Library tradeoffs

- **FAISS**: gold standard for batch + research; CPU/GPU; full IVF/PQ/HNSW; HNSW lacks deletes.
- **hnswlib**: minimal C++ HNSW with `markDelete`; fastest single-machine HNSW; no quantization.
- **Voyager** (Spotify): hnswlib successor; E4M3 fp8 storage; fault-tolerant index files; multithreaded build/query; Python+Java.
- **ScaNN** (Google): anisotropic VQ + tree pruning; ~2× QPS at fixed recall vs HNSW on some sets; weaker dynamic-update story.
- **Chroma**: dev-friendly, sqlite-backed; HNSW under the hood.
- **Qdrant / Weaviate / Milvus / Pinecone**: full DBs — payload filtering, replication, segments, multi-tenancy.

## Recent changes worth tracking

- **pgvector 0.7** (2024): `halfvec`, `sparsevec`, `bit` improvements.
- **pgvector 0.8** (Oct 2024+): **`iterative_scan`** (strict/relaxed) — first-class fix for filter-induced under-fill; planner improvements.
- **Filterable HNSW maturation**: Qdrant payload links, Weaviate `acorn` (default in newer versions), Vespa ACORN-1 + Adaptive Beam Search.
- **Binary quantization mainstream**: Qdrant/Weaviate/OpenSearch all ship BQ + rerank; oversampling 2–3 standard.
- **SPLADE-v3** (2024) and Mistral-SPLADE pushing learned sparse close to cross-encoder rerank.
- **Pinecone serverless gen-2** (2025): slab + bitmap metadata, auto-tuned, no manual knobs.
- **Drift-Adapter** (EMNLP 2025) as near-zero-downtime alternative to full reindex.

## Authoritative references

- [pgvector repo](https://github.com/pgvector/pgvector), [pgvector 0.8 release](https://www.postgresql.org/about/news/pgvector-080-released-2952/)
- [FAISS wiki indexes](https://github.com/facebookresearch/faiss/wiki/Faiss-indexes)
- [Qdrant quantization](https://qdrant.tech/documentation/manage-data/quantization/)
- [Weaviate ACORN](https://weaviate.io/blog/speed-up-filtered-vector-search)
- [Vespa ACORN-1](https://blog.vespa.ai/additions-to-hnsw/)
- [Milvus DiskANN](https://milvus.io/docs/diskann.md)
- [ann-benchmarks](https://ann-benchmarks.com/)
- [Drift-Adapter (2025)](https://arxiv.org/abs/2509.23471)
- [SPLADE](https://github.com/naver/splade)
- [Pinecone slab architecture](https://www.pinecone.io/learn/slab-architecture/)

## Guardrails

Before recommending a non-trivial vector-index change (HNSW knob bump, quantization swap, filter strategy, reindex):
1. Quote the parameter and its default in the index/DB version in use
2. Cite the relevant docs / paper for the claim
3. Make the recommendation conditional on observed evidence (recall@k measurement, latency P99, build memory, filter selectivity) — never blanket-tune
4. Verify the engine version. Many features gate on releases (pgvector 0.8 iterative_scan, Qdrant payload links, Weaviate ACORN default)

**Tuning without measurement is worse than defaults.**

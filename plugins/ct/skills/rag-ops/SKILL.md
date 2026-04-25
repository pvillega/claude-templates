---
name: rag-ops
description: >
  Deep RAG application-layer operational intuition — chunking strategies (fixed,
  recursive, semantic, late chunking, Anthropic contextual retrieval), 2026 embedding-
  model landscape, reranker economics (cross-encoder, ColBERT/ColBERTv2, ColPali),
  hybrid retrieval (BM25 + dense + RRF k=60, SPLADE-v3), query transformations
  (HyDE, multi-query, decomposition), evaluation (RAGAS/TruLens, LLM-judge bias),
  hallucination detection and citation grounding, embedding drift and index freshness,
  long-context-vs-RAG decision, multimodal RAG.
  Load ONLY when the task is about RAG application design / tuning — chunking choices,
  embedding-model selection, reranker integration, eval/golden-set design, hallucination
  audits, embedding-version migration, or long-context-vs-RAG sizing. Do NOT load for
  ANN index/data-structure choice (use vector-search), embedding-model fine-tuning,
  pure prompt engineering without retrieval, or LLM tool/agent orchestration — those
  don't need this skill. Pairs with `vector-search` for the storage layer.
  Triggers on: "chunking strategy", "late chunking", "contextual retrieval",
  "recursive splitter", "token-aware split", "embedding model selection", "MTEB",
  "BGE-M3", "Voyage-3", "Cohere Embed v4", "Matryoshka embeddings", "hybrid retrieval",
  "BM25 + dense", "SPLADE-v3", "RRF", "reranker", "ColBERT", "ColBERTv2", "ColPali",
  "HyDE", "RAG-Fusion", "RAGAS", "TruLens", "faithfulness", "groundedness",
  "Citations API", "embedding drift", "index freshness", "long-context vs RAG",
  "lost in the middle", "context rot", "multimodal RAG", "Self-RAG", "CRAG".
---

# RAG Operational Guide

Concise operational pointers for deep RAG application-layer tuning and incident diagnosis.

Assumes you already know what RAG is, basic embedding usage, and that you have a vector store. This skill covers the **operational layer** — the parts models tend to gloss over: chunking economics, the 2026 embedding-model landscape, reranker tradeoffs, hybrid fusion math, evaluation methodology and judge bias, hallucination/grounding, drift handling, long-context-vs-RAG decisions — current as of late 2025/early 2026.

## When to use

Load when the question is about:
- Choosing chunk size / splitter (fixed / recursive / semantic / token-aware / late) for a known embed model
- Tuning chunking against `embed_model.max_seq_length` (e.g., 512 vs 8192)
- Contextual retrieval (Anthropic chunk augmentation) vs late chunking (Jina) vs vanilla
- Picking 2026 embedding model from MTEB top set under cost/latency/dim constraints
- Matryoshka truncation (e.g., 3072 → 256 dim) for ANN cost reduction
- Hybrid (dense + BM25 / SPLADE) with RRF and avoiding score-normalization mistakes
- Adding a reranker stage (Cohere v3.5, BGE v2-m3, Jina v3) and budgeting 100–600 ms
- HyDE / multi-query / decomposition vs single-shot when latency-sensitive
- Building a RAGAS / TruLens eval harness with golden set, NDCG@k / MRR / Recall@k
- Hallucination detection via faithfulness, NLI, citation grounding, Anthropic Citations API
- Re-embed planning when changing model or pipeline; hot/cold index split
- Long-context (Claude / Gemini 1M) vs RAG; mitigating "lost in the middle" / "context rot"
- Multimodal / visual document retrieval with ColPali, ColQwen2, ColSmol

**Do NOT load** for: ANN index data-structure choice (use `vector-search`), vector-DB shard layout, LLM generation/prompt engineering not bound to retrieved context, agent / tool-use orchestration without retrieval semantics, fine-tuning embedding models from scratch.

## Chunking — concrete defaults

- **Fixed-size**: deprecated default; baseline only. Rule of thumb: ~50% of `embed_model.max_seq_length` with 10–20% overlap.
- **Recursive character split** (LangChain `RecursiveCharacterTextSplitter`): hierarchical separators `["\n\n","\n"," ",""]`. Default `chunk_size=512, chunk_overlap=64` is a starting point — re-tune against the model's tokenizer.
- **Token-aware**: count with the model's tokenizer (`tiktoken` for OpenAI, `AutoTokenizer` for HF, `voyageai.Client.count_tokens` for Voyage). 1 token ≠ 1 word for non-Latin; chunking on chars overruns `max_seq_length` for CJK/code.
- **Sentence / semantic** chunking: split on sentence boundaries, then merge until a similarity drop ("breakpoint percentile" ~95) — LlamaIndex `SemanticSplitterNodeParser`. Higher recall on argumentative text, slower index.
- **Late chunking** (Jina, arXiv 2409.04701): embed the entire long doc through the transformer first, then mean-pool over token spans → chunk vectors that retain document context. Average +3.6% relative retrieval over naive sentence-boundary chunking; native in `jina-embeddings-v3` (8192 ctx). No retraining needed.
- **Anthropic Contextual Retrieval**: prepend a 50–100 token Claude-Haiku-generated chunk-context blurb before embedding and BM25 indexing. Prompt-cached cost ≈ $1.02 per 1M document tokens. **Reported failure-rate reductions (top-20)**: 35% with contextual embeddings alone (5.7% → 3.7%), 49% combined with contextual BM25 (→ 2.9%), 67% adding a reranker (→ 1.9%).
- Optimal chunk size is bounded by the model's effective context: BGE-M3 / Jina v3 (8192), E5-Mistral (32k but degrades), text-embedding-3-large (8191). Set chunks ≤ 50% of effective ctx so query + chunk fits at rerank time.

## Embedding models 2026 — selection

**Closed**:
- `voyage-3-large` / `voyage-4` — highest retrieval quality on private benchmarks; MoE in v4 cuts serving cost ~40%; query/doc-asymmetric models share vector space.
- `cohere-embed-v4` — multimodal, multilingual, Matryoshka, 256–1536 dims.
- `text-embedding-3-large` (3072 dim, Matryoshka) — solid cost/quality default; truncated 256-dim still beats `ada-002` 1536.

**Open / self-host**:
- **BGE-M3** — multi-functional: dense + sparse-lexical + ColBERT-style multi-vector, 8192 ctx, MTEB ~63.
- **E5-Mistral-7B-Instruct** — strong but 7B-heavy.
- **nv-embed-v2** — MTEB 72.31 overall, retrieval 62.65.
- **Llama-Embed-Nemotron-8B** — tops multilingual MTEB.
- **nomic-embed-text-v1.5** (Matryoshka, 768 dim).
- **GritLM** — unifies generation + embedding, useful when one model serves both.
- **Jina v3** (570M) — outperforms E5-Mistral-7B on multilingual at ~12× less compute; v4 adds vision.

**Matryoshka**: store full dim, query at any nested dim (256, 512, 1024). Enables tiered search: short-vector ANN candidate gen → full-vector rerank. Renormalize after truncation if cosine.

## Reranking economics

- **Bi-encoder** (your retriever): ~5–20 ms/query, no per-doc inference at query time.
- **Cross-encoder reranker**: scores `[query, doc]` jointly. Latency scales with `top_k_to_rerank × seq_len`. Typical 2-stage: retrieve top 50–100, rerank to top 10.

**2025 benchmark numbers** (illustrative):
- `bge-reranker-v2-m3` ~145 ms p95 / 0.715 nDCG@10 / $0.35 per 1k queries
- `cohere-rerank-3.5` ~210 ms p95 / 0.735 nDCG@10 / $2.40 per 1k
- `jina-reranker-v3` (Qwen3-0.6B base) — 81.33% Hit@1 at ~188 ms, BEIR 61.94 nDCG@10 — 10× smaller than listwise generative rerankers.

**ColBERTv2 / Jina-ColBERT-v2** (late interaction): MaxSim per query token over doc tokens. PLAID-style residual-compression cuts storage 6–10×; Jina-ColBERT-v2 50% lower storage vs v1, 89 langs, 8192 ctx. Sweet spot when you need reranker-quality at retriever-time latency on huge corpora.

## Hybrid retrieval

Standard recipe: dense top-k + BM25 top-k → RRF fuse. **`RRF(d) = Σ 1/(k + rank_i(d))` with `k=60`** (empirically robust per Cormack 2009). RRF is rank-based, so it does **NOT** need score normalization — common pitfall is min-max-normalizing dense cosine and BM25 raw scores then weighted-summing; BM25 is unbounded and dataset-dependent, breaking the average.

**Learned sparse**: SPLADE-v3 (lexical-expansion via MLM head, term weights) bridges dense recall and BM25 lexical precision. **BGE-M3** produces dense + sparse + multi-vector in one forward pass — single-model hybrid.

Typical fused weighting: 0.6 dense / 0.4 sparse. Fuse top 50 from each; rerank top 30 fused → top 10.

## Query transformations

- **HyDE**: LLM generates a hypothetical answer; embed and retrieve against it. Wins on vocabulary mismatch (medical, legal). Adds 1 LLM call (~300–800 ms small model). Hurts on factual lookup where the generated answer fabricates wrong terminology.
- **Multi-query / RAG-Fusion**: generate N rewrites, retrieve each, RRF-fuse. Wins on ambiguous queries; cost is N× retriever calls + 1 LLM call.
- **Decomposition**: break complex query into sub-queries, retrieve per sub, aggregate. Mandatory for multi-hop QA; latency cost compounds.

**Production pattern**: route via a small classifier — short factual → direct; vocabulary-gap → HyDE; multi-hop → decompose. ≤1B router (or logistic regression on query features) keeps overhead < 50 ms.

## Evaluation

- **Retrieval-only**: NDCG@k (graded relevance, position-discounted), MRR (first-hit reciprocal), Recall@k (coverage), Hit@k (binary). Report at k = 5, 10, 20.
- **RAGAS metrics**:
  - **Faithfulness** = claims-extracted-from-answer / claims-supported-by-context (NLI-prompted).
  - **Answer relevancy** = similarity of answer to LLM-rephrased queries derived from the answer.
  - **Context precision** (rank-aware: are relevant chunks at top?).
  - **Context recall** (needs ground truth).
- **TruLens RAG triad**: context relevance, groundedness, answer relevance — all LLM-as-judge.
- **LLM-judge biases**: length (verbose answers under-rated ~10% by some judges, over-rated by others), positional, self-preference, format. Mitigations: ensemble of 3 judges (~+8% accuracy), pairwise prompts with order-swap, calibrated rubrics with anchor examples, capping `max_tokens` to neutralize length.
- **Golden set**: 200–500 (query, ideal-answer, supporting-doc-ids) tuples drawn from production logs (sampled, redacted, human-validated). Refresh quarterly.

## Hallucination / attribution

- **Faithfulness via NLI**: split answer into atomic claims (LLM), each claim → (entail / neutral / contradict) over retrieved context. `groundedness < 1` → hallucination.
- **Citation grounding via Anthropic Citations API** (Messages API, `citations: {enabled: true}`): Claude returns sentence/passage spans into provided documents. Reported case (Endex): source-hallucination 10% → 0%, +20% citations per response. Caveat: citations don't fix factual errors when the source itself is wrong.
- **Patronus Lynx, RAGTruth, MiniCheck** — open-source hallucination detectors; combine with judge ensemble for cheap online QA.

## Index freshness

- **Embedding-drift sources**: tokenizer change, model version bump, normalization toggle, preprocessing edit, re-embedding only a subset. **Rule**: one index = exactly one (`model_version`, `pipeline_hash`, `normalization`) tuple. Pin via `pipeline_id` field on every vector.
- **Hot/cold split**: hot index — recent N days, frequent incremental upserts; cold index — bulk-rebuilt off-peak (3 AM weekends), promoted atomically. Pinecone, Weaviate, Qdrant support zero-downtime alias swap.
- **Re-embed cost**: text-embedding-3-large ~$0.13 / 1M tokens — re-embedding 1B tokens = $130; budget when changing models. Voyage and Cohere quote similar; OSS local re-embed dominated by GPU-hours.
- **Incremental indexing**: emit `{doc_id, content_hash, last_modified}` events; only re-embed when `content_hash` changes. Tombstone deletes; never partially update a chunked doc — re-chunk the whole document.

## Long context vs RAG

- **Long-context wins**: small corpora (≤ 200 pages), unique single-document tasks, multi-hop reasoning where chunking would sever dependencies, exploratory analysis.
- **RAG wins**: large corpora (>1M tokens), low-latency / high-QPS, cost-sensitive, requires citation per answer, frequently updated content.
- **"Lost in the middle" / context rot**: accuracy degrades for content placed mid-context. Claude reports ~90% retrieval at 1M tokens (≈ 10% miss). Gemini 1.5 Pro: 99.7% on synthetic NIAH, ~60% on realistic multi-fact recall.
- **Cost ratio reported**: 1M-token request ~30–60× slower and ~1250× cost per query vs RAG at equivalent retrieval quality. **Hybrid routing** (cheap-RAG-first, escalate-to-long-context) is the 2026 dominant pattern.

## Multimodal RAG

- **ColPali** (ICLR 2025): VLM (PaliGemma backbone) → multi-vector embeddings of page-image patches. Late-interaction MaxSim between query token vectors and patch vectors. Eliminates OCR / layout-parse / text-chunking pipelines for PDFs, slides, screenshots.
- **ColQwen2** — Qwen2-VL backbone, same recipe; **ColSmol** — small variant for edge.
- Storage cost is high (multi-vector per page); use binary / scalar quantization, PLAID two-stage filter.
- Use when documents are layout-heavy (financial filings, scientific PDFs, scanned forms).

## Failure modes

- **Needle-in-haystack**: evaluate with **NoLiMa / RULER**, not synthetic NIAH (saturated).
- **Similarity-vs-relevance gap**: cosine high, intent wrong (e.g., antonyms cluster nearby in word2vec-derived spaces). Mitigate with reranker + query intent classification.
- **Vocabulary mismatch**: query uses common terms, docs use jargon (or vice-versa). Mitigate with HyDE or hybrid BM25/SPLADE.
- **Multi-hop**: single retrieval insufficient; needs decomposition + iterative retrieval (Self-RAG `retrieve` token, CRAG retrieval-quality evaluator with web fallback).
- **Negation / temporal**: embeddings ignore "not" and tense; route to a structured filter when detected.

## Production patterns

- **Caching layers**: query-embedding cache (key = `hash(query) + model_version`), retriever-result cache (TTL ≤ index-rebuild interval), reranker cache (key = `hash(query, top_k_doc_ids)`), answer cache only if generation is deterministic.
- **Retrieval-log mining**: sample 1% of queries with retrieved docs and downstream signals (click, thumbs-up, follow-up rephrasing) → weekly golden-set augmentation.
- **Drift monitoring**: track P50 retrieval-score distribution per day; alert on >2σ shift. Track answer-length distribution and faithfulness on a held-out probe set.
- **Self-RAG / CRAG in prod**: lightweight retrieval-quality classifier; on "ambiguous" → fall back to web / broader index; on "irrelevant" → skip retrieval.

## Recent changes (2024–2026)

- **Anthropic Contextual Retrieval** (Sept 2024) and **Citations API** (Jan 2025) — chunk augmentation + grounded sentence-level citations.
- **Late Chunking** (Jina, late 2024 → v3 paper Jul 2025) shipped as runtime option in `jina-embeddings-v3`.
- **ColPali / ColQwen2 / ColSmol** (ICLR 2025) — vision-late-interaction supplanting OCR-based document RAG.
- **Long-context shift**: Claude and Gemini 1M-token windows reframe RAG as a cost/latency/freshness optimization, not a context-size workaround. **"Context rot"** replaces "lost in the middle" as the dominant framing.
- **2026 reranker landscape**: Jina v3 sub-200 ms with listwise-quality results; BGE v2-m3 cheap default; Cohere 3.5 / Voyage 2.5 quality leaders.
- **BGE-M3** single-model hybrid (dense + sparse + multi-vector) reduces three-pipeline complexity to one forward pass.

## Authoritative references

- [Anthropic Contextual Retrieval](https://www.anthropic.com/news/contextual-retrieval)
- [Anthropic Citations API](https://www.anthropic.com/news/introducing-citations-api)
- [MTEB Leaderboard](https://huggingface.co/spaces/mteb/leaderboard)
- [Late Chunking paper](https://arxiv.org/abs/2409.04701), [Jina blog](https://jina.ai/news/late-chunking-in-long-context-embedding-models/)
- [ColPali paper](https://arxiv.org/abs/2407.01449)
- [ColBERTv2 paper](https://arxiv.org/abs/2112.01488), [Jina-ColBERT-v2](https://arxiv.org/abs/2408.16672)
- [Self-RAG](https://selfrag.github.io/)
- [RAGAS metrics](https://docs.ragas.io/en/stable/concepts/metrics/available_metrics/), [TruLens RAG triad](https://www.trulens.org/getting_started/core_concepts/rag_triad/)
- [Databricks long-context RAG](https://www.databricks.com/blog/long-context-rag-performance-llms)

## Guardrails

Before recommending a non-trivial RAG-pipeline change (chunking strategy, embed-model swap, reranker addition, hybrid weights, re-embed):
1. Quote the parameter / approach and any default
2. Cite the originating paper / blog / docs
3. Make the recommendation conditional on observed evidence (NDCG@k, MRR, faithfulness on a golden set, latency P99) — never blanket-tune
4. Verify model versions and pipeline IDs. Many features gate on releases (Citations API Jan 2025, Jina v3 native late chunking, ColPali ICLR 2025)

**Tuning without measurement is worse than defaults.**

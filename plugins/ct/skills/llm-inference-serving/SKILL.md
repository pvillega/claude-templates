---
name: llm-inference-serving
description: >
  Deep LLM-inference-serving operational intuition — vLLM V1, SGLang RadixAttention,
  TensorRT-LLM, TGI, llama.cpp tradeoffs; PagedAttention and KV-cache math (MHA/GQA/MLA),
  continuous batching and chunked prefill, prefix caching, prefill/decode arithmetic
  intensity and disaggregated serving (DistServe, Splitwise, Mooncake), speculative
  decoding (n-gram, Medusa, EAGLE-3, MTP), quantization formats (FP8/NVFP4/AWQ/GPTQ/GGUF),
  TP/PP/EP for MoE (DeepSeek EPLB/LPLB), TTFT/TPOT/goodput.
  Load ONLY when the task is about serving-engine knob tuning, KV-cache sizing,
  prefill/decode batching design, quantization-format selection for deployment,
  speculative-decoding choice, MoE/parallelism layout, or disaggregated serving.
  Do NOT load for fine-tuning/training, embeddings/reranker serving, prompt
  engineering, or hosted-API integration — those don't need this skill.
  Triggers on: "vLLM", "SGLang", "TensorRT-LLM", "TGI", "llama.cpp", "MLC-LLM",
  "PagedAttention", "RadixAttention", "continuous batching", "chunked prefill",
  "prefix caching", "FP8 KV cache", "kv-cache-dtype", "speculative decoding",
  "EAGLE-3", "Medusa", "n-gram decoding", "prompt lookup", "MLA", "GQA",
  "AWQ", "GPTQ", "Marlin", "Machete", "GGUF", "NVFP4", "MXFP4", "FP8 W8A8",
  "DistServe", "Mooncake", "Splitwise", "disaggregated prefill", "expert parallelism",
  "EPLB", "capacity factor", "TTFT", "TPOT", "ITL", "goodput", "RoPE scaling",
  "sliding window", "--gpu-memory-utilization", "--max-num-batched-tokens".
---

# LLM Inference Serving Operational Guide

Concise operational pointers for deep LLM-serving troubleshooting and tuning.

Assumes you already know what an LLM, KV cache, and a token are. This skill covers the **operational layer** — the parts models tend to gloss over: V1-engine internals, KV-cache math (MHA/GQA/MLA), continuous-batching/chunked-prefill economics, prefill/decode disaggregation, speculative decoding tradeoffs, quantization-format choice, and MoE+parallelism layout — current as of late 2025/early 2026.

## When to use

Load when the question is about:
- Tuning vLLM/SGLang/TGI/TRT-LLM serving knobs in production
- Sizing GPUs / KV-cache budget for a model + concurrency target
- Picking a quantization format for the deployment target (server vs edge)
- Diagnosing throughput-vs-latency regressions (TTFT vs ITL trade)
- Choosing between TP, PP, EP, DP for an MoE or dense model
- Deciding whether disaggregated prefill/decode is worth it
- Selecting a speculative-decoding strategy and predicting acceptance rate
- Long-context tuning (RoPE scaling, sliding window, chunked prefill)
- KV-cache memory math when adding GQA/MLA models
- Prefix-caching impact on RAG / multi-turn / system-prompt-heavy workloads
- Benchmark interpretation: goodput vs raw throughput, P99 latency
- Scaling MoE serving (Mixtral, DeepSeek-V3/R1) across nodes
- Deciding when to keep llama.cpp / GGUF vs server-grade engines
- Migrating between vLLM V0 and V1 engine

**Do NOT load** for: training / fine-tuning, embedding or reranker serving, agent / tool-calling protocol design, hosted-API integration, plain "what's an LLM" questions. For training fundamentals see `dl-training`; for fine-tuning see `fine-tuning-llms`.

## vLLM and the V1 engine

V1 is default since ~v0.8.1 (April 2025); V0 deprecated through 2025. V1 unifies prefill and decode under one scheduler with a `{request_id: num_tokens}` budget. EngineCore runs in its own process; scheduler and worker 0 are decoupled (symmetric TP); Persistent Batch caches input tensors and applies diffs. Reported V1 vs V0: up to 1.7× throughput on dense models, larger on multimodal.

Key knobs and how they interact:
- `--gpu-memory-utilization` (default 0.9) — fraction of GPU memory for the executor. KV cache pool ≈ this fraction × VRAM − weights − activations − buffers.
- `--max-num-seqs` (default 256 in V1) — max concurrent sequences (decode parallelism cap).
- `--max-num-batched-tokens` (default ≈8192 in V1; was 2048 in V0) — per-iteration token budget shared by prefill + decode chunks. Lower → better ITL; higher → better TTFT/throughput. Sweep 8k–64k.
- `--enable-chunked-prefill` (default True in V1) — splits long prompts into chunks so a giant prefill doesn't stall queued decodes.
- `--enable-prefix-caching` (default True in V1) — hash-keyed shared KV blocks across requests. Massive win for RAG / system-prompt / multi-turn; near-zero loss otherwise.
- `--kv-cache-dtype fp8` (E4M3 by default on Hopper+) — halves KV bytes vs FP16 with negligible quality loss for most models.
- `--quantization {fp8,awq,gptq,awq_marlin,gptq_marlin,nvfp4,...}` — weight scheme. Marlin/Machete kernels: ~2.6× for GPTQ, ~10.9× for AWQ vs naïve dequant.
- `--tensor-parallel-size`, `--pipeline-parallel-size`, `--data-parallel-size`, `--enable-expert-parallel`.
- `--speculative-config '{...}'` (V1 unified) replaces the older `--speculative-model`.

KV-token capacity ≈ `max-num-seqs × max-model-len`. Setting `max-model-len=128k` with `max-num-seqs=256` blows the KV budget on a single H100 — drop one. `gpu-memory-utilization ≥ 0.95` leaves no headroom for activations under bursty prefill; OOM appears under load, not at boot.

## KV-cache math

Per-token MHA bytes: `2 × n_layers × n_kv_heads × head_dim × bytes_per_elem`.

Worked: Llama 3 70B (80 layers, 8 KV heads via GQA, head_dim 128, BF16) = `2 × 80 × 8 × 128 × 2` = **327,680 B ≈ 0.31 MB/token**. At 100K tokens that's ~31 GB just for one sequence.

**GQA** collapses `n_kv_heads` from `n_query_heads` → `n_groups` (Llama 3: 64→8 = 8× KV reduction).

**MLA** (DeepSeek V2/V3/R1) replaces per-head K/V with a per-token shared low-rank latent (`d_c ≈ 512`) plus a small RoPE key (`d_R ≈ 64`). Bytes ≈ `batch × seq × n_layers × (d_c + d_R) × bytes`. DeepSeek-V3 at FP16 ≈ ~70 KB/token vs ~860 KB on a hypothetical MHA equivalent (~60× reduction, ~12× vs comparable GQA). Why DeepSeek can serve 128K cheaply and why vLLM treats MLA via a separate `hybrid_kv_cache_manager`.

KV quant: FP8 E4M3 cuts bytes 2×. NVFP4 KV (Blackwell) halves again with micro-block scaling (block 16 + FP8 scale + per-tensor FP32 scale).

## Batching evolution

- **Static**: all in-batch requests run to completion together. Padding waste, head-of-line blocking.
- **Dynamic** (Triton-style): wait window then batch. Predictable latency, lower throughput.
- **Continuous (iteration-level)** (Orca 2022; vLLM/SGLang/TGI/TRT-LLM): scheduler reconsiders the batch every forward step. Finished sequences leave; new ones enter freed KV slots immediately. Reported wins: 24× vs HF Transformers (vLLM original), 36.9× vs FasterTransformer (Orca paper).
- **Chunked prefill**: split a 32K-prompt prefill into per-step chunks sharing `max-num-batched-tokens` with decodes. Eliminates head-of-line ITL spikes; smooths P99. Default-on in V1.

## Prefill vs decode and disaggregated serving

- **Prefill**: compute-bound; full S×S attention per head per layer; intensity 200–400 ops/byte; saturates Tensor Cores. Llama 70B on H100 ≈ 92% compute utilization.
- **Decode**: memory-bandwidth-bound; one token per step requires a full pass over weights and the entire growing KV. Intensity 60–80 ops/byte; H100 utilization 20–40%; tensor cores idle, HBM saturated.

Co-locating both wastes the resource the other phase needs. Hence PD disaggregation:
- **Splitwise** (Microsoft): cost/power-driven PD split; layer-wise KV transfer overlapped with compute.
- **DistServe**: searches optimal P:D GPU ratio + per-phase parallelism to satisfy TTFT and TPOT independently — **optimizes goodput** (requests/s meeting SLO), not raw throughput.
- **Mooncake** (Moonshot/Kimi): KV-cache-centric architecture; pools CPU/DRAM/SSD/RDMA into a global KV store with RDMA-based KV transfer; reported 525% throughput uplift.

KV transfer is hundreds of MB/request — the new bottleneck. RDMA preferred over NCCL for cross-pod transfers. vLLM RFC #10818 closed in 2025; production-ready. **When worth it**: medium-to-long prompts, strict TTFT SLO, concurrency high enough that PD interference is real. **Skip for** short-prompt high-frequency chat — KV-transfer overhead dominates.

## Speculative decoding

Verifier runs N draft tokens per step, accepts the longest matching prefix. Speedup ≈ `accepted_length × target_step_cost / (target_step_cost + draft_cost)`.

- **Draft model**: small same-family LM (e.g., 1B drafting 70B). Quality drives acceptance.
- **N-gram / prompt lookup**: matches recent generated/prompt tokens; zero training. Acceptance 0.75–0.85 on code/structured/repetitive output, 0.5–0.65 on creative.
- **Medusa**: extra prediction heads on the target; trains heads, no separate draft.
- **EAGLE / EAGLE-2 / EAGLE-3** (NeurIPS 2025): predicts at the *feature* level (residual stream); reuses target features. **EAGLE-3 is current SOTA**; reported 2–6× in vLLM (Red Hat, mid-2025).
- **MTP** (multi-token prediction, native in DeepSeek-V3) treated as in-model spec decode.
- **PARD / MLP / suffix decoding**: lighter alternatives.

vLLM CLI: `--speculative-config '{"method":"ngram","num_speculative_tokens":4,"prompt_lookup_min":2,"prompt_lookup_max":5}'` or `'{"method":"eagle3","model":"…","num_speculative_tokens":2}'`.

**Footgun**: under high concurrency the batch fills naturally — speculation eats compute that would have served other requests, net throughput drops. Use spec decode for low-concurrency latency-sensitive workloads, not at saturation.

## Quantization formats

**Server-grade**:
- **FP8 W8A8** (E4M3 weights+activations): vLLM `--quantization fp8` on Hopper (cc ≥ 8.9) and Ada. E4M3 (range ±448) for weights/activations; E5M2 (range ±57344) historically for grads. Per-tensor scale standard; per-channel for sensitive layers.
- **NVFP4** (Blackwell B100/B200/B300, TRT-LLM ≥ 0.17, vLLM dense+MoE late 2025): block-16 microscaling with FP8 (E4M3) block scales + FP32 per-tensor. ~2× FP8 throughput on Blackwell; better accuracy than MXFP4 (block 32).
- **AWQ (4-bit) + Marlin**: weight-only INT4, activation-aware. Often highest throughput on GPU; quality close to FP16 for ≥7B. ~10.9× vs naïve dequant.
- **GPTQ + Marlin**: similar 4-bit with Hessian calibration; ~2.6× vs naïve. GPTQModel emits Marlin/Machete-ready checkpoints.
- **INT8 W8A8 (SmoothQuant)**: less common since FP8 landed on Hopper; useful pre-Hopper.
- **BNB load-in-4bit / 8bit**: Transformers-side, slow; prototyping only.

**Edge / CPU / Mac**:
- **GGUF** (llama.cpp). Q4_K_M is the sweet spot (mixed 4-bit with selective higher precision); Q5_K_M for headroom; Q3_K_S/Q2_K when you must squeeze. CPU, Apple Metal, Vulkan, CUDA, ROCm.

Per-channel scales > per-tensor on sensitivity-prone layers (e.g., `down_proj`); per-tensor cheaper, often fine elsewhere.

## Frameworks compared

- **vLLM** (Apache 2.0): broadest model coverage, V1 engine, strong NVIDIA + growing AMD/Inferentia/TPU. Default for general-purpose serving; wins on heterogeneous fleets and unique-prompt workloads.
- **SGLang** (Apache 2.0): RadixAttention reuses prefix-tree KV across siblings — ~29% throughput edge on H100 at 8B (16.2k vs 12.5k tok/s); up to 6.4× on prefix-heavy RAG/multi-turn; ~5–8% lower TTFT P95. Caveat: Python-router GIL ceiling around 127% CPU at very high concurrency. Default for DeepSeek, structured output, multi-turn agentic.
- **TensorRT-LLM** (NVIDIA): peak Hopper/Blackwell perf; ahead-of-time engine compile; first-class NVFP4. Best raw throughput on NVIDIA; least flexible; engine rebuild on every config change.
- **TGI** (HuggingFace): **maintenance mode since late 2025** — bug fixes only. Has TRT-LLM/vLLM backends. Pick only for legacy compatibility.
- **llama.cpp**: GGUF native; CPU + Metal + Vulkan + CUDA + ROCm; tiny binaries; no continuous batching at server-grade quality. Best on Mac/edge/single-user.
- **MLC-LLM** (TVM-based): broad hardware (Vulkan, WebGPU, mobile); compile-once-run-anywhere; weaker server batching.

## Parallelism and MoE

- **TP** shards weight matrices intra-layer; AllReduce per layer. Needs NVLink/NVSwitch for ≥8-way; degrades fast on PCIe.
- **PP** cuts the model by layers; AllReduce-free but bubble unless micro-batched. vLLM async PP send/recv: ~31% E2E throughput uplift.
- **EP** shards experts across ranks for MoE; AllToAll (not AllReduce). Use with DP-attention for the modern wide-EP MoE pattern (vLLM 0.9+/V1).
- **DP** replicates.

**MoE serving**: Mixtral 8x7B/8x22B is straightforward TP. DeepSeek-V3/R1 (256 experts + 32 redundant, MLA) is the modern hard case. **EPLB** (DeepSeek's open-source Expert Parallelism Load Balancer) duplicates hot experts and packs across GPUs to flatten per-step expert utilization; **LPLB** extends with linear-programming for per-batch fluctuations. Capacity factor caps per-expert tokens-per-step; over-cap tokens drop or reroute. Reported scale: vLLM Wide-EP 2.2k tok/s/H200 on DeepSeek; LMSYS reproduced 96-H100 PD-disaggregated DeepSeek with EP. NCCL 2.21+ added an EP AllToAll extension.

## Long context, latency goals

- **Long-context techniques**: PagedAttention page tables for non-contiguous KV; sliding-window attention gets a dedicated KV-cache group in vLLM's hybrid manager so windowed and full-attention layers share blocks without waste. RoPE scaling: `rope_scaling={"type":"dynamic","factor":2.0}`, `linear`, `yarn`, `llama3` for trained extensions. ChunkAttention: prefix-tree-aware FlashAttention.
- **Latency targets**: TTFT (prefill-dominated), TPOT/ITL (decode-dominated). Production: TTFT P99 < 500–1000 ms for chat; ITL P99 < 50–100 ms (≥ 10 tok/s feels live). **Goodput** = requests/s meeting both SLOs simultaneously — what DistServe/Mooncake actually optimize. Naive throughput hides that batching too aggressively wins tokens/s but blows TTFT P99.

## Authoritative references

**Engine docs**:
- [vLLM V1 announcement](https://blog.vllm.ai/2025/01/27/v1-alpha-release.html)
- [Inside vLLM (Sep 2025)](https://blog.vllm.ai/2025/09/05/anatomy-of-vllm.html)
- [vLLM optimization](https://docs.vllm.ai/en/stable/configuration/optimization/)
- [vLLM speculative decoding](https://docs.vllm.ai/en/latest/features/speculative_decoding/)
- [vLLM FP8 W8A8](https://docs.vllm.ai/en/stable/features/quantization/fp8/)

**Disaggregation / scaling**:
- [Mooncake paper](https://arxiv.org/pdf/2407.00079)
- [DistServe retrospective (Hao AI Lab)](https://haoailab.com/blogs/distserve-retro/)
- [DeepSeek EPLB](https://github.com/deepseek-ai/EPLB)
- [vLLM Wide-EP DeepSeek](https://blog.vllm.ai/2025/12/17/large-scale-serving.html)

**Speculation, kernels**:
- [EAGLE repo (1/2/3)](https://github.com/SafeAILab/EAGLE)
- [NVIDIA NVFP4 intro](https://developer.nvidia.com/blog/introducing-nvfp4-for-efficient-and-accurate-low-precision-inference/)
- [Anyscale continuous batching](https://www.anyscale.com/blog/continuous-batching-llm-inference)

## Guardrails

Before recommending a non-trivial serving change (KV dtype, quantization scheme, parallelism layout, spec-decoding method, disaggregation):
1. Quote the engine flag/parameter and its current default
2. Cite the engine's docs / release blog for the version in use
3. Make the recommendation conditional on observed metrics (TTFT/ITL P99, KV-cache hit rate, expert-utilization variance) — never blanket-tune
4. Verify the engine version. Many defaults shifted (V1 default in vLLM 0.8.1, EAGLE-3 mid-2025, NVFP4 in TRT-LLM 0.17+, TGI maintenance from late 2025)

**Tuning without measurement is worse than defaults.**

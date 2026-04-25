---
name: pytorch
description: >
  Deep PyTorch operational intuition — torch.compile (Dynamo/Inductor) recompile and
  graph-break diagnosis, CUDA OOM and allocator tuning, FSDP2 vs FSDP1 vs DDP,
  AMP/bfloat16 vs FP16+GradScaler, DataLoader bottleneck tuning, Profiler+Kineto and
  memory_viz, NaN/anomaly mode cost, deterministic algorithms, SDPA/FlexAttention
  backends, version-by-version feature trail (2.4–2.8).
  Load ONLY when the task is about torch.compile diagnosis, CUDA OOM/fragmentation,
  FSDP/DDP setup or sharding choice, mixed-precision policy, DataLoader stalls,
  profiler/memory-snapshot interpretation, attention-backend selection, or determinism
  tradeoffs. Do NOT load for plain training-loop authoring, model architecture choice,
  generic loss-curve debugging, or HuggingFace API surface that doesn't touch torch
  knobs — those don't need this skill. For training fundamentals (init, optimizer,
  scheduler, normalization), pair with `dl-training`.
  Triggers on: "torch.compile", "TorchDynamo", "TorchInductor", "AOTInductor",
  "fullgraph", "max-autotune", "graph break", "TORCH_LOGS", "tlparse",
  "PYTORCH_CUDA_ALLOC_CONF", "expandable_segments", "max_split_size_mb",
  "memory._snapshot", "memory_viz", "FSDP2", "fully_shard", "MixedPrecisionPolicy",
  "find_unused_parameters", "static_graph", "GradScaler", "torch.amp.autocast",
  "scaled_dot_product_attention", "FlexAttention", "SDPBackend",
  "use_deterministic_algorithms", "CUBLAS_WORKSPACE_CONFIG", "torchtitan",
  "torch.compiler.set_stance", "register_full_backward_hook", "persistent_workers",
  "prefetch_factor".
---

# PyTorch Operational Guide

Concise operational pointers for deep PyTorch troubleshooting and tuning.

Assumes you already know tensors, autograd, `nn.Module`, optimizers, and basic training loops. This skill covers the **operational layer** — the parts models tend to gloss over: torch.compile internals, allocator behavior, FSDP2 vs FSDP1, mixed-precision footguns, profiler/memory-snapshot workflows, attention-backend selection, and the version trail through 2.4–2.8.

## When to use

Load when the question is about:
- `torch.compile` diagnosis: recompile thrash, graph breaks, cache poisoning, mode selection (`reduce-overhead`/`max-autotune`/`max-autotune-no-cudagraphs`), `fullgraph=True`, dynamic shapes
- AOTInductor: ahead-of-time compile, `.pt2` package, stable C++ ABI
- CUDA OOM diagnosis: `PYTORCH_CUDA_ALLOC_CONF` knobs, `expandable_segments`, fragmentation, `torch.cuda.memory._snapshot()` + memory_viz
- FSDP2 (`fully_shard`) vs FSDP1 (`FullyShardedDataParallel`) vs DDP — sharding strategies, `MixedPrecisionPolicy`, `reshard_after_forward`, CPU offload, HSDP via 2D mesh
- DDP `find_unused_parameters` cost vs `static_graph`, comm hooks
- AMP / bfloat16 / FP16 + GradScaler choice; autocast scope footguns
- DataLoader bottlenecks: `num_workers`, `pin_memory`, `persistent_workers`, `prefetch_factor`, RNG-per-worker
- Profiler + Kineto: schedule, trace handler, memory profiler, chrome trace
- NaN / inf forensics: anomaly mode (cost), forward / `register_full_backward_hook`
- Determinism: `use_deterministic_algorithms`, `CUBLAS_WORKSPACE_CONFIG`, cudnn benchmark/deterministic tradeoff
- SDPA backends (FlashAttention, mem-efficient, cuDNN, math) and FlexAttention
- Mapping a feature to a 2.x version (FSDP2 stable in 2.6, FlexAttention in 2.5+, CUTLASS Inductor in 2.8)

**Do NOT load** for: plain training-loop authoring, architecture choice, generic loss-curve debugging, ONNX/mobile export, vendor inference servers, HuggingFace API surface that doesn't touch torch knobs. For init/optimizer/scheduler/norm fundamentals, use `dl-training`.

## torch.compile (Dynamo + Inductor)

- **Modes**: `mode="default"` balanced; `"reduce-overhead"` uses CUDA Graphs (kills launch overhead, copies inputs — pin tensors with `cudagraph_mark_step_begin` to avoid corruption); `"max-autotune"` adds Triton/CUTLASS autotune + CUDA Graphs (very long compile); `"max-autotune-no-cudagraphs"` autotune without graph constraints. Set `fullgraph=True` to **raise** on graph break instead of silently falling back to eager.
- **Dynamic shapes**: `dynamic=None` is the recommended default — first call traces static, second call with a different shape promotes that dim to dynamic. Force with `dynamic=True` for variable-length workloads (avoids per-batch recompile).
- **Recompile triggers**: tensor shape change without `dynamic`, dtype/device change, Python closure-over var change, guard-failure on int/bool, list-length change, `requires_grad` toggling.
- **Cache poisoning**: after `torch._dynamo.config.recompile_limit` (default 8; renamed from `cache_size_limit` in 2.6+) the frame runs eager forever — fix the cause, don't bump the limit.
- **Diagnosis**: `TORCH_LOGS="graph_breaks,recompiles,perf_hints"` plus `tlparse` for HTML rollups; `torch._dynamo.explain(fn)(*args)` for static analysis. Compile cache lives at `TORCHINDUCTOR_CACHE_DIR` (default `/tmp/torchinductor_$USER`); remote cache via `TORCHINDUCTOR_FX_GRAPH_REMOTE_CACHE`. **Mega Cache** (2.7) is a single tarballable artefact for cross-host warm-up — flag for any team running compile in CI.
- **`torch.compiler.set_stance`** (2.6+) gates per-call: `"force_eager"`, `"eager_on_recompile"`, `"fail_on_recompile"`, `"default"`. `fail_on_recompile` is the test-suite guard against silent perf regression.
- **AOTInductor**: `torch._inductor.aoti_compile_and_package` → `.pt2` callable from Python or C++ via stable libtorch ABI (firmed in 2.6/2.7). Inductor CUTLASS backend (2.8) covers `mm`/`fp8 mm`/`addmm`/`bmm` for compile and AOTI.
- **Footguns**: data-dependent shapes recompile every call; closures over varying-length Python lists blow the cache; `print` mid-graph breaks; `if tensor.item()` is a graph break by definition.

## CUDA OOM and the allocator

- **Allocator config** via `PYTORCH_CUDA_ALLOC_CONF` (alias `PYTORCH_ALLOC_CONF` for multi-device). Knobs:
  - `expandable_segments:True` — single growing virtual-memory segment per stream. First thing to try when reserved ≫ allocated.
  - `max_split_size_mb:N` — prevents splitting free blocks below N MiB. Reduces tile-and-can't-merge fragmentation for fixed-size LLM workloads. Footgun: too small wastes memory in unused tail.
  - `garbage_collection_threshold:0.8` — sync+release before fallback to OOM.
  - `roundup_power2_divisions:N` — quantises requested sizes.
  - `backend:cudaMallocAsync` — driver pool; **disables most snapshot tooling**.
- **Snapshot toolchain**: `torch.cuda.memory._record_memory_history(max_entries=100_000)` then `torch.cuda.memory._dump_snapshot("snap.bin")` (the file is a serialized snapshot in PyTorch's snapshot format). Drop on `pytorch.org/memory_viz` for a flame timeline with allocation stacks. Quick metrics: `memory_allocated`, `memory_reserved`, `max_memory_allocated`, `memory_stats()`.
- **Footguns**: `nvidia-smi` shows the driver pool, not the allocator pool — freed tensors stay reserved until `torch.cuda.empty_cache()`. `expandable_segments` interacts badly with some CUDA Graph capture flows and a few custom kernels.

## FSDP2, FSDP1, DDP

- **FSDP2** (`torch.distributed.fsdp.fully_shard`): introduced in 2.4, beta in 2.5, recommended-default in 2.6+. Per-parameter sharding via DTensor on `dim=0`; `model.parameters()` become DTensor in place. Reported ~7% lower per-GPU memory and ~1.5% throughput gain over FSDP1 in torchtitan benchmarks. **Use this for new code.**
- **FSDP1** (`FullyShardedDataParallel`): legacy flat-parameter API, in maintenance. Only reach for it when stuck with `ShardingStrategy.HYBRID_SHARD` + `auto_wrap_policy` flows.
- **FSDP2 knobs**:
  - `MixedPrecisionPolicy(param_dtype=torch.bfloat16, reduce_dtype=torch.float32, output_dtype=...)`. Keep `reduce_dtype=fp32` for stable gradient all-reduce.
  - `reshard_after_forward=True|False|int` — `False` keeps gathered params for reuse during recomputation; integer reshards every-k layers.
  - `offload_policy=CPUOffloadPolicy(pin_memory=True)` for parameter offload.
  - HSDP = 2D `init_device_mesh` with `Shard` × `Replicate`.
- **`torch.compile` composes per-module** (regional compile, 2.5) on the inner block; activation checkpointing via `torch.distributed._composable.checkpoint`.
- **DDP**: `find_unused_parameters=True` is a real per-iteration cost — extra autograd-graph traversal. Prefer `static_graph=True` when the unused-set is stable across iterations (DDP captures it on iter 1 and reuses). `gradient_as_bucket_view=True` saves a copy. Comm hooks: `bf16_compress_hook`, `fp16_compress_hook`, `powerSGD_hook`.
- **Reference**: `github.com/pytorch/torchtitan` — production FSDP2 + TP + PP + Float8 + `torch.compile` templates.

## AMP / bfloat16 / FP16

- **Modern call**: `torch.amp.autocast(device_type="cuda", dtype=torch.bfloat16)` and `torch.amp.GradScaler("cuda")`. The `torch.cuda.amp.*` aliases are deprecated.
- **GradScaler is FP16-only** — bfloat16 has the same 8-bit exponent as fp32, so under/overflow is rare. Don't use it with bf16.
- **bf16 on Ampere+ (sm_80) and Hopper/Blackwell**; FP16 only on Volta/Turing or when bf16 path is materially slower for your GEMM shape.
- **Under FSDP2**, set precision via `MixedPrecisionPolicy`, **not** module-level autocast — cleaner all-gather casts.
- **Footguns**: autocast does NOT cast LayerNorm/softmax inputs implicitly — those stay original dtype (source of "fp16 NaN at LN" lore). bf16 logits on CrossEntropy with extreme magnitudes can still produce -inf via exp underflow.

## DataLoader

- **`num_workers`** heuristic: `min(physical_cores, 8)` per GPU on a single-node multi-GPU box. Oversubscription thrashes the OS scheduler.
- **`pin_memory=True`** only helps if you also pass `non_blocking=True` to `.to(device)`. Otherwise dead cost.
- **`persistent_workers=True`** skips fork+import each epoch — large win for HuggingFace `datasets` (keeps Arrow mmaps warm).
- **`prefetch_factor=2`** (default) buffers `2*num_workers` batches; raise only if GPU stalls visibly.
- **`worker_init_fn`** is **mandatory** if any worker uses numpy/random — every fork inherits the same numpy seed. Derive per-worker seed from `torch.initial_seed()`.
- **TorchData / DataPipes** were deprecated in v0.8 (Jul 2024) and removed in v0.10 — pin to 0.9 if you depend on them. `StatefulDataLoader` (in `torchdata`) is the supported successor for resumable distributed pipelines and is what torchtitan uses.

## Profiler

- `torch.profiler.profile(activities=[CPU, CUDA], schedule=schedule(wait=1, warmup=1, active=3, repeat=2), on_trace_ready=tensorboard_trace_handler("./tb"), record_shapes=True, profile_memory=True, with_stack=True)`. Wrap user-named regions with `record_function("forward")`.
- **Kineto** backend produces chrome-trace JSON (`chrome://tracing`, Perfetto). `with_stack=True` is expensive but is the only way to get Python frames in the trace.
- **Memory profiler**: `profile_memory=True` emits per-allocation events; combine with `_record_memory_history` for the snapshot viewer.
- **Footguns**: `repeat` controls cycle count, not total duration; `on_trace_ready` is called once per cycle. Tight `active` windows produce Kineto reassociation warnings.

## NaN / numerical debugging

- **`torch.autograd.set_detect_anomaly(True)`** records forward stacks so backward NaN raises with a forward frame. **2–10x slowdown** — never leave on.
- **Hooks**: `module.register_forward_hook` (current API) and `module.register_full_backward_hook`. `register_backward_hook` is deprecated and silently drops grads on in-place ops.
- Pattern: register `assert torch.isfinite(t).all()` hooks **before** turning anomaly mode on (anomaly raises before hooks fire).

## Determinism

Triple needed: `torch.use_deterministic_algorithms(True, warn_only=False)`, `torch.backends.cudnn.deterministic = True`, `torch.backends.cudnn.benchmark = False`. Plus env `CUBLAS_WORKSPACE_CONFIG=:4096:8` (or `:16:8`) — without it, post-CUDA-10.2 cuBLAS GEMMs are nondeterministic and will raise. `cudnn.benchmark=True` searches the fastest conv algo on first call (great for fixed-shape models) but the search itself depends on prior allocator state — results drift between runs. Determinism + AMP + FSDP2 mostly works in 2.7+; expect a few ops (`index_add_`, scatter_add on CUDA) to fall back or raise.

## Attention backends

- **`F.scaled_dot_product_attention`** dispatches across four backends: FlashAttention (default for non-trivial shapes), memory-efficient (xformers-style), cuDNN fused (added 2.5; preferred on H100 for some shape regimes), and math (slow reference).
- **Force selection**: `with torch.nn.attention.sdpa_kernel(SDPBackend.FLASH_ATTENTION):` or list form.
- **Constraints**: FlashAttn requires fp16/bf16, head_dim divisible by 8, no arbitrary `attn_mask` (only causal/none); mem-efficient supports arbitrary masks but bf16/fp16 only.
- **FlexAttention** (`torch.nn.attention.flex_attention`, 2.5+): takes a `score_mod` callable (ALiBi, sliding-window, doc-mask) plus a `BlockMask`, lower-bounds to a fused Triton kernel via Inductor. 2.7 added a decoding-optimised variant with GQA + PagedAttention; 2.8 added trainable biases and nested-jagged-tensor support.

## Version trail (2.4 → 2.8)

- **2.4 (Jul 2024)**: Python 3.12 for `torch.compile`, AOTInductor freezing on CPU, FSDP2 prototype, libuv TCPStore default.
- **2.5 (Oct 2024)**: FlexAttention initial, cuDNN SDPA backend, regional compilation, Intel-GPU eager, `torchdata.datapipes` deprecated.
- **2.6 (Jan 2025)**: `torch.compiler.set_stance`, AOTInductor stable C ABI, FSDP2 promoted to recommended-default, Python 3.13 for compile, FP16 on x86 CPU.
- **2.7 (Apr 2025)**: NVIDIA Blackwell support, **Mega Cache** (cross-host compile-cache portability), FlexAttention decoding backend (GQA + PagedAttention), AOTInductor ABI guarantees firmed.
- **2.8 (Aug 2025)**: hierarchical compilation, **Inductor CUTLASS backend** (mm/fp8 mm/addmm/bmm), control-flow operators (`cond`, `while_loop`, `scan`, `associative_scan`, `map`) for compile/export, Inductor Graph Partition for CUDA Graph, `torch::stable::Tensor` for third-party C++, DCP HuggingFace SafeTensors.

## Authoritative references

**Official** (`pytorch.org`):
- [PyTorch 2.8 release blog](https://pytorch.org/blog/pytorch-2-8/) and [2.7](https://pytorch.org/blog/pytorch-2-7/), [2.6](https://docs.pytorch.org/blog/pytorch2-6/), [2.4](https://pytorch.org/blog/pytorch2-4/)
- [CUDA semantics & allocator](https://docs.pytorch.org/docs/stable/notes/cuda.html)
- [Memory snapshot guide](https://docs.pytorch.org/docs/stable/torch_cuda_memory.html)
- [`fully_shard` (FSDP2)](https://docs.pytorch.org/docs/stable/distributed.fsdp.fully_shard.html), [FSDP tutorial](https://docs.pytorch.org/tutorials/intermediate/FSDP_tutorial.html)
- [`torch.compile` troubleshooting](https://docs.pytorch.org/docs/stable/user_guide/torch_compiler/torch.compiler_troubleshooting.html)
- [`torch.amp`](https://docs.pytorch.org/docs/stable/amp.html), [Profiler](https://docs.pytorch.org/docs/stable/profiler.html)
- [FlexAttention](https://docs.pytorch.org/docs/stable/nn.attention.flex_attention.html)

**Reference repos / deep-dives**:
- [torchtitan](https://github.com/pytorch/torchtitan) — production FSDP2 + TP + PP + Float8 + compile templates
- Edward Yang — [State of `torch.compile` (Aug 2025)](https://blog.ezyang.com/2025/08/state-of-torch-compile-august-2025/)
- Zach DeVito — [Memory snapshots](https://zdevito.github.io/2022/08/16/memory-snapshots.html)

## Guardrails

Before recommending a non-trivial operational change (compile mode, allocator config, FSDP policy, autocast dtype, attention backend):
1. Quote the parameter/flag and its default
2. Cite the official PyTorch doc / blog section
3. Make the recommendation conditional on observed evidence (profiler trace, memory snapshot, recompile log) — never blanket-tune
4. Verify the PyTorch version. Many defaults shifted (FSDP2 stable in 2.6, FlexAttention decoding in 2.7, Inductor CUTLASS in 2.8)

**Tuning without measurement is worse than defaults.**

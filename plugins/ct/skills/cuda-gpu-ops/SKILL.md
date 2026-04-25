---
name: cuda-gpu-ops
description: >
  Deep GPU/CUDA operational intuition — nvidia-smi/dcgm field meanings, NCCL env-var
  tuning and topology debugging, MIG vs MPS vs time-slicing tradeoffs, NVLink/NVSwitch/
  InfiniBand/GPUDirect interconnect, Nsight Systems/Compute profiling workflow, power/
  thermal/ECC diagnosis, Xid catalog and RMA thresholds, Hopper (TMA/FP8/wgmma/DSMEM)
  and Blackwell (FP4/NVLink5/decompression) specifics, CUDA stream gotchas, allocator
  fragmentation.
  Load ONLY when the task is about cluster-level GPU debugging, distributed-training
  hangs, multi-tenant sharing decisions, interconnect sizing, profiling, power/thermal
  capping, ECC/Xid diagnosis, or Hopper/Blackwell architecture-specific tuning. Do NOT
  load for plain training-loop authoring, model architecture, dataloader perf, ROCm/
  Gaudi/MPS, or cloud SKU billing — those don't need this skill.
  Triggers on: "nvidia-smi", "dcgm", "dcgm-exporter", "DCGM_FI_PROF", "NCCL", "NCCL_DEBUG",
  "NCCL_IB_HCA", "NCCL_SOCKET_IFNAME", "NCCL_TOPO_FILE", "NCCL_P2P_DISABLE", "MIG",
  "MPS", "NVLink", "NVSwitch", "InfiniBand", "GPUDirect RDMA", "GPUDirect Storage",
  "nvidia-peermem", "nsys", "ncu", "Nsight", "CUPTI", "Xid", "ECC", "row remapping",
  "page retirement", "persistence mode", "TMA", "wgmma", "FP8", "FP4", "transformer engine",
  "DSMEM", "Hopper", "Blackwell", "GB200", "HBM3e", "cudaMallocAsync", "default stream",
  "expandable_segments".
---

# GPU/CUDA Operational Guide

Concise operational pointers for cluster-level GPU debugging, distributed training, and architecture-specific tuning.

Assumes you already know that GPUs run kernels, that CUDA exists, and basic CUDA programming concepts. This skill covers the **operational layer** — the parts models tend to gloss over: what `nvidia-smi` numbers actually mean, NCCL knobs and topology, MIG/MPS/streams decisions, interconnect sizing, profiling, power/thermal/ECC, Xid forensics, and Hopper/Blackwell specifics — current as of late 2025/early 2026.

## When to use

Load when the question is about:
- "GPU at 100% util but slow" — the classic memory-bound vs compute-bound trap
- Multi-node distributed training that hangs, stalls, or runs at fraction of expected throughput
- Choosing between MIG / MPS / time-slicing for a Kubernetes/Slurm GPU pool
- Sizing or selecting interconnect (NVLink vs PCIe vs InfiniBand) for a new cluster
- Reading `dmesg` / journal for `NVRM: Xid` and deciding "RMA the card or reboot"
- Power/thermal capping a node for thermal headroom or PSU constraints
- Profiling a PyTorch/JAX step and deciding whether the bottleneck is kernel, memcpy, or Python
- Triaging "CUDA OOM" with significant `reserved` headroom (fragmentation)
- Enabling FP8/FP4 paths on Hopper/Blackwell and validating numerics
- Designing a CUDA-stream graph and avoiding accidental serialization through stream 0
- Debugging GPUDirect RDMA / `nvidia-peermem` failures on a new IB fabric
- Building a Prometheus dashboard with the right metrics (saturation, not utilization)
- Validating that a multi-tenant inference service has no noisy-neighbor SM contention
- Hardening a long-running training job against silent ECC corruption

**Do NOT load** for: model architecture or dataset pipelines without a GPU-systems angle, plain PyTorch/TF API questions, AMD ROCm / Intel Gaudi / Apple MPS, cost/billing comparisons.

## nvidia-smi: what the numbers mean

- **`GPU-Util` (Volatile)** is the **percentage of time** in the sample window that **at least one kernel** was running. Aggregate over all SMs, treats GPU as a single unit. A single warp pinging one SM yields 100%. You can hit 100% on pure memcpy with zero compute. **Occupancy proxy at best, saturation never.**
- **DCGM** profiling metrics via `dcgm-exporter` give real saturation:
  - `DCGM_FI_PROF_SM_ACTIVE` — fraction of cycles an SM had a resident warp
  - `DCGM_FI_PROF_SM_OCCUPANCY` — average warp slots filled / max
  - `DCGM_FI_PROF_PIPE_TENSOR_ACTIVE` — tensor-core busy ratio (the metric you actually want for LLM training)
  - `DCGM_FI_PROF_PIPE_FP16_ACTIVE`, `_FP32_ACTIVE`, `_FP64_ACTIVE`
  - `DCGM_FI_PROF_DRAM_ACTIVE` — HBM bandwidth utilization. **High DRAM_ACTIVE + low TENSOR_ACTIVE = memory-bound.**
  - `DCGM_FI_PROF_PCIE_TX_BYTES`, `_NVLINK_TX_BYTES` — interconnect.
- **`Memory-Usage`** is allocator-reserved VRAM, not application-resident. Frameworks hold caching pools — high Memory-Usage with low actual tensor footprint is normal.
- **`Pwr:Usage/Cap`** — sustained `Usage == Cap` means you are power-throttled (check `Throttle Reasons` from `nvidia-smi -q`).
- **Temp throttling** — H100 SXM thermal slowdown ~87°C, HW slowdown ~90°C, shutdown ~95°C. Hopper exposes `Memory Temp` separately (HBM3 throttles ~95°C). Watch `Throttle Reasons: HW Thermal Slowdown`.
- **ECC** in `nvidia-smi -q -d ECC`: `Volatile` resets on driver reload; `Aggregate` is lifetime. SBE corrected; DBE uncorrectable, on Ampere+ triggers row remapping.
- **Persistence mode** (`nvidia-smi -pm 1`) keeps the kernel module loaded between client exits. Without it, every CUDA process pays a ~1–3 s init and clock state resets. Mandatory on any node with custom power/clock locks.
- **`dcgmi diag -r 3`** runs an active diagnostic (PCIe, NVLink, memory bandwidth, SM stress, ECC). Use as admission test before scheduling on a suspect node.

## NCCL operational vars

`NCCL_DEBUG=INFO` (or `WARN`, `TRACE`); `NCCL_DEBUG_SUBSYS=INIT,NET,GRAPH` to scope; `NCCL_DEBUG_FILE=/tmp/nccl.%h.%p.log` for per-host/PID.

**Transport selection** — at init NCCL prints lines like `Channel 00 : 0[0] -> 1[1] via P2P/NVLink` or `via NET/IB/...`. These tell you whether intra-node went over NVLink (good), PCIe P2P (acceptable), or shared memory/sockets (bad).

- `NCCL_IB_HCA=mlx5_0,mlx5_1` — filter HCAs. **Always prefix `=` for exact match** — `mlx5_1` without `=` also matches `mlx5_10..mlx5_19`. `:1` for port; `^` excludes.
- `NCCL_IB_DISABLE=1` — force TCP fallback; confirms IB-specific issue.
- `NCCL_SOCKET_IFNAME=eth0,ib0` — filter TCP control-plane interfaces. Mandatory on hosts with bond/docker/cni interfaces or NCCL picks the wrong one and hangs at init.
- `NCCL_P2P_DISABLE=1` — diagnostic only; perf drops sharply.
- `NCCL_SHM_DISABLE=1` — disable host-shared-memory fallback; forces P2P or net.
- `NCCL_TOPO_FILE` — override auto-detect with NVIDIA-provided XML for DGX/HGX or non-standard PCIe topology.
- `NCCL_ALGO=Ring|Tree|CollNet|NVLS` and `NCCL_PROTO=Simple|LL|LL128`. **Don't set unless benchmarking.** Ring = best peak BW for large messages; Tree = log(n) latency at medium sizes; **NVLS** uses NVLink Sharp on NVSwitch (H100 NVL/GB200) — ~2× faster all-reduce.
- `NCCL_BUFFSIZE` (default 4 MB) — raise for very large all-reduce sizes if memory permits.

Common breakage: containers without `--privileged` or without `NVIDIA_VISIBLE_DEVICES`; missing `nvidia-peermem` kernel module silently drops to staged TCP.

## Multi-tenant sharing

- **MIG** (Multi-Instance GPU) — A100, A30, H100, H200, H800. Hardware partitions: dedicated SM slices, L2, memory controllers, HBM. Up to 7 instances on H100 (1g.10gb, 2g.20gb, 3g.40gb, 7g.80gb). Enable: `nvidia-smi -mig 1`, then `nvidia-smi mig -cgi`. Hardware-isolated; safe for multi-tenant. Caveat: no NVLink between MIG instances; tensor-parallel inside a partition only.
- **MPS** (Multi-Process Service) — `nvidia-cuda-mps-control -d`. Multiple CUDA contexts share one GPU concurrently. On Volta+ each client gets isolated GPU address space, but a fatal fault propagates to all clients. **Trusted tenants only.** Best for ensemble inference, MoE expert dispatch, batched microservices. Avoid for untrusted code or long-running training.
- **Time-slicing** (default Kubernetes device-plugin) — multiple pods see same physical GPU; CUDA context switch on each kernel. No isolation, no concurrency. Fine for dev/notebook pools.
- **CUDA streams** — within one process; the right tool for concurrent kernels. Not multi-tenant.

Decision: untrusted multi-tenant → MIG (only on supported SKUs). Trusted concurrent → MPS. Casual pool → time-slicing. Within one app → streams.

## Interconnect

| Gen | Per-GPU NVLink | Use |
|---|---|---|
| NVLink 3 (A100) | 600 GB/s | Ampere |
| NVLink 4 (H100) | 900 GB/s | Hopper |
| NVLink 5 (B100/B200) | 1.8 TB/s | Blackwell — 18 sublinks × 100 GB/s |

**NVSwitch** — full-bandwidth crossbar across an NVLink domain. 4th-gen on Blackwell: 72 NVLink5 ports/chip; **GB200 NVL72** aggregates 130 TB/s across 72 GPUs in one rack-scale NVLink domain; scales to 576 GPUs.

**PCIe** — Gen5 x16 = 64 GB/s bidir (~14× slower than NVLink5). Gen6 doubles to 128 GB/s; rolling out 2025–2026. PCIe is the GPU-CPU and GPU-NIC path; NVLink is GPU-GPU.

**InfiniBand** — HDR 200 Gb/s (25 GB/s), NDR 400 Gb/s (50 GB/s), XDR 800 Gb/s (100 GB/s, shipping 2025). One ConnectX-7/8 NIC per GPU is the rule on H100/B200 nodes.

**GPUDirect RDMA** — NIC reads/writes GPU HBM directly, bypassing host bounce buffers. Requires `nvidia-peermem` (CUDA 11.4+, R470+). Validate with `ibv_devinfo` and `ib_write_bw --use_cuda=0`.

**GPUDirect Storage (GDS)** — NVMe (or NVMe-oF) → GPU memory via DMA, bypassing CPU memcpy. `cuFile` API; 2–5× on read-heavy data loaders.

**Topology matters**: NIC↔GPU on different PCIe switches/sockets → RDMA crosses sockets via UPI and tanks. `nvidia-smi topo -m` shows the affinity matrix (`PIX` = same switch, `PXB` = across switches, `SYS` = across sockets).

## Profiling

- **`nsys` (Nsight Systems)** — system-wide timeline; CPU+GPU+NCCL+CUDA APIs. Use first to find *where* time goes. `nsys profile -t cuda,nvtx,osrt,cudnn,cublas -o run --capture-range=cudaProfilerApi --cuda-graph-trace=node python train.py`. Wrap iterations with `torch.cuda.nvtx.range_push("step")`/`pop()` and `torch.cuda.cudart().cudaProfilerStart()`.
- **`ncu` (Nsight Compute)** — single-kernel deep dive (SM/L1/L2/HBM counters, occupancy, roofline). Use after nsys identifies a hot kernel: `ncu --target-processes all --set full -k regex:matmul -o report python train.py`. Replays the kernel with different counter groups; expensive — bound with `--launch-skip` and `--launch-count`.
- **`nvprof`** is **deprecated** since CUDA 11.x; not supported on Hopper/Blackwell. Use `ncu`.
- **CUPTI** — underlying API; PyTorch/TF/JAX profilers and DCGM build on it. Only one CUPTI session per process — `torch.profiler` and nsys collide.
- **PyTorch profiler** — Python-level events + CUDA, Chrome trace JSON. Cheaper than nsys, integrates with TensorBoard, but zero visibility outside PyTorch (NCCL kernels show as opaque blobs). Use nsys for distributed; PyTorch profiler for single-rank kernel attribution.

## Power and thermal

- `nvidia-smi -pm 1` — **persistence on first**, otherwise other settings get reset.
- `nvidia-smi -pl <W>` — set power cap. Bounded by min/max from `-q -d POWER`. Cluster-wide downcapping (e.g., 500W on 700W H100) commonly buys 5–15% PUE for ~3–7% perf loss.
- `nvidia-smi -lgc <minMHz>,<maxMHz>` — lock graphics clocks for deterministic benchmarking. `-rgc` resets.
- **GPU Boost** is opportunistic — clocks float to thermal/power headroom. Locking min == max only when you need determinism (loses 10–20% throughput).
- **Throttle reasons** (`-q -d PERFORMANCE`): `SW Power Cap` (soft from `-pl`), `HW Slowdown` (board PSU/OCP), `HW Thermal Slowdown` / `HW Power Brake Slowdown` (physical), `Sync Boost` (multi-GPU sync). Sustained `HW Thermal Slowdown` = airflow/coolant problem.

## ECC and when to swap

`nvidia-smi -q -d ECC,ROW_REMAPPER`:
- **SBE** Volatile/Aggregate — corrected. A few/week is normal; sudden burst on one bank means a row going bad.
- **DBE** — uncorrectable. Ampere+ retires the page or remaps the row; application sees `cudaErrorECCUncorrectable`; on training that's a dead rank.
- **Row remapping** (Hopper improved with reserved spare rows per bank): `Remapping Failure: Yes` or `Pending: Yes` means reboot. `Uncorrectable Error: Yes` after reboot = remap exhausted, **RMA**.

`dmesg | grep -i NVRM` for **Xid** codes:
- **13** Graphics Engine Exception (often SW)
- **31** GPU memory page fault (illegal address; SW bug)
- **43** GPU stopped processing (HW or driver hang)
- **48** DBE uncorrectable
- **63/64** ECC page retirement (63 = success, **64 = failure → RMA**)
- **74** NVLink error
- **79** GPU has fallen off the bus (PCIe link lost; reboot, recurrent → RMA)
- **94/95** Contained / Uncontained ECC (**95 → RMA**)

Swap thresholds (rule of thumb): >5 row remaps in a week, any Xid 64/79/95, sustained DBE > 0/day.

## Hopper specifics (H100/H200)

- **TMA** (Tensor Memory Accelerator) — async, descriptor-based 1D-5D tensor copy global ↔ shared memory. Single thread issues; HW handles strides/swizzling. Frees registers; backbone of FlashAttention-3.
- **FP8** — **E4M3** (more mantissa, fwd activations/weights) and **E5M2** (more range, gradients). 4× A100 FP16 rate.
- **Transformer Engine** — TE library + HW; per-tensor dynamic scaling between FP8 and BF16 to stay in range. Up to ~2× throughput on attention/GEMM with no quality loss when calibrated.
- **DSMEM** (Distributed Shared Memory) — within a thread block cluster, threads can read/write shmem of sibling blocks on other SMs. Combined with L2, multiplies on-chip BW.
- **wgmma** — warpgroup-level (4 warps = 128 threads) async MMA. Replaces `mma`. Compiles to `GMMA` SASS.
- **HBM3 (H100)**: 3.35 TB/s, 80 GB. **HBM3e (H200)**: 4.8 TB/s, 141 GB — same compute as H100, big inference win.
- Compute capability 9.0.

## Blackwell specifics (B100/B200/GB200)

- **FP4** — MXFP4/MXFP6 microscaling, ~9 PFLOPS dense / 18 PFLOPS sparse on B200. Inference focused; **2nd-gen Transformer Engine** auto-scales FP4/FP6.
- **NVLink 5** — 1.8 TB/s/GPU, scales to 576-GPU domains via NVSwitch.
- **Decompression engine** — on-die hardware decompresses Snappy/LZ4/Deflate at line rate; offloads CPU for analytics ETL feeding the GPU.
- **Improved RAS engine** — predictive failure analytics; longer uptime at trillion-param scale.
- **Memory** — B200: 192 GB HBM3e, 8 TB/s.
- **GB200 NVL72** — 72 B200 GPUs + 36 Grace CPUs in one liquid-cooled rack, single 130 TB/s NVLink domain; designed as the unit of scale-up.
- Compute capability 10.0.

## CUDA streams and async gotchas

The **legacy default stream** (NULL stream) is shared by all host threads in a process and **implicit-syncs against all other blocking streams**. Launches on user streams will serialize against it. Symptoms: "I created 4 streams but they run sequentially."

Two fixes:
1. Compile with `nvcc --default-stream per-thread` or `-DCUDA_API_PER_THREAD_DEFAULT_STREAM`. Each host thread gets its own non-blocking default.
2. Create explicit non-blocking streams: `cudaStreamCreateWithFlags(&s, cudaStreamNonBlocking)`.

**Mixing matters**: a library compiled with legacy default and your code per-thread will still sync against legacy stream 0 if either side touches it.

`cudaMallocAsync` / `cudaFreeAsync` (CUDA 11.2+) — stream-ordered allocation; participates in stream graph and CUDA Graphs. Lets you allocate inside captured graphs.

`cudaStreamSynchronize` blocks the host; `cudaEventRecord` + `cudaStreamWaitEvent` lets streams synchronize on the device without host involvement (preferred).

## Memory specifics

| Memory | BW | Capacity |
|---|---|---|
| HBM2e (A100) | 2.0 TB/s | 40/80 GB |
| HBM3 (H100) | 3.35 TB/s | 80 GB |
| HBM3e (H200) | 4.8 TB/s | 141 GB |
| HBM3e (B200) | 8.0 TB/s | 192 GB |

**Fragmentation** — long-running training with variable shapes leaves "swiss cheese" segments. Reserved high but no contiguous slab → OOM despite low allocated. Fix: `PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True` (uses CUDA VMM `cuMemMap`/`cuMemSetAccess`). Caveat: doesn't currently interop cleanly with `ncclMemAlloc`-based allocators — relevant for some FSDP/NCCL VMM paths.

**Unified memory** (`cudaMallocManaged`) — single pointer, page-migrated on access. Useful for prototyping; bad for hot loops (page-fault stalls). Hides OOM until access time.

**Pinned host memory** (`cudaMallocHost`) — required for true async H2D/D2H. Pages cannot be swapped; bound to ~half of total RAM as a safe upper limit.

## Recent changes (CUDA 12.x / Hopper / Blackwell)

- **CUDA 12.0+**: confidential compute, lazy module loading (`CUDA_MODULE_LOADING=LAZY`), Hopper PTX (`sm_90a`).
- **CUDA 12.4–12.6**: Blackwell support (`sm_100`), MXFP4/MXFP6 in cuBLASLt, **Green Contexts** (lightweight contexts for SM partitioning without MIG), graph memory nodes via `cudaMallocAsync` capture.
- **CUDA 12.8**: deprecated experimental cuBLASLt atomic-sync row chunks (removed later); stricter sm_90/sm_100 separation.
- **CUDA 13.x (2025)**: tightened ncu kernel replay; `nvprof` fully unsupported.
- **Driver**: R555+ for full Hopper feature set, R570+ for Blackwell, R590 (Dec 2025) for stable Xid catalog.

## Authoritative references

- [nvidia-smi reference](https://docs.nvidia.com/deploy/nvidia-smi/index.html)
- [DCGM exporter / metrics](https://github.com/NVIDIA/dcgm-exporter)
- [NCCL env vars](https://docs.nvidia.com/deeplearning/nccl/user-guide/docs/env.html), [NCCL tuning blog](https://developer.nvidia.com/blog/understanding-nccl-tuning-to-accelerate-gpu-to-gpu-communication/)
- [Xid error catalog](https://docs.nvidia.com/deploy/xid-errors/index.html)
- [Dynamic page retirement & row remapping](https://docs.nvidia.com/deploy/dynamic-page-retirement/index.html)
- [GPUDirect RDMA](https://docs.nvidia.com/cuda/gpudirect-rdma/)
- [Hopper architecture deep-dive](https://developer.nvidia.com/blog/nvidia-hopper-architecture-in-depth/)
- [Blackwell architecture](https://www.nvidia.com/en-us/data-center/technologies/blackwell-architecture/)
- [PyTorch CUDA semantics & allocator](https://docs.pytorch.org/docs/stable/notes/cuda.html)
- [stas00/ml-engineering NVIDIA debug](https://github.com/stas00/ml-engineering/blob/master/compute/accelerator/nvidia/debug.md)

## Guardrails

Before recommending a non-trivial GPU operational change (NCCL env, MIG/MPS, power cap, allocator config, FP8/FP4 enable):
1. Quote the env var / flag and its current default
2. Cite the official NVIDIA / NCCL / PyTorch doc
3. Make the recommendation conditional on observed evidence (DCGM metrics, Xid log, nsys trace, nvidia-smi topo) — never blanket-tune
4. Verify the GPU generation and driver/CUDA version. Many features gate on Hopper (FP8, TMA), Blackwell (FP4, NVLink5), or driver minimums (R555+ Hopper, R570+ Blackwell)

**Tuning without measurement is worse than defaults.**

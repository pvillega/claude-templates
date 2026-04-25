---
name: dl-training
description: >
  Deep DL-training operational intuition — initialization (Xavier/He, residual scaling,
  Fixup), optimizer choice (SGD+momentum / AdamW / Lion / Sophia / Muon / Schedule-Free),
  weight-decay correctness (decoupled vs L2, exclusion list), LR schedules
  (cosine vs WSD vs OneCycle vs Schedule-Free, warmup math), LR-batch scaling and μP,
  gradient clipping with AMP, mixed precision (FP16 GradScaler vs bfloat16 vs TF32 vs FP8),
  normalization (BN/LN/GN/RMSNorm; PreLN/PostLN/Peri-LN), gradient/NaN forensics,
  augmentation correctness (Mixup/CutMix label math), label smoothing, SWA/EMA,
  DropPath, memory-efficient training, loss-spike skip-and-rewind.
  Load ONLY when the task is about training-time fundamentals — picking optimizer/
  schedule, weight-decay setup, debugging loss spikes/NaN, init schemes, normalization
  choice, mixed precision footguns, or μP transfer. Do NOT load for architecture
  selection, inference/serving, distributed-systems sharding topology, RL dynamics,
  or pure data-pipeline perf — those don't need this skill. Pairs with `pytorch` for
  compile/FSDP/profiler.
  Triggers on: "AdamW", "Lion", "Sophia", "Muon", "Schedule-Free", "weight_decay",
  "decoupled weight decay", "warmup", "cosine_decay", "WSD", "OneCycle", "linear scaling rule",
  "muP", "μTransfer", "gradient_clipping", "clip_grad_norm", "mixed_precision", "bfloat16",
  "GradScaler", "FP8", "transformer engine", "BatchNorm", "LayerNorm", "RMSNorm",
  "GroupNorm", "PreLN", "PostLN", "Peri-LN", "Kaiming", "Xavier", "Fixup",
  "residual scaling", "Mixup", "CutMix", "label_smoothing", "EMA", "SWA",
  "DropPath", "stochastic depth", "loss spike", "spike skip", "NaN gradient".
---

# DL Training Operational Guide

Concise operational pointers for deep-learning training fundamentals where models tend to be shallow.

Assumes you already know backprop, MLPs, common architectures (CNN/transformer), and basic PyTorch. This skill covers the **operational layer** — initialization, optimizer choice, schedule, weight-decay correctness, gradient/NaN forensics, normalization, augmentation, mixed precision, μP, loss-spike forensics — current as of late 2025/early 2026. Pairs with `pytorch` for `torch.compile`/FSDP/profiler.

## When to use

Load when the task is:
- Picking or tuning an optimizer for a new model (CV, transformer, diffusion)
- Choosing/configuring an LR schedule (cosine, WSD, OneCycle, Schedule-Free)
- Diagnosing loss spikes, NaN, or divergence
- Migrating a run from FP32 → BF16/FP8, or AMP-related instability
- Configuring weight-decay parameter groups (bias / norm exclusion)
- Setting gradient clipping for transformers vs RNNs
- Initializing a deep residual stack or ViT
- Adding Mixup/CutMix/label smoothing to an image pipeline
- Standing up large-batch training and choosing LR scaling rule
- Transferring HPs across model widths (μP / μTransfer)
- Configuring SWA or EMA for the final training phase or diffusion
- Memory-budget engineering: activation checkpointing, ZeRO, sequence packing
- PreLN vs PostLN vs Peri-LN, or BN vs GN vs LN vs RMSNorm
- DropPath / stochastic depth on a deep ViT/ResNet

**Do NOT load** for: architecture choice (attention variants, MoE routing, tokenizer), inference/serving, distributed-systems topology, RL-specific dynamics, pure data-pipeline perf.

## Initialization

PyTorch's `nn.Linear` / `nn.Conv2d` default is `kaiming_uniform_(a=sqrt(5))` — historical, **not Kaiming-for-ReLU**. It approximates a wide uniform; bias is `U(−1/sqrt(fan_in), 1/sqrt(fan_in))`. Don't trust it: re-init explicitly.

- **Xavier/Glorot** (`Var = 2/(fan_in+fan_out)`) — tanh/sigmoid/identity.
- **He/Kaiming** (`Var = 2/fan_in`) — ReLU/GELU.
- **Orthogonal** — RNNs and where preserving rotation matters.
- **Residual scaling**: GPT-2 scales output projections of attn and MLP residual paths by `1/sqrt(2L)` (L = block count; the 2 reflects two residual writes per block). Keeps activation variance ~constant with depth. Used by virtually every modern decoder.
- **Fixup** (Zhang et al., 2019): trains 10k-layer ResNets *without* normalization by zero-init the last layer of each residual branch, scaling earlier layers by `L^(−1/(2m−2))`, plus per-branch scalar/bias parameters. For when you intentionally drop norms.
- **Embedding init**: `N(0, 0.02)` is the GPT-2 convention; `0.006 ≈ 1/sqrt(d_model)` for `d_model ≈ 40k`. Tied input/output embeddings inherit init.

## Optimizers

- **SGD+momentum** β=0.9, weight_decay 1e-4. Still SOTA on ImageNet ResNet, mostly anywhere CV throughput matters and BN is in play. Slow on transformers.
- **AdamW** (Loshchilov & Hutter): β1=0.9, β2=0.999 (drop to 0.95 for LLM pretrain — long-horizon variance), ε=1e-8, weight_decay 0.01–0.1. **Decoupled** weight decay: `θ ← θ − lr·(m̂/(√v̂+ε) + λθ)`, NOT L2-in-loss. PyTorch's `Adam(weight_decay=...)` is the L2 (wrong) form for adaptive moments — use `AdamW`.
- **Lion** (Chen et al., 2023): `update = sign(β1·m + (1−β1)·g)`, β1=0.9, β2=0.99. Sign flattens magnitudes, so **LR must be 3–10× smaller than AdamW** and weight_decay 3–10× larger to keep `lr·λ` constant. Half the optimizer-state memory of AdamW (no `v`).
- **Sophia** (Liu et al., 2023): diagonal-Hessian preconditioner estimated every k steps; element-wise clipping bounds the worst-case update. Reports ~2× wall-clock vs AdamW on GPT-2-class. Adoption mixed; sensitive to clip threshold ρ.
- **Muon** (Jordan, 2024 — "MomentUm Orthogonalized by Newton-Schulz"): for hidden 2D matrices only — momentum then Newton-Schulz (5 iters) orthogonalizes the update so no direction dominates. Embeddings/heads/scalars stay on AdamW. ~2× efficient for LLMs in 2025; used in Moonshot/Kimi-class runs and "Distributed Muon" (ZeRO-1 friendly). **Footgun**: matrix LR ≈ 0.02 is *much* higher than AdamW's; weight decay also retuned.
- **Schedule-Free AdamW** (Defazio et al., 2024): no LR schedule; replaces momentum with interpolation+averaging. Won MLCommons AlgoPerf 2024 self-tuning. Useful when training horizon is unknown or one config must serve many durations.

## Weight decay correctness

L2-in-loss adds `λ·‖θ‖²` to objective; gradient becomes `g + 2λθ`. With Adam this is then divided by `√v̂`, so heavily-updated params get *less* effective decay — backwards. Decoupled (AdamW) applies `θ ← θ(1 − lr·λ)` outside the adaptive step.

**Always exclude from decay**: biases, LayerNorm/RMSNorm γ and β, BatchNorm γ/β, position embeddings (often), token embeddings (sometimes — varies). Decaying norm scales pulls them toward zero, killing the affine recovery. Build two param groups: matrices (`p.dim() ≥ 2 and "norm" not in n`) get λ; the rest gets 0.

Common bugs: (1) `Adam` with `weight_decay`, (2) decaying biases, (3) forgetting to scale λ when scaling LR for Lion, (4) decay applied around clipping in the wrong order.

## LR schedules

- **Linear warmup + cosine decay**: LLM/ViT default. Warmup steps 0.5–4% of total (e.g., 2000 of 100k); cosine to 10% of peak. **Why warmup matters for AdamW**: at step 1, `v̂ ~ g²` (high-variance estimate) → updates explode. Warmup gives `v̂` time to stabilize. Without it, transformers diverge; PostLN especially.
- **OneCycle** (Smith): triangular LR up to `max_lr` at ~30% of run, cosine down past initial; momentum runs anti-cyclic (high→low→high). "Super-convergence." Best on shorter CV runs with a fixed budget.
- **WSD (Warmup-Stable-Decay)** (MiniCPM, DeepSeek-style): warmup → long flat → short decay (last 10–20%). Decay can be linear, cosine, exponential, or inverse-sqrt. Lets you fork from the stable plateau with different decay lengths/data mixes — checkpoint reuse for continual training.
- **Trapezoidal** ≈ WSD with linear up + flat + linear down. **Linear-decay-to-zero** simple, slightly worse than cosine but optimum-time-agnostic. **Inverse-sqrt** (original Transformer): now uncommon.

## LR-batch scaling rules

- **Linear scaling** (Goyal 2017): `lr ∝ B`, valid for SGD up to ~8k batch on ImageNet; needs ramp-up warmup to absorb the larger jump. Beyond that breaks → use LARS/LAMB layer-wise rules.
- **Sqrt scaling** (Krizhevsky): `lr ∝ √B`. Theoretically motivated for Adam/adaptive (variance argument); empirically often weaker than linear at moderate scale.
- **μP / μTransfer** (Yang & Hu, 2022): reparametrize so input/output/hidden layers each scale weights, init, and LR by width-dependent factors making feature-update magnitude O(1). Tune HPs on a 40M model, transfer zero-shot to 6.7B+. Increasingly standard in 2024–25 frontier runs (cost saving on HP search). PyPI `mup`. **Footgun**: only stable across *width*; depth/data still need re-tune. Works with AdamW; recipes for Muon emerging.

## Gradient clipping

`torch.nn.utils.clip_grad_norm_(params, max_norm=1.0)` between `loss.backward()` and `optimizer.step()`. Transformers: `max_norm=1.0`. RNNs: 5–10 historically. With AMP+GradScaler, call **`scaler.unscale_(optimizer)` first**, then clip, then `scaler.step(optimizer)` — clipping a scaled gradient is a silent bug.

`clip_grad_value_` (per-element) almost never preferred — kills direction information. `error_if_nonfinite=True` catches NaN/Inf early but raises in the hot path; many trainers prefer detecting via scaler skip events.

## Mixed precision

- **FP16 (AMP)**: range too narrow; needs `torch.cuda.amp.GradScaler` with dynamic loss scale. On overflow, scaler skips the step and halves scale; on N consecutive non-overflows, doubles. Skipped steps mean LR scheduler is now ahead of the optimizer — use `scaler.step(optimizer)` so PyTorch tracks correctly.
- **BF16**: same exponent range as FP32, lower mantissa. **No GradScaler needed** — usually. Default for LLM pretrain on A100/H100. **Silent footgun**: small accumulations (long-sequence loss reduction, layernorm reductions over big d_model) lose precision. Keep reductions / optimizer master-state in FP32; PyTorch AMP-bf16 + FP32 master via `MixedPrecision` in FSDP.
- **TF32**: Ampere+ matmul-only mode; 10-bit mantissa, FP32 range. Enable via `torch.set_float32_matmul_precision('high')` or `torch.backends.cuda.matmul.allow_tf32 = True`. ~Free quality cost, ~2× perf vs strict FP32.
- **FP8** (Hopper+, NVIDIA Transformer Engine): E4M3 fwd, E5M2 bwd; per-tensor delayed scaling. By late 2025 FP8 is production for frontier pretrain (Meta, Microsoft, Google reported 30–40% throughput vs BF16) with no quality regression on most training. **MXFP8 micro-scaling** (Blackwell) reduces calibration footguns. Watch for: scale-factor staleness, FP8 attention Q/K outliers (need outlier protection).

## Normalization

- **BatchNorm**: ε=1e-5, momentum=0.1 (running stat update); **train/eval mode different**. Eval mode uses running mean/var → forgetting to switch to eval mode re-estimates from current batch (catastrophic with B=1). **Fails when B<8**; B=2 has 10%+ ImageNet error vs full BN.
- **LayerNorm**: ε=1e-5, applies per-token across feature dim. Required for transformers (sequence-batch independence). PyTorch `nn.LayerNorm` includes affine γ,β; **γ should not be weight-decayed**.
- **GroupNorm** (Wu & He): default G=32; batch-independent; mainstay of detection/segmentation/video where per-image batches are small.
- **RMSNorm** (Zhang & Sennrich): drops mean centering, only `x / RMS(x) · γ`. Used by Llama, Mistral, Gemma, Qwen, DeepSeek. **7–64% faster than LayerNorm** with no quality loss because residual connections keep activations roughly zero-mean already.
- **PreLN** (`x + Sublayer(LN(x))`) vs **PostLN** (`LN(x + Sublayer(x))`). PostLN is the original Transformer; gradient norms grow with depth → long warmup mandatory and divergence common past ~12 layers. PreLN is gradient-stable but suffers *activation variance growth* with depth → "massive activations" in 2B+ models, FP16 attention overflow. **Peri-LN** (LN before *and* after the sublayer) used in Gemma-2 / OLMo-class to bound both. **NormFormer** adds extra LNs after attention QK and FFN GeLU.

## Gradient explosion / NaN diagnosis

`torch.autograd.set_detect_anomaly(True)` finds the op producing NaN (slow — debug only). Hook `register_full_backward_hook` on suspect modules and dump grad norms.

Track per-step: total grad norm, per-layer grad norm, max activation, attention logit max, loss-scale value.

**Spike templates**:
- Loss flat → spike → recover — data hot batch.
- Progressively rising grad norm before spike — PostLN drift, LR too high.
- Sudden NaN with previous skipped scale — FP16 underflow accumulating.
- Rare spike in BF16 attention with FP16-cast logits — overflow in attn softmax. Pre-softmax clamp or convert QKᵀ to FP32.

Divide-by-zero spots: softmax with `−∞` rows (full-mask token), `logsumexp` across empty groups, RMSNorm with zero input vector, `/ std` in custom norm.

## Augmentation

- **Image**: RandAugment (n=2, m=9 typical), AutoAugment policies, RandomErasing.
- **Mixup**: `x' = λ x_a + (1−λ) x_b`, `y' = λ y_a + (1−λ) y_b`, `λ ~ Beta(α,α)`, α=0.2 (CV) to 0.8 (ViT).
- **CutMix**: pastes a rectangle from `b` into `a`, λ = pasted-area / total → label is interpolated by area.
- **Train-only**: never apply to val/test.
- **Text**: synonym swap, back-translation, span deletion. Be careful with classification labels surviving the swap.
- **Audio**: SpecAugment — time/frequency masks plus time warp on spectrogram.
- **Mixup label math**: with cross-entropy and one-hot, expand to `loss = λ·CE(logits, y_a) + (1−λ)·CE(logits, y_b)` (don't mix tensor *and* call `cross_entropy` — lose precision).

## Label smoothing

`y_smooth = (1−ε)·one_hot + ε/K` with ε=0.1 typical. Improves calibration (ECE lower), slightly *hurts* top-1 by ~0.1–0.3% — accepted tradeoff in production. Compose with Mixup carefully (don't double-smooth: usually drop LS when Mixup is on, or use `nn.CrossEntropyLoss(label_smoothing=0.1)` only).

## SWA / EMA

- **SWA** (Izmailov 2018): cycle LR high+constant during last 25% of training, average snapshots, recompute BN running stats post-hoc with one data pass (`update_bn`). Wider basin → better generalization. PyTorch `torch.optim.swa_utils.AveragedModel`.
- **EMA**: throughout training, `θ_ema ← β θ_ema + (1−β) θ`, β=0.999 (image classif), 0.9999 (large LM, diffusion). Stable Diffusion, Imagen ship EMA weights, not live ones. EMA ≈ low-pass filter; reduces noise from late high-LR updates. Cheaper than SWA; near-identical quality.

## Stochastic Depth / DropPath

Per-block Bernoulli drop with linear schedule `p_l = 1 − (l/L)(1 − p_L)`, `p_L = 0.5` (deep ResNet) to `p_L = 0.9` (small ViT). At inference, scale residual by survival probability. Critical for ViT-Large, ConvNeXt; absent or tiny in ViT-Base. timm `drop_path_rate` arg.

## Memory-efficient training

- **Activation checkpointing** (`torch.utils.checkpoint`): saves ~70% activation memory, ~25% slower. **Selective AC**: checkpoint attn but not MLP (or vice-versa).
- **ZeRO** (DeepSpeed) / **FSDP** (PyTorch): ZeRO-1 shards optimizer state (Muon needs Distributed Muon — vanilla ZeRO-1 incompatible because orthogonalization needs the full matrix), ZeRO-2 + grads, ZeRO-3 + params. Offload to CPU/NVMe if VRAM-bound but PCIe-fed.
- **FlashAttention / SDPA**: PyTorch 2.2+ ships FlashAttention-2 inside `F.scaled_dot_product_attention`; 2.5+ adds CuDNN SDPA tuned for Hopper. `torch.nn.attention.sdpa_kernel` to force a backend; math kernel is the slow fallback.
- **Sequence packing**: concatenate short docs into max-length sequences with per-doc attention masks (block-diagonal). 2–5× tokens-per-step on web pretrain; needs cross-doc-attention masking to avoid leakage.

## Loss-spike forensics

Causes ranked by frequency: (1) data hot batch (unusual token co-occurrence; logit saturation), (2) LR too high after warmup, (3) FP16 underflow → scaler-skip → optimizer/state desync, (4) optimizer-state corruption (NaN propagated into `v̂`), (5) data poisoning / undetected bad doc.

**Skip-and-rewind protocol** (PaLM-style): if `loss > k · rolling_mean`, restore from N-step-old checkpoint, skip the last N batches, replay. Common `k=1.5`, `N=200`. Cheap insurance; standard in 2024+ pretrain stacks. Pair with batch logging for forensic root-cause.

## Recent changes (late 2025 / 2026)

- **Muon** mainstreamed for LLM pretrain matrix params (Distributed Muon for ZeRO-1 cluster training).
- **μP** standard for HP transfer in frontier runs; cuts HP search costs > 90%.
- **FP8** is production for BF16-class quality with ~30–40% throughput; MXFP8 (Blackwell) eases calibration.
- **Schedule-Free AdamW** displacing cosine where horizon is unknown.
- **WSD** preferred for continual pretrain / data-mix forks (DeepSeek, MiniCPM lineage).
- **Peri-LN** seen alongside PreLN at >1B scale to control activation variance.

## Authoritative references

- [AdamW](https://arxiv.org/abs/1711.05101)
- [Lion (Symbolic Discovery)](https://arxiv.org/abs/2302.06675)
- [Sophia](https://arxiv.org/abs/2305.14342)
- [Muon (Jordan)](https://kellerjordan.github.io/posts/muon/), [Distributed Muon](https://arxiv.org/abs/2502.16982)
- [Schedule-Free](https://arxiv.org/abs/2405.15682)
- [μP (Tensor Programs V)](https://arxiv.org/abs/2203.03466), [microsoft/mup](https://github.com/microsoft/mup)
- [Fixup init](https://arxiv.org/abs/1901.09321)
- [Group Normalization](https://arxiv.org/abs/1803.08494)
- [RMSNorm](https://arxiv.org/abs/1910.07467)
- [Linear scaling rule (1-Hour ImageNet)](https://arxiv.org/abs/1706.02677)
- [WSD / MiniCPM](https://arxiv.org/abs/2404.06395)
- [PyTorch SDPA / FlashAttention-2](https://pytorch.org/blog/pytorch2-2/)
- [NVIDIA Transformer Engine (FP8)](https://github.com/NVIDIA/TransformerEngine)
- [Spike No More (LLM stability)](https://arxiv.org/abs/2312.16903)
- [Peri-LN](https://arxiv.org/abs/2502.02732)

## Guardrails

Before recommending a non-trivial training change (optimizer swap, schedule change, weight-decay rewiring, FP8 enable, normalization swap):
1. Quote the parameter and any standard default (β, ε, λ, warmup %)
2. Cite the originating paper or PyTorch doc
3. Make the recommendation conditional on observed evidence (loss-curve, grad-norm trace, scaler skip rate, validation delta) — never blanket-tune
4. Verify hardware/library generation. Many features gate (FP8 on Hopper+, MXFP8 on Blackwell, FlashAttention-2 in PT 2.2+)

**Tuning without measurement is worse than defaults.**

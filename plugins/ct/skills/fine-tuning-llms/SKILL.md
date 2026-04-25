---
name: fine-tuning-llms
description: >
  Deep LLM fine-tuning operational intuition — LoRA/QLoRA hyperparameters and merge
  pitfalls, DPO/IPO/KTO/ORPO/SimPO/GRPO selection and tradeoffs, RLHF→GRPO transition,
  chat-template footguns, completion-only loss masking, sequence packing with
  block-diagonal masks, eval contamination and decontamination, catastrophic forgetting
  mitigation, LR magnitudes and schedules (cosine vs WSD), tool ecosystem (TRL, PEFT,
  axolotl, unsloth, llama-factory, torchtune).
  Load ONLY when the task is about post-training open-weights models, picking among
  preference-optimization methods, configuring LoRA/QLoRA, debugging training that
  "won't follow chat format", suspecting eval contamination, or choosing a fine-tuning
  toolchain. Do NOT load for inference/serving (use llm-inference-serving), prompt
  engineering of closed APIs, RAG pipelines, embedding training, or pretraining from
  scratch — those don't need this skill.
  Triggers on: "LoRA", "QLoRA", "PEFT", "lora_alpha", "target_modules", "merge_and_unload",
  "DPO", "IPO", "KTO", "ORPO", "SimPO", "GRPO", "PPO", "RLHF", "SFT", "TRL",
  "SFTTrainer", "DPOTrainer", "GRPOTrainer", "axolotl", "unsloth", "llama-factory",
  "torchtune", "bitsandbytes", "nf4", "double_quant", "paged_adamw", "chat template",
  "apply_chat_template", "completion_only_loss", "DataCollatorForCompletionOnlyLM",
  "sequence packing", "cu_seqlens", "reward model", "KL penalty", "beta",
  "contamination", "MMLU contamination", "catastrophic forgetting", "WSD schedule".
---

# LLM Fine-Tuning Operational Guide

Concise operational pointers for deep post-training of open-weights LLMs.

Assumes you already know what an LLM is, basic transformer training, and HuggingFace `Trainer`. This skill covers the **operational layer** — the parts models tend to gloss over: LoRA mechanics and merge pitfalls, the preference-optimization family (DPO/IPO/KTO/ORPO/SimPO/GRPO) and when each fits, chat-template silent killers, packing, contamination, the toolchain (TRL/PEFT/axolotl/unsloth/llama-factory/torchtune) — current as of late 2025/early 2026.

## When to use

Load when the question is about:
- Fine-tuning open-weights model (Llama, Qwen, Mistral, Gemma, DeepSeek)
- Picking among LoRA / QLoRA / full FT given a VRAM budget
- Choosing among DPO / IPO / KTO / ORPO / SimPO / GRPO for preference / reasoning post-training
- Reproducing R1-style reasoning training with verifiable rewards
- Configuring `SFTTrainer` / `DPOTrainer` / `GRPOTrainer` in TRL
- Setting `r`, `lora_alpha`, `target_modules`, `lora_dropout` for a new adapter
- Debugging "trained but won't follow chat format" (template mismatch)
- Sequence packing with FlashAttention block-diagonal masks
- Catastrophic forgetting after task-specific FT
- Suspect benchmark contamination on MMLU / GSM8K / HumanEval
- Designing eval beyond MMLU (Arena-Hard, AlpacaEval-LC)
- Picking an LR schedule (cosine vs WSD) and base LR magnitude
- Computing effective batch size for DPO / GRPO stability
- Choosing axolotl vs unsloth vs llama-factory vs torchtune
- Merging LoRA adapter back into a quantized base model

**Do NOT load** for: pure inference / serving / vLLM tuning, prompt engineering of frontier closed models, RAG pipelines, embedding model training, tokenizer training, pretraining from scratch.

## LoRA mechanics and knobs

LoRA freezes base, learns `B @ A` of rank `r`, applied as `delta = (alpha/r) * B A x`. The scale `alpha/r` is the load-bearing knob — doubling `r` without doubling `alpha` halves the effective update.

- **Convention**: `lora_alpha = 2r`. PEFT defaults `r=8, alpha=8`; community SFT default `r=16, alpha=32`; for larger behavioral shifts `r=64, alpha=128`. Past `r=128` rarely beats full FT and erodes the parameter savings.
- **`target_modules`**: classic LoRA hits attention only — `q_proj/k_proj/v_proj/o_proj`. Modern recipes target **all linear layers** including `gate_proj/up_proj/down_proj`. PEFT shortcut: `target_modules="all-linear"`. The QLoRA paper showed all-linear is required to hit full-FT parity.
- **`lora_dropout`**: 0.0 with ≥500 examples; 0.05 light reg; 0.1 only for tiny datasets / heavy overfit.
- **`bias="none"`** is standard; `"lora_only"` adds learnable bias on adapted layers.
- **`modules_to_save`** for `embed_tokens` / `lm_head` when training new tokens.

**Merge tradeoffs**: `model.merge_and_unload()` collapses adapter into base for zero-overhead inference but is permanent. Keep separate when serving multiple LoRAs (one base, hot-swap adapters).

**QLoRA merge footgun**: training under QLoRA dequantizes nf4 → bf16 for the forward pass, so the adapter is fit to **bf16 weights**. Merging back into the **nf4 4-bit checkpoint** produces a precision mismatch and silent quality regression. Fix: dequantize the base to bf16, merge, then re-quantize with **AWQ/GPTQ** (not nf4).

## QLoRA and 4-bit training

```
BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4",
                   bnb_4bit_use_double_quant=True,
                   bnb_4bit_compute_dtype=torch.bfloat16)
```

- **NF4** is information-theoretically optimal for normally distributed weights and matches bf16 quality; FP4 lags ~1pp.
- **`double_quant`** quantizes the per-block constants too, saving ~0.4 bits/param (~3 GB on a 65B).
- **`paged_adamw_8bit`** uses NVIDIA unified memory to spill optimizer state to host RAM — prevents OOM on long-sequence steps but costs PCIe bandwidth on spikes.

**Footgun**: at long context, **activation memory dominates** — quantizing weights does nothing for it. Use gradient checkpointing (`use_reentrant=False`), FlashAttention 2/3, and sequence packing instead. bitsandbytes ≥ 0.43 supports FSDP + 4-bit; older versions force DDP only. **Compute dtype must match the optimizer expectation** — mixing fp16 compute with `paged_adamw_32bit` yields silent NaNs on Llama 3 (use bf16 throughout).

## DPO and the preference family

DPO loss: `-log σ(β · (log π(y_w|x)/π_ref(y_w|x) − log π(y_l|x)/π_ref(y_l|x)))`. **`β` (TRL default 0.1)** is the implicit KL coefficient; larger β → stays closer to ref, smaller β → more aggressive. Practical range 0.05–0.5; try 0.01 if reward/margin is flat (often combined with bumping LR to 5e-7).

DPO needs `ref_model` resident — second forward pass per step, ~doubles VRAM. With LoRA, TRL skips `ref_model` and uses the base (zero-adapter) as implicit ref.

- **IPO** (Azar et al.): replaces log-sigmoid with squared-error penalty so it can't collapse on near-deterministic preferences; converge without early stopping. Same `β` slot interpreted as `τ` regularizer.
- **KTO** (Ethayarajh, prospect theory): pointwise — needs only `desirable / undesirable` labels, not pairs. Gold for sparse / one-sided feedback (thumbs up/down logs). Asymmetric loss: penalty for bad > reward for good.
- **ORPO** (Hong, 2024): single-stage SFT + odds-ratio preference penalty in one objective, **no reference model**. One model in memory (vs DPO's 2, PPO's 4). `λ` ≈ 0.1–1.0. Best for from-base alignment without an SFT phase.
- **SimPO** (Princeton, NeurIPS 2024): length-normalized average log-prob as implicit reward, **no reference model**, plus margin term `γ`. Often beats DPO on AlpacaEval2. Sensitive to `β` (2.0–2.5) and `γ` (0.5–1.5).
- **GRPO** (DeepSeekMath, used for R1, Qwen 2.5/3 reasoning): for each prompt sample `G` answers (typical `num_generations=8`), compute group-normalized advantage `A_i = (r_i − mean(r))/std(r)`. **Drops the value head entirely.** Memory: 3 models (policy, ref, reward — and reward is often a verifier script, so effectively 2 nets). **DAPO** (early 2025) drops the KL term for verifiable-reward reasoning.

**Selection**: DPO = solid baseline with curated pairs; IPO = noisy/deterministic prefs; KTO = pointwise logs; ORPO = skip SFT, save memory; SimPO = squeeze AlpacaEval2 cheaply; GRPO = math/code/reasoning with rule-based rewards.

## PPO and why GRPO won

Classic RLHF: SFT → reward model (Bradley-Terry on preference pairs, frozen scalar head on SFT base) → PPO with clipped surrogate `min(r·A, clip(r, 1−ε, 1+ε)·A)` plus per-token KL against ref. **Four models resident**: policy, ref, reward, critic (value head). `init_kl_coef=0.2`, adaptive. Notoriously unstable — reward hacking, mode collapse, length explosion.

GRPO removed the critic by using group statistics for the baseline: ~40–50% memory cut, frees GPU for larger policies (how DeepSeek RL'd a 671B MoE). For tasks with verifiable answers (math, code, format), **GRPO + rule-based reward is now the default**.

## Chat templates — the silent killer

`tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)` is the only safe way to render training and inference inputs. ChatML (`<|im_start|>role\n...<|im_end|>`) for Mistral/Qwen lineage; Llama 3 uses `<|begin_of_text|><|start_header_id|>role<|end_header_id|>\n\n...<|eot_id|>`. Each tokenizer ships its own Jinja in `tokenizer.chat_template`.

Footguns:
- Training with one template, serving with another → distribution shift, model emits wrong special tokens, loops.
- Llama 3.1 had a known bug where `apply_chat_template` always added the generation prompt regardless of `add_generation_prompt=False`; fixed upstream but stale in some unsloth bnb-4bit mirrors.
- `return_assistant_tokens_mask=True` is buggy on tiktoken-based Llama 3 tokenizers — affects completion-only masking.
- Pad and EOS often the same token; if the model never sees EOS during training (left-padding for batch + ignore_index), it never learns to stop.

## Loss masking and packing

**Completion-only**: set prompt token labels to `-100` so CrossEntropy ignores them. TRL `SFTTrainer` does this automatically when `completion_only_loss=True` on prompt-completion datasets, or via `DataCollatorForCompletionOnlyLM(response_template=...)`. Training on the full sequence (prompt included) hurts instruction-following — gradient spent echoing inputs the model already perfectly conditions on.

**Sequence packing**: concatenate examples up to `max_seq_length` to remove padding waste (typically 30–50% of tokens). Naive packing is **wrong** — attention bleeds across examples. Solution: FlashAttention 2's variable-length API (`flash_attn_varlen_func`) takes `cu_seqlens` (cumulative lengths) and applies a block-diagonal mask in `O(Σ s_i²)` instead of `O((Σ s_i)²)`. TRL `SFTConfig(packing=True, packing_strategy="ffd")` and unsloth's "uncontaminated packing" both wire this correctly. Insert EOS between concatenated examples or the model learns documents flow into each other.

## Eval contamination and decontamination

GPT-3 set the n-gram overlap convention at 13-grams; standard since. n-gram is necessary but not sufficient — paraphrases, translations, and number swaps slip past. **LLM-judge decontamination** (Yang et al.) catches more. Removing contaminated GSM8K examples drops some models' accuracy ~13pp.

The HF Open LLM Leaderboard had repeated contamination scandals (2023–24); v2 moved to MMLU-Pro, GPQA, MUSR, MATH-Lvl5, IFEval, BBH precisely because v1 saturated and leaked. **Treat MMLU/GSM8K/HumanEval scores from any 2024+ release as unreliable absolute** — useful only as relative deltas on your own held-out splits.

For new evals: **GPQA-Diamond, AIME, LiveCodeBench (rotating), SWE-bench Verified, Arena-Hard-v0.1**.

## Forgetting, schedules, batch sizes, judges

**Catastrophic forgetting** signs: MMLU drops 3–10pp after task FT, refusal patterns shift, chat format degrades. Mitigations:
1. **Replay** — mix 5–20% pretraining/instruct corpus into FT data
2. **Lower LR** — strongest single lever
3. **LoRA over full FT** — keeps base frozen by construction
4. **EWC / L2-SP** — penalize drift
5. For RL specifically, **KL to ref** is the regularizer

**LR magnitudes** (community defaults, late 2025):
- LoRA / QLoRA SFT: 1e-4 to 5e-4 (try 2e-4)
- Full FT SFT: 5e-6 to 5e-5 (try 2e-5; bf16 Adam)
- DPO LoRA: 5e-7 to 5e-6
- DPO full: 5e-7
- ORPO: 5e-6 to 8e-6
- GRPO: 1e-6 to 5e-6

**Schedules**: cosine with 3–10% warmup is the safe default. Linear is fine for short FT. **WSD** (warmup-stable-decay) — constant LR + late decay — is now competitive; better when total step count isn't fixed up front. **Decay-to-zero (D2Z)** can save up to 60% pretraining compute vs cosine-10×. Constant works for DPO (small step counts).

**Effective batch size** = `per_device_train_batch_size × gradient_accumulation_steps × DP world`. DPO/PPO/GRPO are batch-size sensitive — under-batched DPO (effective < 32) collapses to noise. Target effective BS 64–128 for DPO, 128–512 for PPO/GRPO. With grad accum, ref-model forwards still happen per micro-batch — VRAM cost stays.

**LLM-judge bias**: AlpacaEval favors longer outputs — use **AlpacaEval-LC** (length-controlled) or **Arena-Hard** which stratifies. Position bias (first answer wins ~3–5%), self-enhancement (judge prefers own family), verbosity, formatting (markdown vs plain). Mitigations: pairwise with order-swap, hidden-CoT judge, multi-judge ensembles, length normalization in the prompt. Reward-model overfit shows as reward hacking; hold out fresh preference set, watch judge agreement drop.

## Tools — where each wins

- **TRL** (HF): canonical reference impls of SFT/DPO/GRPO/PPO/KTO/ORPO/CPO/online-DPO. When you want trainer code that matches papers.
- **PEFT** (HF): LoRA/DoRA/IA3/OFT primitives; usually a dependency.
- **bitsandbytes**: 4/8-bit and paged optimizers; FSDP-compat from 0.43+.
- **axolotl**: YAML-driven, all the recipes (FSDP/DeepSpeed/QAT, GRPO, sequence parallel) — production at scale, beginner on-ramp. v0.8+ is the maturity point.
- **unsloth**: single-GPU king. Custom Triton fused RoPE+MLP kernels, 2–3× faster than axolotl on a 4090, 30–90% less VRAM. Supports 4B model on 3.9 GB. MoE training 12× faster (2026 release). **No multi-node.**
- **llama-factory**: web UI wrapper, uses unsloth backend; fastest path for non-engineers.
- **torchtune**: pure-PyTorch, deep customization, scales clean with FSDP + PT 2.5 compile; smaller model zoo (Meta-leaning).

Sequencing: prototype on unsloth single-GPU → scale on axolotl multi-GPU/multi-node → rebuild in torchtune for surgical PyTorch control.

## Recent changes (2025–2026)

- **GRPO replaced PPO** as the default RL post-training algorithm; **DAPO** drops KL entirely for verifiable rewards. Anchored by DeepSeek R1 and Qwen 2.5/3 reasoning lines.
- **ORPO and SimPO** reached production adoption — single-model, single-stage alignment is the new norm for resource-constrained shops.
- TRL `GRPOTrainer` shipped with multi-reward, async reward functions, vLLM-backed sampling.
- Unsloth fused-kernel + uncontaminated packing landed mid-2025 (~3× throughput).
- Axolotl v0.8 added QAT, sequence parallelism, full reward modeling.
- **HF Open LLM Leaderboard v2** retired contaminated benchmarks.
- WSD recognized as competitive with cosine; D2Z saves significant compute.

## Authoritative references

- [TRL DPOTrainer](https://huggingface.co/docs/trl/main/en/dpo_trainer), [GRPOTrainer](https://huggingface.co/docs/trl/grpo_trainer), [SFTTrainer](https://huggingface.co/docs/trl/sft_trainer)
- [PEFT LoRA conceptual guide](https://huggingface.co/docs/peft/main/en/conceptual_guides/lora)
- [HF 4-bit / QLoRA](https://huggingface.co/blog/4bit-transformers-bitsandbytes)
- [DeepSeekMath (GRPO origin)](https://arxiv.org/abs/2402.03300)
- [SimPO paper](https://arxiv.org/pdf/2405.14734)
- [HF chat templating docs](https://huggingface.co/docs/transformers/main/en/chat_templating)
- [Packing + FlashAttention](https://arxiv.org/abs/2407.09105)
- [Unsloth 3× faster + packing](https://docs.unsloth.ai/new/3x-faster-training-packing)
- [Don't merge LoRA into 4-bit (Kaitchup)](https://kaitchup.substack.com/p/dont-merge-your-lora-adapter-into)

## Guardrails

Before recommending a non-trivial fine-tuning change (LoRA rank, β, schedule, packing strategy, RL algorithm):
1. Quote the parameter and its current default in the relevant trainer
2. Cite the TRL / PEFT / paper section supporting the claim
3. Make the recommendation conditional on observed evidence (eval delta, KL trajectory, judge agreement) — never blanket-tune
4. Verify the toolchain version. Many defaults shifted (TRL `completion_only_loss`, Axolotl QAT in v0.8, unsloth uncontaminated packing mid-2025)

**Tuning without measurement is worse than defaults.**

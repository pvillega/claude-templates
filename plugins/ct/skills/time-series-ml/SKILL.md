---
name: time-series-ml
description: >
  Deep time-series ML operational intuition — walk-forward / rolling-origin CV with
  correct gap, temporal-leakage audit (future regressors, rolling-stat shift,
  bidirectional fill), ADF+KPSS stationarity decision matrix and differencing,
  multi-seasonal decomposition (STL/MSTL) and Fourier features, direct-vs-recursive-vs-
  DirRec multi-step, probabilistic forecasting (pinball, CRPS, conformal MAPIE/EnbPI),
  hierarchical reconciliation (BU/TD/MinT), foundation models 2024–2026 (Chronos-2,
  TimesFM 2.5, MOIRAI 2.0, Toto, Lag-Llama), neural architectures (N-BEATS/N-HiTS/TFT/
  PatchTST/iTransformer/DLinear), MASE-vs-MAPE, drift detectors (ADWIN/Page-Hinkley).
  Load ONLY when the task is forecasting / time-series — designing CV under temporal
  ordering, choosing local-vs-global modeling, selecting a foundation model vs tuned
  baseline, configuring probabilistic intervals, hierarchical reconciliation, or drift
  monitoring. Do NOT load for general supervised tabular ML (use `classical-ml-pitfalls`),
  causal inference / DiD, LLM token sequences, recommender sequences, or survival
  analysis — those don't need this skill.
  Triggers on: "forecasting", "time series", "walk-forward", "rolling-origin",
  "TimeSeriesSplit", "ExpandingWindowSplitter", "SlidingWindowSplitter", "temporal leakage",
  "lag features", "ARIMA", "Prophet", "STL", "ADF", "KPSS", "MASE", "pinball loss",
  "CRPS", "quantile forecast", "conformal prediction", "Chronos", "Chronos-2",
  "TimeGPT", "TimesFM", "MOIRAI", "Toto", "Lag-Llama", "N-BEATS", "N-HiTS",
  "TFT", "PatchTST", "iTransformer", "DLinear", "hierarchical reconciliation",
  "MinT", "concept drift", "ADWIN", "Page-Hinkley", "statsforecast", "mlforecast",
  "neuralforecast", "sktime", "darts".
---

# Time-Series ML Operational Guide

Concise operational pointers for deep time-series and forecasting work where models tend to be shallow.

Assumes you already know what a time series is, basic ARIMA/ETS, and supervised ML. This skill covers the **operational layer** — walk-forward CV correctness, leakage vectors, stationarity tests, multi-seasonal decomposition, multi-step strategy, probabilistic + conformal intervals, hierarchical reconciliation, the 2024–2026 foundation-model landscape, neural architectures with DLinear as the bar — current as of late 2025/early 2026.

## When to use

Load when the task is:
- Designing a CV scheme for autoregressive / lag-feature pipelines
- Deciding `gap` in `TimeSeriesSplit` to avoid leakage between fold boundary and lag horizon
- Choosing among `statsforecast.cross_validation`, `mlforecast`, sktime splitters, sklearn `TimeSeriesSplit`
- Picking direct vs recursive vs DirRec multi-step strategy for a horizon `h`
- Picking a probabilistic head (quantile, distribution, conformal) for prediction intervals
- Deciding whether to fit a foundation model zero-shot, fine-tune, or train a global supervised model
- Auditing a feature pipeline for future-target / future-regressor / global-normalization leakage
- Choosing differencing order `d`/`D` after ADF+KPSS
- Modelling multi-seasonality (intraday + weekly + yearly) via Fourier or Prophet
- Hierarchical reconciliation (BU/TD/MinT) over a product/store/region tree
- Selecting a metric — when MAPE is broken, when MASE is required
- Setting up online drift monitors (ADWIN, Page-Hinkley) and refit cadence
- Building anomaly detectors over residuals from STL or a forecast model
- Comparing a neural model against a `seasonal_naive` skill-score benchmark before claiming a "win"

**Do NOT load** for: general supervised tabular ML (rows i.i.d.; use `classical-ml-pitfalls`), causal inference / DiD / synthetic control, LLM text generation, recommender / sessionised event sequences, survival analysis.

## Walk-forward CV — corrections most pipelines miss

`sklearn.model_selection.TimeSeriesSplit(n_splits=5, max_train_size=None, test_size=None, gap=0)`. **The footgun: `gap=0` by default.** If features include `lag_k` of the target (or rolling stats with window `w`), the test fold uses targets the training fold's last rows already saw as features. **Set `gap` ≥ max(`lag_horizon`, `rolling_window`)** or, for direct-h forecasting, `gap = h − 1`. Without `test_size`, fold size = `n_samples // (n_splits + 1)`.

`sktime.split.ExpandingWindowSplitter(fh, initial_window, step_length)` grows train each fold; `SlidingWindowSplitter` keeps it fixed (better when distribution drifts). `fh` is a `ForecastingHorizon` — relative or absolute. Both accept `step_length < len(fh)` to overlap test windows.

`statsforecast.cross_validation(df, h, n_windows, step_size, refit)` — cutoffs `cutoff_max = T − h`, `cutoff_min = cutoff_max − (n_windows − 1)·step_size`. `refit=False` trains once at earliest cutoff; `refit=True` per window; `refit=k` every k windows. For neural / global models with expensive fits use `refit=False` early, then a final `refit=1` rerun for headline numbers. `step_size = h` non-overlapping; `step_size = 1` true rolling-origin.

mlforecast uses the same `cross_validation` API; the recursive feature builder will silently use future rows for `expanding_mean` etc. unless you pass `lag_transforms` (lag-only).

## Temporal leakage vectors (audit checklist)

(a) **Future regressors at predict time** — exogenous `X` must be known at the cutoff (calendar, promotions yes; weather forecasts only with the same lead time). statsforecast/neuralforecast call these `futr_exog_list`; if a column is unknown at horizon, declare `hist_exog_list`.
(b) **Rolling stats on full series** — compute `pandas.Series.rolling(w).mean().shift(1)` not `.rolling(w).mean()`. **The `shift(1)` is the leakage fix everyone forgets.**
(c) **Target encoding using future labels** — encode using `expanding(min_periods=...).mean().shift(1)`.
(d) **Normalization fit on full series** — `StandardScaler.fit(y)` on the entire series leaks variance from test; fit per-train-fold. NeuralForecast/MOIRAI handle with per-window `scaler_type='standard'/'robust'/'identity'`.
(e) **Imputation with bidirectional fill** — `bfill`/interpolation across the cutoff. Use forward-only.

## Stationarity — ADF+KPSS decision matrix, differencing

- `statsmodels.tsa.stattools.adfuller`: H0 = unit root (non-stationary). Reject p<0.05 → "stationary".
- `statsmodels.tsa.stattools.kpss(regression='c'|'ct')`: H0 = stationary. Reject p<0.05 → "non-stationary". **Opposite direction.**
- **Combined matrix**:
  - ADF reject + KPSS not reject → stationary; `d=0`.
  - ADF not reject + KPSS reject → unit root; difference once, retest; ARIMA `d≥1`.
  - Both reject → trend-stationary; **detrend** (regress on `t`), don't difference.
  - Neither rejects → undetermined; usually difference and proceed.
- **Seasonal differencing** `D` for season `m`: `y_t − y_{t−m}`. For monthly data `m=12`. ARIMA(p,d,q)(P,D,Q)_m. Use `nsdiffs` (Canova-Hansen / OCSB) for `D`, `ndiffs` for `d` — `pmdarima.utils` and `statsforecast.arima.AutoARIMA` both expose this.
- Box-Cox stabilises variance (positive series only); log is `λ=0`. `scipy.stats.boxcox` returns optimal `λ`. Invert before scoring.

## Seasonality, multi-seasonal, holidays

- **`STL(period, seasonal=7, robust=True)`** (`statsmodels`) — robust to outliers; period must be odd ≥3.
- **MSTL** (`statsforecast.MSTL` with `season_length=[24, 24*7]`) for multi-seasonal data (daily-with-weekly hourly). Beats classical decompose.
- **Fourier features**: `sin(2πk·t/P), cos(2πk·t/P)` for `k=1..K`. **Prophet defaults**: yearly K=10, weekly K=3, daily K=4. Higher K → more wiggle, more overfitting. For NeuralForecast/mlforecast use `mlforecast.target_transforms.Differences` and pass calendar Fourier columns as `static_features` or `dynamic_features`.
- **Prophet** — `changepoint_prior_scale` (default 0.05) controls trend flexibility; reduce to 0.001 for stiff, raise to 0.5 for noisy. `n_changepoints=25` over the first 80% of history. `seasonality_mode='additive'|'multiplicative'`. Holiday DataFrame with `holiday`, `ds`, optional `lower_window`, `upper_window`. Battle-tested but maintained at low velocity; **NeuralProphet** (PyTorch) adds AR + lagged covariates and is the contemporary alternative.

## Direct vs recursive vs DirRec

- **Recursive**: one model, feed `ŷ_{t+1}` back as input for `t+2..t+h`. Errors compound; unbiased only when `f` is linear and correctly specified (Hyndman 2014). Library default in `mlforecast.MLForecast`.
- **Direct**: train `h` separate models, one per step. Avoids error compounding, no inter-step coherence, scales poorly in `h`. NeuralForecast does direct by default (output head sized `h`); statsforecast `MFLES`, `Theta`, `AutoARIMA` are recursive.
- **DirRec / rectify**: predict `ŷ_{t+1}`, append, retrain, repeat. Best of both at training cost. `darts.models.RegressionModel(multi_models=True, ...)` exposes the choice.
- **Multi-output (MIMO)**: single model emits the full vector. NeuralForecast (NHITS, PatchTST, iTransformer) is MIMO.

## Probabilistic forecasting & conformal

- **Quantile head**: train with **pinball loss** `L_τ(y, ẑ_τ) = max(τ(y−ẑ_τ), (τ−1)(y−ẑ_τ))`. NeuralForecast: `loss=DistributionLoss('Normal'|'StudentT'|'NegativeBinomial')` or `loss=MQLoss(quantiles=[0.1,0.5,0.9])`. Coverage of the 80% interval should be ≈80% on holdout — measure it (MIS / interval coverage). **Calibration ≠ point accuracy**; a model with worse RMSE may have well-calibrated 95% PIs and be more useful for inventory.
- **CRPS** = `∫(F̂(z) − 𝟙{y ≤ z})² dz`; for an ensemble it's the average of `|x_i − y| − 0.5·|x_i − x_j|`. CRPS reduces to MAE at the median; pinball loss summed over a dense quantile grid approximates 2·CRPS.
- **Conformal prediction (split / EnbPI)**: MAPIE 1.x exposes `MapieTimeSeriesRegressor` with **EnbPI** (Xu & Xie 2021) — bootstrap residuals, build PIs with approximately marginal coverage `1−α` without distributional assumptions. **Exchangeability is violated** in TS; use re-weighted / adaptive variants (ACI, AgACI). 2025: NeurIPS paper on conformal under change points; arXiv 2511.13608 is the current "gentle intro." TimeGPT uses split conformal under `level=[80,95]`.

## Local vs global, hierarchical reconciliation

- **Local**: one model per series (ARIMA, ETS, Theta). Strong on short, well-behaved series; collapses over thousands of items.
- **Global**: one model across all series with series-id embedding (mlforecast LightGBM, NeuralForecast). M5 finding: top 50 used LightGBM globally; ES benchmark beaten by ~7.5% of teams, only ML approaches won. M4 winner was ES-RNN hybrid (Smyl), 2nd was XGBoost stacking — global beats local at scale.
- **Hierarchical reconciliation** when series sum to higher levels. `Nixtla/hierarchicalforecast`: `BottomUp`, `TopDown(method='proportions'|'forecast_proportions')`, `MiddleOut`, `MinTrace(method='ols'|'wls_var'|'mint_shrink')`, `ERM`. **MinT (`mint_shrink`)** uses residual covariance — minimum-variance unbiased reconciliation, generally beats BU/TD on real data (Wickramasuriya, Athanasopoulos, Hyndman 2019). Probabilistic coherent: `BootstrapReconciler`, `Normality`, `PERMBU`.

## Foundation models 2024–2026

| Model | Architecture | Size | Niche |
|---|---|---|---|
| **Chronos / Chronos-Bolt** (Amazon) | T5 enc-dec, value tokenization via quantile binning | Tiny 9M → Large 710M; Bolt 250× faster, 20× less mem | Univariate zero-shot; Bolt-Base 205M beats original Chronos-Large |
| **Chronos-2** (Oct 2025, arXiv 2510.15821) | 120M encoder-only, alternating time/group attention | 120M | **Multivariate joint forecasting + covariates**; tops GIFT-Eval late 2025 |
| **TimeGPT** (Nixtla) | Closed API; direct multi-step, conformal PIs | — | `level=` PIs; zero-shot + fine-tune (`finetune_steps`, `finetune_loss`, `finetune_depth`); anomaly endpoint |
| **TimesFM** (Google) | Decoder-only | 200M; v2.5 (Sep 2025) **16K context**, native probabilistic head | Held #1 GIFT-Eval until Chronos-2 |
| **MOIRAI** (Salesforce) | Masked encoder, multi-patch, any-variate attention, mixture distribution head | LOTSA 27B obs | MoE adds sparse experts; **MOIRAI 2.0** (Nov 2025) decoder-only, multi-token prediction |
| **Lag-Llama** | Decoder-only on lag features (Feb 2024) | open | **No exogenous support** — limits practical use |
| **Toto** (Datadog) | 151M, Student-t mixture head, factorised attention | 151M | SOTA on Datadog **BOOM** (350M obs, 2807 series); competitive on GIFT-Eval/LSF; Apache 2.0 |
| **Moment** (CMU, 2024) | T5-style multi-task | — | Forecast/classify/impute/anomaly |

**Practical**: zero-shot foundation models beat seasonal-naive on heterogeneous, low-volume, no-history series. They typically **lose to a tuned global LightGBM/NHITS** on a single rich domain with adequate history (M5-style). **Always benchmark against `SeasonalNaive` and `AutoETS` before celebrating.**

## Neural architectures — what each is for

- **N-BEATS** (Oreshkin 2020) — pure MLP residual stacks, "interpretable" trend + seasonality basis. Strong univariate baseline; **no covariates**.
- **N-HiTS** (Challu 2022) — multi-rate via MaxPool on input + hierarchical interpolation on output → cheaper long horizon, ~25% lower MSE than Informer at 50× speed. Default for long-h univariate in NeuralForecast.
- **TFT** (Lim 2019) — variable selection per input type (static, past-known, future-known), LSTM seq2seq, multi-head interpretable attention, quantile head. Use when you have rich heterogeneous covariates and need feature attributions.
- **PatchTST** (Nie 2022, ICLR 2023) — channel-independent + 16-token patches → ~21% MSE reduction vs prior transformers on ETT/Traffic/Weather long-horizon.
- **iTransformer** (Liu 2024) — inverts the axis: each *variate* is a token, attention is across variates. Strong on multivariate where cross-series structure matters.
- **DLinear** (Zeng 2022, AAAI 2023) — series decomposition + two linear layers. Beat SOTA transformers (FEDformer, Autoformer, Informer) by 25–40% MSE on long-horizon multivariate. **Still the bar**: if your transformer doesn't beat DLinear, you have a paper, not a model. PatchTST and iTransformer are the two architectures that consistently do.

## Evaluation metrics — what's broken

- **MAPE**: undefined at `y=0`, asymmetric (over-forecast penalised more in percentage terms), incentivises low forecasts. Avoid for intermittent demand.
- **sMAPE**: bounded [0, 200%] but still asymmetric; two definitions in the wild (M3 vs M4) — quote which.
- **MASE** (Hyndman & Koehler 2006): `mean(|e_t|) / mean(|y_t − y_{t−m}|)` over training, where `m` is seasonality (`m=1` non-seasonal). Scale-free, defined unless series constant, **MASE<1 ⇔ beats seasonal-naive**. Default reporting metric for forecasting comps (M4, M5, GIFT-Eval).
- **RMSE**: scale-dependent, sensitive to outliers; pair with MAE.
- **WAPE / WMAPE**: `Σ|e_t| / Σ|y_t|` — preferred over MAPE for retail.
- **Skill score**: `1 − metric_model / metric_baseline`; baseline is `SeasonalNaive`. Positive = win, negative = lost to naive.
- **Pinball loss / CRPS** for probabilistic; **MIS** (Mean Interval Score, Gneiting-Raftery) for prediction intervals — reports both width and coverage.

## Concept drift & refit cadence

- `river.drift.ADWIN(delta=0.002)` — adaptive window, statistical guarantees, slowly adapts.
- `river.drift.PageHinkley(min_instances=30, delta=0.005, threshold=50, alpha=1−1e-4)` — cheaper, lowest RAM, often the most reliable in 2025 comparative studies.
- KSWIN as a non-parametric alternative.

**Operational pattern**: monitor `MAPE_t` over a sliding 7-day window of 1-step residuals; trigger retrain if window MAPE > 1.5× training MAPE for 3 windows in a row, or any drift detector fires. Refit cadence guidance: daily forecasts → weekly refit; hourly → daily incremental fit; minute-level → online incremental (`river`, `statsforecast` with `refit=1`).

## Anomaly detection in TS

- **STL residuals + 3σ bands** — fast, interpretable, weak on heteroscedastic noise; use IQR/MAD on residuals.
- **Isolation Forest / Extended IForest** on residuals — handles multivariate, struggles with seasonality unless deseasonalised first.
- **LSTM-AE** — reconstruction loss as score; needs labelled anomalies for threshold calibration; brittle to drift.
- **Prophet residuals** — built-in PIs become anomaly bounds; trend changes register as anomalies. Use `add_seasonality(prior_scale=...)` and increase `changepoint_prior_scale` to absorb regime shifts.
- **TimeGPT `detect_anomalies`** — conformal residuals, zero-shot. Toto/Chronos-2 likewise expose forecast-residual anomaly scoring.

**Footgun**: a true anomaly during a seasonal peak gets masked by the seasonal component; always detrend+deseasonalise *before* scoring, and inspect the seasonal component separately for changepoints.

## Recent changes (2024–2026)

- **Foundation models** hit production: Chronos-Bolt (Aug 2024), TimesFM 1.0 (Feb 2024) → 2.5 (Sep 2025), MOIRAI 1.0 (Mar 2024) → MoE → 2.0 (Nov 2025), Toto + BOOM (May 2025), Chronos-2 multivariate (Oct 2025). Chronos-2 / TimesFM-2.5 trade #1 on GIFT-Eval roughly quarterly.
- **Conformal prediction matured** for TS — MAPIE 1.x, EnbPI mainstream, NeurIPS 2025 conformal-under-changepoints.
- **Nixtla ecosystem consolidation**: `statsforecast` + `mlforecast` + `neuralforecast` + `hierarchicalforecast` + `nixtla` (TimeGPT) under one cross-compatible `cross_validation` API; `coreforecast` shared C kernels.
- **DLinear** is still a hard baseline three years on. Treat it as the entry tariff for a forecasting paper.

## Authoritative references

- [Chronos-2 (arXiv 2510.15821)](https://arxiv.org/abs/2510.15821)
- [Toto + BOOM (Datadog)](https://www.datadoghq.com/blog/ai/toto-boom-unleashed/)
- [TimesFM 2.5](https://www.marktechpost.com/2025/09/16/google-ai-ships-timesfm-2-5-smaller-longer-context-foundation-model-that-now-leads-gift-eval-zero-shot-forecasting/)
- [MOIRAI (Salesforce)](https://www.salesforce.com/blog/moirai/)
- [PatchTST (arXiv 2211.14730)](https://arxiv.org/abs/2211.14730), [N-HiTS (arXiv 2201.12886)](https://arxiv.org/abs/2201.12886)
- [DLinear "Are Transformers Effective?" (arXiv 2205.13504)](https://arxiv.org/abs/2205.13504)
- [TFT (arXiv 1912.09363)](https://arxiv.org/abs/1912.09363)
- [Nixtla statsforecast cross-validation tutorial](https://nixtla.github.io/statsforecast/docs/tutorials/crossvalidation.html)
- [sklearn TimeSeriesSplit](https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.TimeSeriesSplit.html)
- [statsmodels ADF/KPSS notebook](https://www.statsmodels.org/stable/examples/notebooks/generated/stationarity_detrending_adf_kpss.html)
- [HierarchicalForecast (Nixtla)](https://nixtlaverse.nixtla.io/hierarchicalforecast/index.html)
- [MAPIE conformal docs](https://mapie.readthedocs.io/)
- [A Gentle Introduction to Conformal Time-Series Forecasting (arXiv 2511.13608)](https://arxiv.org/abs/2511.13608)
- [M5 results (Makridakis et al.)](https://www.sciencedirect.com/science/article/pii/S0169207021001874)
- [Prophet seasonality/holidays/regressors](https://facebook.github.io/prophet/docs/seasonality,_holiday_effects,_and_regressors.html)
- [TimeGPT prediction intervals](https://www.nixtla.io/docs/forecasting/probabilistic/prediction_intervals)

## Guardrails

Before recommending a non-trivial time-series change (CV gap, multi-step strategy, foundation-model adoption, conformal layer, reconciliation method):
1. Quote the parameter / function and any default
2. Cite the originating paper / library doc
3. Make the recommendation conditional on observed evidence (MASE vs SeasonalNaive, interval coverage, drift-detector signal) — never blanket-tune
4. Verify the library version. Many features gate (Chronos-2 multivariate Oct 2025, TimesFM 2.5 16K ctx Sep 2025, MAPIE 1.x conformal API)

**Tuning without measurement is worse than defaults.**

---
name: classical-ml-pitfalls
description: >
  Deep classical-ML operational intuition — the leakage taxonomy (target / contamination /
  group / temporal / preprocessing) and how Pipeline + ColumnTransformer prevent it,
  cross-validation correctness (StratifiedKFold, GroupKFold, StratifiedGroupKFold,
  TimeSeriesSplit gap, nested CV), eval under class imbalance (PR-AUC vs ROC-AUC, MCC,
  threshold tuning, cost-sensitive learning, SMOTE-in-pipeline), calibration (Platt vs
  isotonic vs Beta vs temperature), categorical encoding (sklearn TargetEncoder cross-
  fit, CatBoost ordered TS), missing-data handling, XGBoost/LightGBM/CatBoost
  operational tuning footguns, permutation importance vs TreeSHAP.
  Load ONLY when the task is about tabular ML rigor — diagnosing too-good-to-be-true
  CV, designing CV under non-IID rows, calibration, threshold tuning, encoding
  categoricals correctly, or boosted-tree config. Do NOT load for deep-learning
  training (use `dl-training`), LLM eval, RL, or time-series forecasting models
  beyond CV strategy (use `time-series-ml`) — those don't need this skill.
  Triggers on: "data leakage", "target leakage", "group leakage", "temporal leakage",
  "preprocessing leakage", "GroupKFold", "TimeSeriesSplit", "StratifiedKFold",
  "StratifiedGroupKFold", "nested CV", "class imbalance", "PR-AUC", "MCC",
  "Matthews correlation", "threshold tuning", "Youden's J", "calibration", "Platt scaling",
  "isotonic", "Brier score", "CalibratedClassifierCV", "TargetEncoder",
  "ordered target statistics", "early_stopping_rounds", "num_leaves",
  "monotone_constraints", "enable_categorical", "categorical_features=from_dtype",
  "IterativeImputer", "missing indicator", "permutation importance", "TreeSHAP",
  "SMOTE in pipeline", "imblearn".
---

# Classical ML Pitfalls — Operational Guide

Concise operational pointers for classical-ML rigor that models tend to gloss over.

Assumes you already know logistic regression, random forest, gradient boosting, sklearn syntax, and basic CV. This skill covers the **operational layer** — leakage taxonomy, CV under non-IID rows, eval under imbalance, calibration choice, categorical encoding correctness, missing-data handling, boosted-tree tuning footguns — current as of late 2025/early 2026 (sklearn 1.6/1.7/1.8 era).

## When to use

Load when the task is:
- Building a tabular classifier/regressor for production with cost-sensitive thresholds
- Designing CV when rows are non-IID (patient-, store-, session-level)
- Fitting a model on time-ordered data with a forecast horizon
- High class imbalance (positives < 5%), or ROC-AUC looks suspiciously good
- Probabilities consumed downstream (uplift, expected-value, two-stage routing)
- Categoricals with high cardinality (>50 levels) or unseen-at-inference categories
- Benchmarking XGBoost/LightGBM/CatBoost and getting irreproducible runs
- Suspect leakage after a too-good-to-be-true CV score
- A pipeline mixes scaling, imputation, and a regularized linear model
- Kaggle-style write-up where validation gap is large
- Disparate-impact / fairness audit on group-level metrics
- Need feature attributions you can defend (permutation vs SHAP)

**Do NOT load** for: deep-learning training (use `dl-training`), LLM evaluation, RL, time-series forecasting models (use `time-series-ml`; the CV strategy here still applies), vector-DB retrieval ranking.

## Leakage taxonomy and what `Pipeline` actually fixes

Five categories, increasing subtlety:

1. **Target leakage** — feature is a function of `y` known only post-event (e.g., `total_paid` predicting `defaulted`). **No CV scheme catches this**; requires a temporal/causal audit of each column.
2. **Train/test contamination** — same row in both splits. Hash IDs, split on the hash.
3. **Group leakage** — same patient, user, or device in train and test. Use `GroupKFold(n_splits=5).split(X, y, groups=patient_id)` or `GroupShuffleSplit`. `cross_val_score` accepts `groups=` only for splitters that support it.
4. **Temporal leakage** — random shuffle of time-ordered rows. Use `TimeSeriesSplit(n_splits=5, gap=H, max_train_size=...)` where `gap` excludes `H` samples between train and test (set to your forecast horizon to avoid label-period overlap). **Default `gap=0` is wrong for nearly all production forecasts.**
5. **Preprocessing leakage** — fitting `StandardScaler`, `SimpleImputer`, `TargetEncoder`, PCA, or feature-selection on the full dataset before splitting. **Fix is structural**: wrap them in `sklearn.pipeline.Pipeline` and pass the pipeline (not the fitted estimator) to `cross_val_score` / `GridSearchCV`. Each fold then refits transformers on that fold's train portion only.

`ColumnTransformer` mistakes:
- Fitting it once outside the pipeline, then passing transformed arrays into CV — same leakage as #5.
- `remainder='passthrough'` shifts downstream column indices; refer to columns by name (pandas/Polars), not positional `[0,1,2]`.
- Putting `SMOTE` / `RandomOverSampler` inside `sklearn.pipeline.Pipeline` — fails silently; the resampler runs at predict time too. Use **`imblearn.pipeline.Pipeline`**, which only resamples on `fit`.

## Cross-validation correctness

`KFold` default `n_splits=5` (sklearn 1.x). `cross_val_score` auto-picks `StratifiedKFold` when the estimator inherits `ClassifierMixin` — but only on the default integer-`cv` path; passing your own `KFold` overrides this. **For class imbalance always pass `StratifiedKFold` explicitly**; with groups, use `StratifiedGroupKFold` (sklearn ≥ 1.0) which preserves both stratification and group disjointness.

`TimeSeriesSplit`: training sets are *expanding* by default (each fold's train is a superset of the previous). For sliding window, set `max_train_size`. **`gap` must equal the forecast horizon when the label is computed over a future window** — otherwise label-period overlap leaks.

**Nested CV** for unbiased generalization with HPO: outer loop estimates performance, inner loop tunes. Cheap shortcut: hold out a final test set once, do `GridSearchCV` on train (`refit=True`), evaluate the refit estimator on test exactly once. **Re-using the test set to compare configurations is leak-by-stewardship** — equivalent to multiple-comparisons inflation.

## Imbalance: metrics, thresholds, weights, SMOTE

Under extreme imbalance (positive rate < 1%), **ROC-AUC is dominated by the easy true-negative bulk** and stays high even when precision is awful. **PR-AUC** (`average_precision_score`) shifts with prevalence and reflects positive-class quality directly. Pair with **MCC** (`matthews_corrcoef`, range −1..1, balanced across confusion-matrix cells) and class-conditional **F-beta** (β > 1 weights recall, β < 1 weights precision).

**Default threshold 0.5 is a modeling assumption, not a result.** Tune via:
- **Youden's J**: argmax `(tpr − fpr)` (balanced misclassification cost).
- **F-beta**: `precision_recall_curve` then argmax `(1+β²)·P·R / (β²·P + R)`.
- **Cost-sensitive**: argmin `c_FP·FP + c_FN·FN` over thresholds with explicit costs.

Tune on a *separate* validation fold from training and from final test.

`class_weight='balanced'` reweights loss inversely to class frequency at fit time; `sample_weight` is row-level and stacks. Both are math-only — they don't change rank order, only the cost surface; with calibrated probabilities they are essentially threshold shifts.

**SMOTE caveats**: synthesizes interpolated nearest-neighbor minority points → inflates near-duplicates. Apply *inside* CV via `imblearn.pipeline.Pipeline` so synthesis runs on each fold's training portion only — applying SMOTE before CV produces near-perfect AUCs that vanish in production. SMOTE rarely helps modern boosted trees with `scale_pos_weight` / `is_unbalance`; prefer those plus threshold tuning.

## Calibration: which method, which size

`CalibratedClassifierCV(estimator, method=..., cv=5, ensemble=True)`:
- **`method='sigmoid'`** (Platt): two-parameter logistic. Works on small data (~hundreds), assumes miscalibration is symmetric and roughly logistic. Underperforms when reliability curve is non-monotonic in shape.
- **`method='isotonic'`**: piecewise-constant non-decreasing fit. Needs ≥1k calibration samples or it overfits and creates ties that distort ROC. Strictly more flexible than Platt.
- **Beta calibration** (third-party `pycal`): three parameters; outperforms Platt when score distribution per class is non-Gaussian. Common for boosted trees.
- **Temperature scaling** (DL): single scalar `T`, divides logits before softmax — preserves argmax (so accuracy unchanged), rescales entropy.

`ensemble=True` (default) trains `cv` (classifier, calibrator) pairs and averages — costs `cv×` training but improves robustness. `ensemble=False` reuses out-of-fold predictions to fit a single calibrator on the full data — faster, smaller artifact.

**Reliability diagram**: bin predicted probs, plot bin mean vs empirical positive rate; well-calibrated → diagonal. **Brier score** = mean squared error of probabilities; decomposes into calibration + refinement + uncertainty, so a lower Brier can come from sharper but less-calibrated forecasts. Use Brier + reliability diagram together.

**Calibration is independent of discrimination**: a model with AUC 0.95 can be poorly calibrated; calibrating cannot improve AUC (rank order). For threshold tuning under cost asymmetry you need calibrated probabilities, not just rankings.

## Encoding categoricals

- **One-hot** (`OneHotEncoder(handle_unknown='ignore', max_categories=...)`): blows up parameter count for high-cardinality; tree models split slower; unseen levels become all-zero rows.
- **Naive target/mean encoding**: leaks unless out-of-fold. The `category-encoders` package's `TargetEncoder` does global encoding by default — wrap in `cross_val_predict` or use sklearn's native version.
- **`sklearn.preprocessing.TargetEncoder`** (since 1.3): internal cross-fitting in `fit_transform` (default `cv=5`, `smooth='auto'` empirical-Bayes shrinkage to global mean). **Critical**: `enc.fit(X,y).transform(X)` and `enc.fit_transform(X,y)` give *different* outputs — only the latter cross-fits on training data. Test data uses the full-fit encoder via `transform`. For multiclass: `n_features × n_classes` columns.
- **CatBoost ordered TS**: shuffles row order and computes encoding from preceding rows only — `ctr = (countInClass + prior) / (totalCount + 1)`. Multiple permutations average out shuffle variance. Set `cat_features=[...]` (indices or names); never one-hot beforehand.
- **Frequency encoding**: cheap, leak-safe, surprisingly competitive. **James-Stein** (in `category_encoders`): shrinkage estimator like sklearn's TargetEncoder but with closed-form variance.

## Missing data

- **MCAR** (random) — drop or impute with `SimpleImputer`. **MAR** (depends on observed) — model-based; `IterativeImputer` (experimental, set `random_state`). **MNAR** (depends on unobserved) — no purely statistical fix; add a missing indicator and let the model learn.
- `KNNImputer`: O(n²) at fit, fragile on high-d; scale features first.
- **Missing indicator** (`MissingIndicator` or `add_indicator=True`) is cheap and often preserves signal lost to imputation.
- **XGBoost / LightGBM** handle NaN natively: choose default branch direction at each split using gradient on missing rows. **Do not impute before** — you destroy signal. CatBoost: same for numeric; categoricals require explicit handling.

## Boosted-tree operational

**XGBoost** (3.x): `early_stopping_rounds` accepted directly in `fit()` for sklearn API; via `xgb.callback.EarlyStopping` for native API. `eval_metric` defaults from `objective` — `objective='binary:logistic'` without setting `eval_metric` defaults to `logloss`; if you tune for AUC explicitly set `eval_metric='auc'`. Mismatch between `objective` (training loss) and `eval_metric` (early-stop signal) is fine *if* you understand both surfaces; the trap is using `auc` for early stop but reporting log-loss. `enable_categorical=True` plus pandas/Polars `category` dtype unlocks native splits; alternatively `feature_types=['c','q','q',...]` on `DMatrix` (`q`=quantitative, `c`=categorical). `monotone_constraints=(1,0,-1,...)` per-feature: 1 non-decreasing, −1 non-increasing, 0 free. `tree_method='hist'` + `device='cuda'` for GPU; `gpu_hist` is deprecated. `max_bin` default 256; lower = faster + more regularized.

**LightGBM**: `num_leaves` default 31, **primary complexity knob** — leaf-wise growth means a tree with `num_leaves=255` is far deeper than depth-7 in XGBoost despite similar leaf counts. **Rule of thumb**: `num_leaves < 2^max_depth`. `min_data_in_leaf` default 20 — under-set this and a 31-leaf tree memorizes folds. `max_bin` default 255. `deterministic=True` + fixed `num_threads` for reproducibility; `feature_fraction_seed`, `bagging_seed`, `data_random_seed` separately. **Negative integers in `categorical_feature` columns are treated as missing** — silent bug source.

**CatBoost**: `cat_features=[...]` then *do not* one-hot. Best with native pandas DataFrame; ordered boosting reduces target-encoding leakage. Slow without `task_type='GPU'`.

## Scaling, collinearity, importances

Tree models are scale-invariant; standardizing inputs is wasted compute. **Regularized linear models** (`Ridge`, `Lasso`, `LogisticRegression(penalty='l2')`, `LinearSVC`) require scaling — penalty is on coefficient magnitude in the *scaled* basis, so unscaled features get penalized in proportion to their numeric range. With strong collinearity, logistic-regression coefficients become unstable; either L2 + standardize, or drop one of each correlated pair (`np.corrcoef` > 0.95) before fitting.

**Permutation importance** (`sklearn.inspection.permutation_importance(model, X_val, y_val, n_repeats=30, scoring=...)`): model-agnostic, computed on validation data, reflects reliance not causation. With correlated features, permuting one leaks information through its twin → both underestimated. Cluster correlated features (`scipy.cluster.hierarchy` on `1 − |corr|`) and permute clusters.

**TreeSHAP** (XGBoost/LightGBM/CatBoost native): exact Shapley values for tree ensembles in polynomial time; respects feature interactions, decomposes per-row, but encodes the model's *use* of features — high SHAP doesn't mean causal. Use permutation importance for "does removing this feature hurt" and SHAP for per-prediction explanation. **Never cite tree-impurity importance** (`feature_importances_`) — biased toward high-cardinality features.

## Recent changes (sklearn 1.6 / 1.7 / 1.8)

- `HistGradientBoostingClassifier/Regressor` defaults `categorical_features='from_dtype'` (since 1.6) — auto-detects pandas `category` and Polars `Categorical`/`Enum` dtypes. Pass a Polars DataFrame directly; no `OrdinalEncoder` step needed.
- `TargetEncoder` (since 1.3) — internal CV; the `fit_transform` vs `fit().transform()` distinction is the **#1 footgun**.
- `set_output(transform='polars')` (since 1.4) on transformers returns Polars frames end-to-end.
- sklearn 1.7 (June 2025): experimental free-threaded CPython 3.13 support; broader Array API coverage (PyTorch / CuPy on selected estimators).
- XGBoost 3.x: `device='cuda'` replaces `gpu_hist`; categorical native + Arrow ingestion stable.

## Authoritative references

- [scikit-learn cross-validation user guide](https://scikit-learn.org/stable/modules/cross_validation.html)
- [scikit-learn TargetEncoder](https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.TargetEncoder.html)
- [scikit-learn calibration user guide](https://scikit-learn.org/stable/modules/calibration.html)
- [scikit-learn permutation importance](https://scikit-learn.org/stable/modules/permutation_importance.html)
- [scikit-learn 1.7 release notes](https://scikit-learn.org/stable/whats_new/v1.7.html)
- [HistGradientBoostingClassifier](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.HistGradientBoostingClassifier.html)
- [XGBoost parameters](https://xgboost.readthedocs.io/en/stable/parameter.html), [XGBoost categorical tutorial](https://xgboost.readthedocs.io/en/stable/tutorials/categorical.html)
- [LightGBM parameters](https://lightgbm.readthedocs.io/en/latest/Parameters.html)
- [CatBoost ordered target statistics](https://catboost.ai/docs/concepts/algorithm-main-stages_cat-to-numberic.html)
- [imbalanced-learn common pitfalls](https://imbalanced-learn.org/stable/common_pitfalls.html)
- [Fairlearn assessment user guide](https://fairlearn.org/main/user_guide/assessment/index.html)

## Guardrails

Before recommending a non-trivial change (CV scheme, calibration method, encoder choice, threshold, boosted-tree config):
1. Quote the parameter and its default for the library version in use
2. Cite the official user guide section
3. Make the recommendation conditional on observed evidence (held-out metric, reliability diagram, leakage audit) — never blanket-tune
4. Verify the library version. Many features gate (sklearn 1.3 TargetEncoder, 1.6 `categorical_features='from_dtype'`, XGBoost 3.x `device='cuda'`)

**Tuning without measurement is worse than defaults.**

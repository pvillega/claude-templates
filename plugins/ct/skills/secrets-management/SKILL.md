---
name: secrets-management
description: >
  Operational tradeoffs across secret-management approaches — sops + age, cloud KMS,
  HashiCorp Vault, Sealed Secrets, External Secrets Operator, k8s native Secrets,
  SaaS managers. Covers rotation patterns, threat boundaries, leak-detection tooling,
  and the workflow specifics LLMs gloss over (sops .sops.yaml rules, Vault auth methods,
  ESO ExternalSecret CR, kubeseal scopes, KMS provider config).
  Load ONLY when the task is about choosing between approaches, designing rotation,
  configuring sops/Vault/ESO/Sealed Secrets, k8s etcd encryption, or diagnosing
  leak / propagation / boot-strap problems. Do NOT load for ordinary "store this
  password" or trivial `kubectl create secret` questions — those don't need this skill.
  Triggers on: "sops", "age encryption", "vault auth", "AppRole", "sealed secrets",
  "external secrets operator", "ExternalSecret", "kubeseal", "KMS provider", "etcd
  encryption at rest", "secret rotation", "dynamic credentials", "secret leak",
  "gitleaks", "trufflehog", ".sops.yaml", "secret store CR", "response wrapping",
  "auto-unseal", "sealed-secrets backup".
---

# Secrets Management Operational Guide

Concise pointers for choosing and operating secret-management systems.

Assumes you know what an env var, a k8s `Secret`, and an IAM role are. This skill covers the **operational layer** — the parts models tend to gloss over: which tool fits which threat model, the workflow specifics of `sops` / Vault / ESO / Sealed Secrets, rotation mechanics, leak-detection tooling, and boot-strap-trust pitfalls.

## When to use

Load when the question is about:
- Picking among sops+age / Vault / Sealed Secrets / ESO / SaaS for a specific environment
- `sops` workflow (`.sops.yaml`, `encrypted_regex`, `updatekeys`, age recipients)
- Vault auth methods, dynamic credentials, response wrapping, seal/unseal
- Sealed Secrets controller behaviour, scope flags, key rotation, master-key backup
- External Secrets Operator: `SecretStore`/`ExternalSecret` CRs, refresh, generators
- Kubernetes native Secrets: etcd KMS encryption, `immutable`, mount propagation
- Rotation patterns (static, dynamic, versioned, IAM federation)
- Leak detection (gitleaks/trufflehog/git-secrets) and Docker BuildKit secret mounts

**Do NOT load** for: "store this password somewhere", trivial `kubectl create secret`, `.env` file basics, password-manager UX. Those don't need this skill.

## Decision matrix

| Approach | When it fits | What it costs |
|---|---|---|
| **sops + age** in repo | GitOps, low infra, small team, encrypts at rest in Git | Manual recipient list mgmt; no audit trail; no dynamic creds |
| **sops + cloud KMS** | Want central key authority + IAM-based access | Network call to KMS on every decrypt; KMS key deletion = data loss |
| **HashiCorp Vault** | Dynamic creds, audit, multi-team, certificate issuance, transit encryption | Operates a stateful HA cluster; seal/unseal ceremony; full-time operator |
| **AWS SM / GCP SM / Azure KV** | Already in that cloud, want minimal ops | Cloud lock-in; per-secret cost; cross-region replication is extra |
| **Sealed Secrets** | Pure-k8s GitOps; secrets must live in Git encrypted | Controller-only decryption; lose master key = lose all secrets; namespace+name binding by default |
| **External Secrets Operator** | Already running a secret store; want k8s-native sync | Bootstrap-trust problem (auth to backend); k8s `Secret` object still on cluster |
| **Doppler / Infisical / 1Password Automation** | Small team, want polished UX, no infra | Vendor outage = your secrets are gone; data residency questions |

**Rule of thumb**: pick the simplest tool that satisfies the threat model. sops+age beats Vault for a 3-person team; Vault beats sops the moment you need dynamic database creds or PKI.

## sops

- **What it encrypts**: VALUES of structured files (YAML/JSON/INI/ENV/dotenv); KEYS stay plaintext. Preserves diff readability — reviewing PRs against encrypted files still works.
- **Backends**: age, AWS KMS, GCP KMS, Azure Key Vault, HashiCorp Vault transit, GCP/AWS Secrets Manager, PGP/GPG.
- **`.sops.yaml` creation_rules**: list evaluated top-down, first match wins. Each rule has `path_regex`, recipient set (`age:` / `kms:` / `pgp:` / `hc_vault_transit_uri:`), and optional `encrypted_regex` / `unencrypted_regex` (mutually exclusive).
  ```yaml
  creation_rules:
    - path_regex: secrets/prod/.*\.yaml$
      age: age1abc...
      kms: arn:aws:kms:eu-west-1:111:key/xxx
      encrypted_regex: '^(password|token|secret|key|credential)'
  ```
- **Selective encryption**: `encrypted_regex 'password|token|secret|key'` encrypts only matching keys; the rest stays plaintext. Useful for k8s `Secret` manifests where `metadata` should remain navigable.
- **Commands**: `sops -e file.yaml` encrypt; `sops file.yaml` open in `$EDITOR` (auto decrypt/re-encrypt); `sops -d file.yaml` decrypt to stdout; `sops -i -e file.yaml` in-place encrypt.
- **MAC**: SOPS computes a MAC over encrypted values + key paths as AAD → tamper detection. Modifying the YAML structure of an encrypted file breaks the MAC.
- **Per-value AES-256-GCM with unique IV**: prevents pattern analysis across the file.
- **Key rotation**: edit `.sops.yaml` recipient list, then `sops updatekeys file.yaml` (re-encrypts the data key to new recipients without changing the data key itself). For a full data-key rotation use `sops --rotate -i file.yaml` or `sops rotate`.
- **Shamir threshold**: `key_groups` + `shamir_threshold: N` → require N of M groups to decrypt. Use when no single team should be able to read prod alone.
- **Key file lookup order** (age): `SOPS_AGE_KEY_FILE` env var → `SOPS_AGE_KEY` (raw key) → `SOPS_AGE_KEY_CMD` (command output) → `~/.config/sops/age/keys.txt`.

## age

- **Pure file encryption**, X25519. Intentionally minimal: no signing, no negotiation, no algorithm agility.
- `age-keygen -o key.txt` writes private key to file; line 2 is `# public key: age1...` (the recipient).
- `age -e -r age1abc... -o out.age in.txt` encrypt to one recipient.
- `age -d -i key.txt out.age` decrypt with identity file.
- **Multiple recipients**: `-r` is repeatable; resulting file decrypts with ANY one identity. Pattern: encrypt to every developer's age pubkey + a CI/CD key.
- **SSH keys as recipients**: `age -R ~/.ssh/authorized_keys -o out.age in.txt` — supports `ssh-ed25519` and `ssh-rsa`. Decrypt with `age -d -i ~/.ssh/id_ed25519`.
- **Recipient files**: `-R recipients.txt` (one per line, comments OK).
- **No revocation**: removing a recipient from `.sops.yaml` and running `sops updatekeys` does NOT erase historical Git-committed encrypted files — the old recipient can still decrypt those revisions. Treat removed recipient = compromised data.

## HashiCorp Vault

### Engines

- **KV v1**: no versioning. `vault kv put secret/foo k=v`, `vault kv get secret/foo`. Overwrites lose history.
- **KV v2**: versioned, soft-delete, configurable `max_versions`. `vault kv get -version=3 secret/foo`. Old versions retained until `destroy`.
- **Database**: dynamic credentials with TTL. Configure connection + role (`creation_statements` SQL with `{{username}}`/`{{password}}` placeholders), then `vault read database/creds/<role>` returns ephemeral user with `lease_id` + `lease_duration`. Default TTL 1h, max 24h. Supports Postgres, MySQL/MariaDB, Mongo, MSSQL, Oracle, Cassandra, Redis, Snowflake, Elasticsearch, +20.
- **PKI**: issue short-lived X.509 certs with `vault write pki/issue/<role> common_name=...`. CRL/OCSP managed by Vault.
- **Transit**: encryption-as-a-service. App sends plaintext, gets ciphertext back; key never leaves Vault. Use for application-level encryption when you don't want to ship key material.
- **SSH**: signed-cert auth — Vault signs an SSH cert using its CA, host trusts the CA, no per-user public-key dance.

### Auth methods

- **Token**: native, including the root token (printed at init/dev). Never use root token for routine ops.
- **AppRole**: `role_id` (selector, ~UUID) + `secret_id` (credential). Recommended pattern: trusted orchestrator wraps `secret_id` (`vault write -wrap-ttl=120s -force auth/approle/role/<r>/secret-id`), hands wrapping token to consumer; consumer unwraps once, gets `secret_id`. TTL knobs: `secret_id_ttl`, `secret_id_num_uses`, `token_ttl`, `token_max_ttl`.
- **Kubernetes**: pod presents its SA JWT; Vault validates against the k8s API (`tokenreviews`). Tied to namespace + SA via role. No long-lived secret in cluster.
- **AWS IAM**: instance profile or IAM principal signs `sts:GetCallerIdentity`; Vault verifies signature.
- **OIDC/JWT**: federate from any OIDC IdP (GitHub, GitLab, Auth0, Okta, OAuth2 proxies).
- **LDAP**, **GitHub** (org/team membership), **Azure**, **GCP**, **Okta**, **userpass** (last-resort).

### Seal / unseal

- **Shamir** (default): unseal key split into N shares, M required to reconstruct (configurable at `vault operator init`, e.g. `-key-shares=5 -key-threshold=3`). Each operator runs `vault operator unseal` with one share.
- **Auto-unseal**: delegate to AWS KMS, GCP KMS, Azure KV, OCI KMS, AliCloud KMS, HSM (PKCS#11), or Transit on a *separate* Vault. With auto-unseal, Vault generates **recovery keys** (not unseal keys) — they cannot decrypt the root key, only authorize emergency operations.
- **Critical**: deleting the seal KMS key = unrecoverable cluster, even from backup.

### Operational essentials

- **`-dev` mode**: in-memory, root token printed to stdout, no TLS. NEVER production. Resets on restart.
- **Audit devices**: file / syslog / socket. **Required** for compliance; multiple can run; if all audit devices fail, Vault BLOCKS requests (intentional). `vault audit enable file file_path=/var/log/vault_audit.log`.
- **Response wrapping** (`cubbyhole`): `vault wrap` returns a one-time token in a per-token cubbyhole. Used for hand-off (e.g., delivering `secret_id` to a worker without trusting the courier).
- **Lease management**: `vault list sys/leases/lookup/...`, `vault lease renew <id>`, `vault lease revoke <id>`. Dynamic creds revoke on lease expiry — design apps to fetch fresh creds + retry on `permission denied`, not to cache forever.

## Sealed Secrets (Bitnami)

- **Controller-side asymmetric**: controller in cluster generates RSA keypair on first start; pubkey distributed via `kubeseal --fetch-cert`. Only the controller can decrypt.
- `kubeseal -f secret.yaml -w sealed.yaml` produces a `SealedSecret` CR safe to commit. Apply: `kubectl apply -f sealed.yaml` → controller decrypts → creates real `Secret`.
- **Scope** (`--scope`):
  - `strict` (default): bound to exact `namespace + name`. Move/rename = fails.
  - `namespace-wide`: any name within namespace.
  - `cluster-wide`: any namespace, any name. Loosest; only when you must.
- **Rotation**: controller generates new key every **30 days** (`--key-renew-period`). Old keys retained to decrypt existing `SealedSecret`s. To re-encrypt with the latest key without exposing plaintext: `kubeseal --re-encrypt < old.yaml > new.yaml`.
- **Master-key backup** (NON-NEGOTIABLE): `kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > master.key`. Store offline. Without this, a wiped cluster cannot decrypt any committed `SealedSecret`.
- **Limitation**: can only encrypt a `Secret` shape — for non-Secret resources you need ESO or sops.

## External Secrets Operator (ESO)

- **`SecretStore`** (namespace-scoped) / **`ClusterSecretStore`** (cluster) — describes a backend (Vault, AWS SM, GCP SM, Azure KV, 1Password Connect, Akeyless, Doppler, GitLab, IBM, +40).
- **`ExternalSecret`** CR pulls keys from the store and creates/updates a k8s `Secret`:
  ```yaml
  apiVersion: external-secrets.io/v1
  kind: ExternalSecret
  metadata: { name: db-creds }
  spec:
    refreshInterval: 1h
    secretStoreRef: { kind: SecretStore, name: vault-prod }
    target: { name: db-creds, creationPolicy: Owner }
    data:
      - secretKey: PASSWORD
        remoteRef: { key: secret/data/db, property: password }
  ```
- **`refreshInterval`**: re-fetches and updates the k8s `Secret`. `0` = create once, never refresh.
- **`dataFrom`**: bulk import; takes whole JSON object as keys, or supports `extract` / `find` patterns.
- **`creationPolicy`**: `Owner` (default — k8s `Secret` is owned by the CR, deletes cascade) / `Merge` (update existing, no owner) / `Orphan` (create no owner refs) / `None` (injector use only).
- **`deletionPolicy`**: `Retain` (default) / `Delete` (drop k8s `Secret` when remote keys gone) / `Merge` (drop only the keys, keep `Secret`).
- **Auth bootstrap problem**: `SecretStore` needs creds to talk to the backend. Solutions in order of preference:
  1. **Workload identity / IRSA** (EKS) / **Workload Identity Federation** (GKE) — pod assumes IAM role via OIDC; no secret in cluster.
  2. **Kubernetes auth method** (Vault) — pod's SA JWT validated by Vault; no secret in cluster.
  3. Static token in a k8s `Secret` (chicken-and-egg; only acceptable for boot-strap).
- **Generators** (push-based): `Password`, `ECRAuthorizationToken`, `GCRAccessToken`, `ACRAccessToken`, `Webhook`, `ClusterGenerator`. `Password` produces a generated password into a `Secret`; `ECRAuthorizationToken` produces a 12-hour Docker pull cred without static creds in cluster.

## Kubernetes native Secrets

- **`base64` is encoding, NOT encryption**. By default `Secret`s land in etcd as plaintext (base64 in YAML, plaintext on disk).
- **Encryption at rest**: `--encryption-provider-config=/etc/k8s/enc.yaml` on `kube-apiserver`. Provider chain — first encrypts, all decrypt:
  ```yaml
  apiVersion: apiserver.config.k8s.io/v1
  kind: EncryptionConfiguration
  resources:
    - resources: [secrets]
      providers:
        - kms: { apiVersion: v2, name: cloudkms, endpoint: unix:///run/kmsplugin/socket.sock, timeout: 3s }
        - aescbc: { keys: [{ name: fallback, secret: <base64-32B> }] }
        - identity: {}   # plaintext fallback — last
  ```
- **Providers**: `aescbc` (AES-CBC + PKCS#7 + HMAC), `secretbox` (XChaCha20-Poly1305), `kms` v1/v2, `identity` (none). KMS v1 deprecated since 1.28, disabled by default 1.29 — use **kms v2** (automatic seed rotation, KDF-derived per-write DEKs, no manual `cachesize`).
- **Provider order**: first listed encrypts new writes; reads try each in order. Add new provider FIRST, then re-encrypt all secrets (`kubectl get secret -A -o json | kubectl replace -f -`), THEN remove old.
- **`immutable: true`** (1.21+): `Secret` cannot be updated or have data changed; reduces apiserver/etcd watch load. Useful for rarely-changed long-lived secrets.
- **Update propagation**:
  | Mount type | Updates? | Latency |
  |---|---|---|
  | Volume mount | yes | ~kubelet sync, default 60s |
  | Volume mount + `subPath` | NO | requires pod restart |
  | Env var (`valueFrom.secretKeyRef`) | NO | baked at pod start |
- **`/proc/PID/environ` leak**: any process with same UID can read another's env vars. Volume mounts (`mode: 0400`) are safer than env vars for sensitive material.

## Rotation patterns

- **Static rotation** (passwords, API keys): rotate in store + redeploy/restart consumers. Outage window = consumer restart time. Decouple by keeping N+1 versions live (consumers read latest; old continues to work briefly).
- **Dynamic credentials** (Vault DB engine, AWS STS): consumers fetch fresh creds with TTL. Rotation is automatic when lease expires. Apps must handle "creds expired mid-flight" — typically retry-on-401 against fetch-creds endpoint.
- **Versioned secrets** (KV v2, AWS SM versioned): old version retained as `AWSPREVIOUS` / version=N-1; consumers can pin or follow latest. Rotation = create new version, then update consumer pointer.
- **IAM federation** (no rotation): OIDC trust between IdP and AWS/GCP/Azure → short-lived STS tokens (15min–12h). Best pattern when both parties speak OIDC. No secret to rotate because no secret exists.
- **Database root rotation** (Vault `rotate-root`): Vault rotates the DB root password to a value only Vault knows. Subsequent DB engine ops still work; humans permanently lose root unless they break-glass.

## Trust boundaries / threat model

- **At rest**: disk encryption (FDE) is necessary but not sufficient. KMS-encrypted secret value defends against backup theft and operator browsing etcd.
- **In transit**: TLS to the secret store. Verify cert chain — a Vault client trusting `InsecureSkipVerify=true` defeats the design.
- **In use**: secret in process memory. For high-stakes (banking, PII), TEEs (AWS Nitro Enclaves, Intel SGX) keep keys out of host kernel reach.
- **Supply chain**: who can read the store? CI runners with broad pull access are a wide blast radius. Apply per-job least-privilege (per-environment AppRole / per-job OIDC subject claim).

## Leak detection / prevention

- **`gitleaks`**: regex + entropy + composite rules; pre-commit hook (`pre-commit-config.yaml`) and history scan (`gitleaks git --log-opts="--all"`). Bypass: `SKIP=gitleaks git commit`. Config precedence: `-c` flag > `GITLEAKS_CONFIG` env > `GITLEAKS_CONFIG_TOML` env > `.gitleaks.toml`.
- **`trufflehog`**: similar surface, plus **active credential verification** — calls the suspected provider to check if the leaked key actually works. Lower false positive rate at cost of network calls.
- **`git-secrets`**: AWS-pattern focused (`AKIA...`, etc.); lighter, narrower scope.
- **GitHub secret scanning**: built-in for public repos, free; partner program for private repos pushes alerts to providers (e.g., AWS auto-quarantines leaked keys).
- **Pre-commit framework**: integrate `gitleaks` / `trufflehog` / `detect-secrets` to fail commits matching patterns.

## Common pitfalls

- **Env-var secrets readable via `/proc/PID/environ`** (same UID). Prefer file mounts with `0400`.
- **`docker build --build-arg PASSWORD=...`**: build args persist in image layers / `docker history`. Use BuildKit `--mount=type=secret,id=foo` instead — secret only available during the `RUN` instruction at `/run/secrets/foo`, not in image. CLI: `docker build --secret id=foo,src=./secret.txt`.
- **Logging exception messages with secret values** — sanitize at the log boundary, not the call site.
- **`kubectl edit secret` shows base64**: a quick `base64 -d` reveals plaintext in terminal scrollback. Clear scrollback / use `kubectl create secret --dry-run=client -o yaml | kubeseal` instead.
- **Sealed Secrets controller key not backed up** → cluster rebuild = unrecoverable secrets. Back up `kube-system/sealed-secrets-key*` immediately on day 1.
- **ESO `SecretStore` static-token auth in cluster**: chicken-and-egg, defeats the point. Use IRSA / Workload Identity / Vault k8s auth instead.
- **`sops` + age committed without `.sops.yaml`**: new contributors can decrypt (their key is in the file) but cannot encrypt new files correctly because they don't know the recipient list. Always commit `.sops.yaml`.
- **Rotating an `age` recipient list does not retroactively re-key history**: removed recipients still decrypt old Git revisions. Treat any removed recipient as having permanent access to anything they could read at removal time.
- **k8s `Secret` updates don't propagate to `subPath` mounts or env vars** — surprise stale creds after rotation. Use plain volume mounts when rotation matters.

## Authoritative references

- [sops](https://github.com/getsops/sops) — README + [.sops.yaml docs](https://github.com/getsops/sops#using-sops-yaml-conf-to-select-kms-pgp-and-age-for-new-files)
- [age](https://github.com/FiloSottile/age) — `age(1)` man page
- [Vault docs](https://developer.hashicorp.com/vault/docs) — [auth methods](https://developer.hashicorp.com/vault/docs/auth), [database engine](https://developer.hashicorp.com/vault/docs/secrets/databases), [seal](https://developer.hashicorp.com/vault/docs/concepts/seal), [AppRole](https://developer.hashicorp.com/vault/docs/auth/approle)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) — README + scope/rotation sections
- [External Secrets Operator](https://external-secrets.io/) — [ExternalSecret API](https://external-secrets.io/latest/api/externalsecret/), [SecretStore](https://external-secrets.io/latest/api/secretstore/), [Generators](https://external-secrets.io/latest/api/generator/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) + [Encrypting data at rest (KMS)](https://kubernetes.io/docs/tasks/administer-cluster/kms-provider/)
- [Docker BuildKit secret mounts](https://docs.docker.com/build/building/secrets/)
- [gitleaks](https://github.com/gitleaks/gitleaks), [trufflehog](https://github.com/trufflesecurity/trufflehog), [git-secrets](https://github.com/awslabs/git-secrets)

## Guardrails

Before recommending a secret-management approach or a non-trivial config change:
1. State the threat model assumed (who is the attacker, what access do they already have)
2. Quote the specific config field, command, or env var by name (e.g. `creationPolicy: Orphan`, `sops updatekeys`, `--scope strict`)
3. Cite the official doc section
4. Make the choice conditional on team size, infrastructure, and existing tooling — never blanket-recommend Vault or sops

**A secret manager you cannot operate is worse than a `.env` file you respect.**

---
name: tls-openssl
description: >
  Deep TLS / openssl operational debugging — s_client handshake forensics, chain
  validation, ACME challenge mechanics, OCSP stapling, mTLS, file-format conversion
  (PEM/DER/PKCS#12/JKS), TLS 1.3 specifics, Certificate Transparency.
  Load ONLY when the task is "why does TLS not connect", cert chain debugging, ACME
  rate-limit / challenge failure, OCSP stapling diagnosis, mTLS setup, or format
  conversion between keystores. Do NOT load for ordinary "what is HTTPS" or basic
  asymmetric crypto explanations — those don't need this skill.
  Triggers on: "openssl s_client", "cert chain", "untrusted certificate", "verify error",
  "SNI mismatch", "ALPN", "OCSP stapling", "must-staple", "ACME challenge",
  "Let's Encrypt rate limit", "HTTP-01", "DNS-01", "TLS-ALPN-01", "PKCS12 convert",
  "PEM to DER", "JKS keystore", "mTLS client cert", "TLS handshake fail",
  "certificate expired", "self-signed in chain", "missing intermediate", "wrong cert served".
---

# TLS / openssl Operational Guide

Concise operational pointers for diagnosing TLS handshake failures, cert chain problems, and ACME/OCSP/mTLS workflows from the CLI.

Assumes you already know that TLS is asymmetric handshake → symmetric session, and that certs bind a public key to a name. This skill covers the **operational layer** — the openssl flags, error codes, ACME mechanics, and diagnostic flow that models gloss over.

## When to use

Load when the question is about:
- "Why does this TLS connection fail" — handshake forensics with `s_client`
- Cert chain validation errors (numbered verify codes)
- ACME challenge debugging (HTTP-01 / DNS-01 / TLS-ALPN-01) and Let's Encrypt rate limits
- OCSP stapling and Must-Staple diagnosis
- mTLS client-cert setup
- File-format conversion (PEM ↔ DER ↔ PKCS#12 ↔ JKS)
- TLS 1.3 specifics (cipher suite changes, 0-RTT, encrypted handshake)
- Certificate Transparency / SCT lookup

**Do NOT load** for: explaining what HTTPS does, basic public-key crypto introductions, TLS-protocol-design discussions, picking between `ssl` libraries — those don't need this skill.

## openssl s_client — handshake forensics

The single most useful debugging tool. Defaults are subtle and wrong.

- **SNI is mandatory.** `openssl s_client -connect host:443 -servername host`. Without `-servername`, hosts behind name-based vhosting return their **default cert** (typically the first one configured) — you'll debug the wrong cert. Modern openssl falls back to the `-connect` host, but always set `-servername` explicitly.
- **Non-interactive close.** `</dev/null openssl s_client -connect host:443 -servername host 2>/dev/null` — otherwise s_client hangs reading stdin. Pipe to `openssl x509 -noout -dates` to extract just the leaf dates.
- **Full chain dump.** `-showcerts` prints every cert the server sent in presentation order (leaf → intermediates). Compare what the server sends vs what the chain actually requires.
- **Verify return code.** s_client prints `Verify return code: N (text)` at the end. **s_client does not abort on verify failure by default** — add `-verify_return_error` to make it fail. Without that flag, a broken chain still appears to "work."
- **Custom CA.** `-CAfile ca.pem` to verify against a private CA. `-CApath /path/to/hashed/dir` for a directory of hashed CAs.
- **Force version.** `-tls1_2` / `-tls1_3` to constrain. `-no_tls1_3` to negate. Mismatch shows up as "no protocols available" or "wrong version number."
- **Force cipher.** `-cipher 'ECDHE-RSA-AES128-GCM-SHA256'` for TLS 1.2 only. `-ciphersuites TLS_AES_128_GCM_SHA256` for TLS 1.3 only — note these are **separate flags**; mixing throws a syntax error.
- **ALPN selection.** `-alpn h2,http/1.1`. Server picks one and returns `ALPN protocol: h2` in the output. Empty `ALPN protocol:` line = server did not negotiate (HTTP/1.1 default).
- **Protocol bytes.** `-debug` for raw hex dump of all bytes; `-msg` for parsed handshake messages (ClientHello, ServerHello, Certificate, ...). Use `-msg` first, escalate to `-debug` for byte-level.
- **STARTTLS for non-443.** `-starttls smtp|imap|pop3|ftp|xmpp` issues the protocol-specific upgrade command before the handshake. Otherwise the server interprets ClientHello as application data.
- **mTLS client cert.** `-cert client.pem -key client.key`. If server requests a cert and you don't send one, output shows `No client certificate CA names sent` plus a handshake error.

## X509_V_ERR codes (canonical mapping)

`Verify return code:` numbers correspond to `X509_V_ERR_*` in `<openssl/x509_vfy.h>`. Memorise these:

- **0** — `X509_V_OK` — success.
- **10** — `CERT_HAS_EXPIRED` — leaf or chain cert past `notAfter`. Check with `openssl x509 -noout -dates`.
- **18** — `DEPTH_ZERO_SELF_SIGNED_CERT` — leaf is self-signed (no CA). Common in dev with no `-CAfile`.
- **19** — `SELF_SIGNED_CERT_IN_CHAIN` — root anchor not in trust store. Add the root via `-CAfile`.
- **20** — `UNABLE_TO_GET_ISSUER_CERT_LOCALLY` — server did **not send the intermediate**, and you don't have it locally. The single most common production misconfiguration. Fix on the server, not the client.
- **21** — `UNABLE_TO_VERIFY_LEAF_SIGNATURE` — chain doesn't reach a trust anchor at all. Usually missing intermediate + missing root.
- **23** — `CERT_REVOKED` — appears in OCSP/CRL paths.
- **26** — `INVALID_PURPOSE` — leaf's EKU doesn't include `serverAuth` (or `clientAuth` for mTLS).
- **27** — `CERT_UNTRUSTED` — root present but not flagged as trustworthy for this purpose.

Full list defined at `include/openssl/x509_vfy.h` in the openssl repo (~105 codes).

## Cert inspection — quick reference

```bash
# Full text dump
openssl x509 -in cert.pem -noout -text

# Subject/issuer/dates only
openssl x509 -in cert.pem -noout -subject -issuer -dates

# SHA-256 fingerprint (matches what browsers show)
openssl x509 -in cert.pem -noout -fingerprint -sha256

# SANs (the field that actually matters for hostname match)
openssl x509 -in cert.pem -noout -ext subjectAltName

# Public key
openssl x509 -in cert.pem -pubkey -noout

# Read remote leaf without saving file
openssl s_client -connect host:443 -servername host </dev/null 2>/dev/null \
  | openssl x509 -noout -dates -subject -ext subjectAltName
```

**CN is dead.** Modern verifiers (Chrome, curl, Go since 1.15) **ignore Common Name** and use SAN exclusively. Always populate SAN; CN is for human display.

## Chain validation

- **Build bottom-up.** Server must serve `leaf + intermediate(s)`, NOT the root. The client already has the root in its trust store; sending the root wastes bytes and doesn't help.
- **Verify offline.** `openssl verify -CAfile root.pem -untrusted intermediates.pem leaf.pem` — exits 0 on success. `-untrusted` is the cert(s) to consider but not trust.
- **System trust stores:**
  - macOS: keychain (Mozilla bundle exposed via `/etc/ssl/cert.pem`)
  - Debian/Ubuntu: `/etc/ssl/certs/ca-certificates.crt` (managed by `update-ca-certificates`)
  - RHEL/Fedora: `/etc/pki/tls/certs/ca-bundle.crt` (managed by `update-ca-trust`)
  - Alpine: `/etc/ssl/certs/ca-certificates.crt` (`ca-certificates` apk package)
- **AIA chasing trap.** Authority Information Access (`caIssuers` URL) lets clients fetch missing intermediates. **Only Chrome / Edge** chase AIA. Firefox, curl, Go, Java, Python `ssl` do **not**. Symptom: site works in Chrome, fails everywhere else → server is missing the intermediate. Fix the server, never rely on AIA.
- **Cross-signed chains.** A leaf can verify via multiple paths (e.g., Let's Encrypt's ISRG Root X1 path AND the cross-signed DST Root CA X3 path until 2024). Server picks which intermediate to send — the wrong choice breaks old clients.

## Key & CSR generation

```bash
# RSA 4096 (still common for compat)
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out rsa.pem

# ECDSA P-256 (smaller, faster, modern default)
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out ec.pem

# Ed25519 (smallest, OpenSSL 1.1.1+; not all CAs accept yet)
openssl genpkey -algorithm ED25519 -out ed.pem

# CSR with proper SANs (CSR without SANs → modern clients reject)
openssl req -new -key rsa.pem -out csr.pem \
  -subj "/CN=example.com" \
  -addext "subjectAltName=DNS:example.com,DNS:www.example.com"

# Self-signed (dev only)
openssl req -x509 -days 365 -key rsa.pem -out cert.pem \
  -subj "/CN=example.com" \
  -addext "subjectAltName=DNS:example.com"
```

`-addext` is the modern way; the old `-extensions` + `openssl.cnf` dance is no longer needed in OpenSSL 1.1.1+.

## Cipher suites

- **List available with hex codes:** `openssl ciphers -V 'ECDHE+AESGCM:!aNULL'`. `-V` shows hex / proto / Kx / Au / Enc / Mac columns.
- **Naming differs by version:**
  - TLS 1.2: `ECDHE-RSA-AES256-GCM-SHA384` (hyphen-separated, openssl-flavored)
  - TLS 1.3: `TLS_AES_256_GCM_SHA384` (underscore, IANA name)
- **TLS 1.3 has only 5 standard suites** (RFC 8446 §B.4): `TLS_AES_128_GCM_SHA256`, `TLS_AES_256_GCM_SHA384`, `TLS_CHACHA20_POLY1305_SHA256`, `TLS_AES_128_CCM_SHA256`, `TLS_AES_128_CCM_8_SHA256`. Only AEAD; key exchange and auth are decoupled into separate extensions.
- **TLS 1.3 mandatory: ECDHE only.** Static RSA key exchange removed (RFC 8446 §1.2). Forward secrecy is non-optional.
- **DH params largely historical.** `openssl dhparam -out dh2048.pem 2048` only matters for legacy `DHE-*` suites on TLS 1.2. With TLS 1.3 + ECDHE the file is irrelevant. Logjam (2015) mitigated by ≥2048-bit groups.

## ACME (RFC 8555) — challenge mechanics

Three challenge types. Pick based on what you control.

- **HTTP-01** (RFC 8555 §8.3): server serves the key authorization at exactly `/.well-known/acme-challenge/<TOKEN>` over **port 80**. Validation server follows redirects to 443, but the initial request is plain HTTP. Cannot validate wildcards.
- **TLS-ALPN-01** (RFC 8737): server presents a self-signed cert on **port 443** when the client negotiates ALPN protocol `acme-tls/1`. Cert must contain the `id-pe-acmeIdentifier` extension (OID `1.3.6.1.5.5.7.1.31`) with the SHA-256 hash of the key authorization. Useful when you can't open port 80 but can intercept ALPN on 443.
- **DNS-01** (RFC 8555 §8.4): TXT record at `_acme-challenge.<DOMAIN>` containing the base64url-encoded SHA-256 of the key authorization. **Only challenge that supports wildcards** (`*.example.com`).

### Let's Encrypt rate limits (production)

Hit these and you're locked out for a week. Memorise:

- **50 certificates per registered domain per 7 days.** "Registered domain" = public-suffix + 1 label (so `a.example.com` and `b.example.com` share the bucket).
- **5 duplicate certs per 7 days** — exact same set of identifiers.
- **5 failed authorizations per account per host per hour.**
- **300 new orders per account per 3 hours.**
- **10 accounts per IPv4 per 3 hours; 500 per /48 IPv6 per 3 hours.**

**Always test on staging first:** `https://acme-staging-v02.api.letsencrypt.org/directory` — same protocol, vastly higher limits, certs are not publicly trusted. Production: `https://acme-v02.api.letsencrypt.org/directory`.

Cert lifetime: **90 days**. Convention: renew at **30 days remaining** (60 days post-issue).

## OCSP and Must-Staple

- **Manual query** (debug a responder):
  ```bash
  openssl ocsp -issuer issuer.pem -cert leaf.pem \
    -url http://r3.o.lencr.org -resp_text -no_nonce -CAfile root.pem
  ```
  `-no_nonce` is needed because most production responders return cached responses and reject nonce extensions.
- **Stapling = server-side fetch.** Server queries the CA's OCSP responder, caches the response, attaches to the TLS handshake in the `status_request` extension. Client trusts the staple (signed by the CA) — no direct client→CA query.
- **Verify stapling.** `openssl s_client -connect host:443 -servername host -status </dev/null` and look for `OCSP response:` block. Empty = server isn't stapling.
- **Server config:**
  - Nginx: `ssl_stapling on; ssl_stapling_verify on; resolver 1.1.1.1 valid=300s; ssl_trusted_certificate chain.pem;`
  - Apache: `SSLUseStapling on; SSLStaplingCache shmcb:/var/run/ocsp(128000);`
  - Caddy: stapling is automatic, no flag.
- **Must-Staple (RFC 7633).** Cert with the `status_request` TLS feature extension means **clients MUST reject the handshake if no OCSP response is stapled**. Once enabled, stapling failure breaks the site for compliant clients (Firefox, some Chrome paths). Don't enable until stapling is rock-solid.
- **OCSP wind-down.** Let's Encrypt is removing OCSP support in 2025; Apple and Google trust stores moving to CRLite / CRLSets. OCSP increasingly legacy.

## TLS 1.3 specifics

- **Encrypted handshake.** Everything after `ServerHello` is encrypted. Wireshark without keylog file shows opaque bytes — set `SSLKEYLOGFILE=/path/to/keylog` env for `curl`/Chrome to dump session keys.
- **0-RTT (early data).** Client sends application data in the first flight using a PSK from a prior session. **Replay-vulnerable** for non-idempotent requests (POST/PUT). Servers must implement single-use tickets or strict-transport semantics. Opt-in only.
- **SNI still plaintext.** Encrypted Client Hello (ECH, RFC 9180 + drafts) hides SNI but is not yet universally deployed. SNI sniffing in middleboxes still works.
- **Certificate verification still your job.** Forward secrecy ≠ identity. ECDHE protects against passive recording but does nothing against MITM with a forged cert.

## mTLS

- **Server config:** require client cert AND verify against a CA bundle. Nginx: `ssl_verify_client on; ssl_client_certificate ca-bundle.pem;`. Apache: `SSLVerifyClient require; SSLCACertificateFile ca-bundle.pem;`.
- **Test from CLI:**
  ```bash
  curl --cert client.pem --key client.key https://api.internal/

  openssl s_client -connect api.internal:443 -servername api.internal \
    -cert client.pem -key client.key
  ```
- **EKU on client cert** must be `clientAuth` (OID `1.3.6.1.5.5.7.3.2`), not `serverAuth`. CAs sometimes issue with both; check via `openssl x509 -noout -ext extendedKeyUsage`.
- **Common in service meshes.** Istio / Linkerd / Consul Connect rotate short-lived (hours) certs via SPIFFE/SPIRE. Don't try to debug mesh mTLS with hand-rolled CSRs — use the mesh's CLI.

## File-format conversions

- **PEM** = base64-armored DER, `-----BEGIN ...-----` markers. Default for openssl.
- **DER** = raw binary ASN.1. Java and some embedded systems prefer.
- **PKCS#12 / `.p12` / `.pfx`** = bundle of key + cert chain in one password-protected file. Windows / Java / iOS native format.
- **JKS** (Java KeyStore) — deprecated since Java 9; new code should use PKCS#12.

```bash
# PEM cert → DER
openssl x509 -in cert.pem -outform DER -out cert.der

# PEM key + chain → PKCS#12
openssl pkcs12 -export -in cert.pem -inkey key.pem \
  -certfile chain.pem -name myalias -out bundle.p12

# PKCS#12 → PEM (key + cert in one file, unencrypted key)
openssl pkcs12 -in bundle.p12 -nodes -out cert+key.pem
# OpenSSL 3.0+: -nodes is deprecated; use -noenc instead.

# PKCS#12 → JKS (via keytool)
keytool -importkeystore -srckeystore bundle.p12 -srcstoretype PKCS12 \
  -destkeystore store.jks -deststoretype JKS

# JKS → PKCS#12
keytool -importkeystore -srckeystore store.jks \
  -destkeystore bundle.p12 -deststoretype PKCS12
```

`-nodes` / `-noenc` means "no DES encryption on the private key" — required when the consumer (Nginx, HAProxy) reads the file directly. Without it, the key file is itself encrypted with a password.

## Diagnostic flow — "why is this not connecting"

Step through in order; the failure mode tells you the layer.

1. **`telnet host 443` / `nc -vz host 443`** — pure TCP.
   - Connection refused → server not listening / firewall RST.
   - Timeout (no RST) → network drop / firewall blackhole.
   - Connects → move to TLS layer.
2. **`openssl s_client -connect host:443 -servername host </dev/null`** with no version flags.
   - "no protocols available" → version mismatch. Re-run with `-tls1_2` then `-tls1_3` to find what the server speaks.
   - "alert handshake failure" / "no shared cipher" → cipher mismatch. Try with explicit `-cipher` to bisect.
   - "tlsv1 alert unknown ca" → client doesn't trust the CA; check chain.
   - Connects but `Verify return code` ≠ 0 → see X509_V_ERR section above.
3. **Add `-showcerts`** — dump the chain. Compare leaf SAN to the hostname. Compare what's served vs what the chain requires. Missing intermediate = #20 verify error.
4. **`-status`** — is OCSP stapling working? Check expiry of stapled response (responder might be down).
5. **`-alpn h2,http/1.1`** — negotiated protocol matches what the client expects?
6. **`curl -vvv https://host/`** — different stack, different trust store. If `s_client` works and `curl` doesn't, the system trust store is suspect.
7. **`testssl.sh host`** — comprehensive third-party check; flags vulns, weak ciphers, cert problems in one report.

Common failure → likely cause:
- "Certificate expired" → check `notAfter`; check renewal cron / certbot timer.
- "Unable to get local issuer" → server is missing intermediate. Fix server, not client.
- "Hostname mismatch" → SAN doesn't include the requested name; check `-servername` matches what the client sends.
- "no peer certificate available" → server errored before sending cert. Check server logs; usually SNI mismatch or wrong vhost selected.
- "wrong cert served" → SNI bug (often missing `-servername` in your test).

## Certificate Transparency

- **All public certs are logged.** Browsers (Chrome since 2018, Apple since 2021) reject certs without ≥2 SCTs from approved logs.
- **SCT delivery (RFC 6962):** embedded in cert as X.509 extension (OID `1.3.6.1.4.1.11129.2.4.2`), or via OCSP stapling extension (OID `1.3.6.1.4.1.11129.2.4.5`), or as a TLS extension. Most CAs use embedded.
- **Lookup by domain:** `crt.sh` indexes all public CT logs. Useful for finding shadow IT, expired-but-still-served certs, or unauthorized issuance.
- **Inspect SCTs in a cert:** `openssl x509 -in cert.pem -noout -text` — look for "CT Precertificate SCTs" block.

## Tooling beyond openssl

- **`testssl.sh`** — bash script, comprehensive cipher/cert/vuln scan. Best single-shot audit tool.
- **`mkcert`** (filippo.io/mkcert) — local CA for development; auto-installs into OS + browser trust stores. Use this instead of self-signed certs in dev.
- **`step-cli`** (Smallstep) — saner ACME client + PKI tooling than openssl for many workflows. `step certificate inspect` beats `openssl x509 -text`.
- **`cfssl`** (Cloudflare) — JSON-driven CSR/cert generation; good for automation.
- **SSL Labs** (`ssllabs.com/ssltest`) — public-facing scan with grade. Slow but authoritative.

## Authoritative references

**OpenSSL manpages** (`docs.openssl.org/master/man1/`):
- [openssl-s_client](https://docs.openssl.org/master/man1/openssl-s_client/)
- [openssl-x509](https://docs.openssl.org/master/man1/openssl-x509/)
- [openssl-verify](https://docs.openssl.org/master/man1/openssl-verify/)
- [openssl-genpkey](https://docs.openssl.org/master/man1/openssl-genpkey/)
- [openssl-pkcs12](https://docs.openssl.org/master/man1/openssl-pkcs12/)
- [openssl-ocsp](https://docs.openssl.org/master/man1/openssl-ocsp/)
- [openssl-ciphers](https://docs.openssl.org/master/man1/openssl-ciphers/)

**RFCs (datatracker.ietf.org):**
- [RFC 8446 — TLS 1.3](https://datatracker.ietf.org/doc/html/rfc8446)
- [RFC 8555 — ACME](https://datatracker.ietf.org/doc/html/rfc8555)
- [RFC 8737 — TLS-ALPN-01](https://datatracker.ietf.org/doc/html/rfc8737)
- [RFC 7633 — TLS Feature / Must-Staple](https://datatracker.ietf.org/doc/html/rfc7633)
- [RFC 6962 — Certificate Transparency](https://datatracker.ietf.org/doc/html/rfc6962)

**Let's Encrypt:**
- [Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Challenge Types](https://letsencrypt.org/docs/challenge-types/)

**Reliable operational deep-dives:**
- Filippo Valsorda (filippo.io) — TLS 1.3 internals, age, mkcert
- Daniel Stenberg (daniel.haxx.se) — curl-side TLS practice
- Mozilla SSL Configuration Generator — server-side template

## Guardrails

Before recommending a non-trivial TLS change (cipher policy, ACME automation, OCSP must-staple, mTLS rollout):

1. Quote the exact openssl flag, RFC section, or X509_V_ERR code that motivates the change.
2. Cite the official manpage / RFC URL.
3. **Always test on staging** for ACME — a botched test on production locks you out for a week.
4. **Never claim "it's working" without** running `openssl s_client -connect host:443 -servername host -verify_return_error </dev/null` end-to-end and reading `Verify return code: 0 (ok)`.

**Tuning without measurement is worse than defaults.**

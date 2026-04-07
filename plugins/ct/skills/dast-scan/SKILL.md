---
name: dast-scan
description: >
  Dynamic Application Security Testing with two tiers: Nuclei (fast, template-based) and ZAP (deep, active scanning via Docker). Use when asked to scan for vulnerabilities, run a security scan, DAST scan, pen test the app, check for XSS/SQLi/CSRF, scan for security issues on a running app, or after deploying a local dev server. Complements threat-modeling (design-time) with runtime verification. Triggers on: vulnerability scan, security scan, DAST, pen test, penetration test, XSS, SQL injection, CSRF, "is this secure" (for running apps), "scan my app", "check for vulnerabilities", "find security issues".
---

# DAST Security Scan

Two-tier dynamic security scanning: Nuclei for fast template-based scanning (1-5 min), ZAP for deep active scanning via Docker (5-30 min).

Complements `threat-modeling` (design-time STRIDE analysis) with runtime vulnerability verification.

## Phase 1: Target Verification

Before scanning, verify the target is reachable and gather information.

1. **Determine target URL:**
   - If user provided a URL → use it
   - Otherwise → check common localhost ports: `curl -s -o /dev/null -w "%{http_code}" http://localhost:PORT` for ports 3000, 8080, 5173, 4200, 8000, 5000
   - If no server found → STOP: "No running server detected. Start your dev server and provide the URL."

2. **Check for OpenAPI/Swagger spec** (enables API-specific scanning):
   - Try common paths: `/openapi.json`, `/swagger.json`, `/api-docs`, `/docs/openapi.json`, `/api/openapi.json`
   - If found → note for ZAP API scan mode in Tier 2

3. **Check for authenticated endpoints:**
   - Try a few API paths and look for 401/403 responses
   - Check for OpenAPI security schemes in the spec
   - If auth detected → ask user:

   ```
   Authenticated endpoints detected. How should I authenticate?
   A) Bearer token — paste your token
   B) Username/password + login endpoint URL
   C) Cookie value — paste the Cookie header
   D) Skip authenticated endpoints
   ```

   For option B: hit the login endpoint, extract token/cookie from response, use for scanning.

4. Report: "Target: http://localhost:3000 (reachable). OpenAPI spec: found at /openapi.json. Auth: Bearer token configured."

## Phase 2: Nuclei Scan (Tier 1)

Fast template-based scanning. Always runs first.

1. **Run Nuclei with smart template selection:**

```bash
nuclei -u <TARGET_URL> -severity critical,high,medium -as -json-export /tmp/nuclei-results.json
```

Flags:
- `-severity critical,high,medium` — skip low/info noise
- `-as` — auto-smart: detect tech stack, select relevant templates
- `-json-export` — machine-readable output

If authenticated, add headers:
```bash
nuclei -u <TARGET_URL> -severity critical,high,medium -as -json-export /tmp/nuclei-results.json -H "Authorization: Bearer <TOKEN>"
```
or:
```bash
nuclei -u <TARGET_URL> -severity critical,high,medium -as -json-export /tmp/nuclei-results.json -H "Cookie: <COOKIE_VALUE>"
```

2. **Parse JSONL output.** Each line is a JSON object with:
   - `template-id`: which template matched (e.g., `cves/2024/CVE-2024-1234`)
   - `info.severity`: critical, high, medium
   - `info.name`: human-readable vulnerability name
   - `info.description`: what the vulnerability is
   - `matched-at`: the URL that triggered the match
   - `matcher-name`: specific matcher within the template

3. **Map findings to source code** where possible:
   - Extract URL paths from `matched-at`
   - Grep for route handlers matching those paths (e.g., `app.post('/api/users/search'` or `@app.route('/api/users/search')`)
   - Present with source file reference when found

4. **Present findings:**

```
NUCLEI SCAN RESULTS (Tier 1 — template-based, 1-5 min)

[CRITICAL] Remote Code Execution — GET /api/debug/eval
  Template: nuclei:cves/2024/CVE-2024-XXXX
  Evidence: Response contains command output
  Source: src/routes/debug.ts:12 (route handler for /api/debug/eval)
  Fix: Remove debug endpoint from production, or add authentication + input sanitization

[HIGH] SQL Injection — POST /api/users/search
  Template: nuclei:vulnerabilities/sqli-error-based
  Evidence: Parameter "query" reflects error: "You have an error in your SQL syntax"
  Source: src/routes/users.ts:45 (route handler for /api/users/search)
  Fix: Use parameterized queries instead of string concatenation

[MEDIUM] Missing CSRF Token — POST /api/settings/update
  Template: nuclei:vulnerabilities/csrf-detection
  Evidence: No CSRF token in form submission
  Fix: Add CSRF middleware to the route
```

**STOP** — Present Nuclei findings. Ask: "Found N vulnerabilities. Want a deeper scan with ZAP? Options: passive only (~5 min) or full active scan (~15-30 min). Note: active scanning may modify data — only run against ephemeral/dev environments."

## Phase 3: ZAP Scan (Tier 2, Opt-In)

Deep scanning with crawling, spidering, and active injection testing. Requires Docker.

1. **Check Docker availability:**
   ```bash
   command -v docker && docker info
   ```
   If Docker is not available → STOP: "Docker is required for ZAP scanning. Install Docker (https://docs.docker.com/get-docker/) or run `tools/dast.sh` to set up. Nuclei results above are still valid."

2. **Detect OS for Docker networking:**
   - macOS: use `host.docker.internal` instead of `localhost` in target URL
   - Linux: use `--network host` and `localhost` directly
   ```bash
   if [[ "$(uname)" == "Darwin" ]]; then
       ZAP_TARGET="${TARGET_URL//localhost/host.docker.internal}"
   else
       ZAP_TARGET="$TARGET_URL"
   fi
   ```

3. **Run ZAP scan:**

   Passive/baseline scan (user chose "passive only"):
   ```bash
   docker run --rm --network host -v /tmp:/zap/wrk:rw zaproxy/zap-stable zap-baseline.py -t <ZAP_TARGET> -J zap-report.json
   ```

   Full active scan (user chose "full active scan"):
   ```bash
   docker run --rm --network host -v /tmp:/zap/wrk:rw zaproxy/zap-stable zap-full-scan.py -t <ZAP_TARGET> -J zap-report.json -m 15
   ```
   `-m 15` limits active scan to 15 minutes.

   API scan (if OpenAPI spec was found in Phase 1):
   ```bash
   docker run --rm --network host -v /tmp:/zap/wrk:rw zaproxy/zap-stable zap-api-scan.py -t <ZAP_TARGET>/openapi.json -f openapi -J zap-report.json
   ```

   Exit codes: 0 = clean, 1 = error, 2 = warnings (findings).

4. **Parse ZAP JSON report.** Key fields:
   - `site[].alerts[]`: array of findings
   - Each alert: `pluginid`, `alert` (name), `riskdesc` (severity), `desc` (description), `solution`, `uri` (affected URLs), `evidence`

5. **Deduplicate against Nuclei results.** Match by:
   - Affected URL path
   - Vulnerability category (XSS, SQLi, CSRF, etc.)
   - Skip ZAP findings already reported by Nuclei

6. **Present ZAP-only findings:**

```
ZAP SCAN RESULTS (Tier 2 — active scanning, new findings only)

[HIGH] Cross-Site Scripting (Reflected) — GET /search?q=<script>
  Alert: 40012
  Evidence: Response contains unescaped user input in HTML context
  Source: src/routes/search.ts:23 (search query handler)
  Fix: Escape HTML output using framework's built-in XSS protection

[MEDIUM] Cookie Without Secure Flag
  Alert: 10011
  Evidence: Set-Cookie header missing Secure attribute
  Fix: Set secure: true in cookie configuration
```

## Phase 4: Summary

Present a consolidated summary:

```
SCAN SUMMARY

Target: http://localhost:3000
Scans: Nuclei (Tier 1) + ZAP baseline (Tier 2)

Findings by severity:
  Critical: 1
  High:     3
  Medium:   5
  Total:    9

Recommended fix priority:
  1. [CRITICAL] Remote Code Execution — remove debug endpoint
  2. [HIGH] SQL Injection — parameterize queries in users route
  3. [HIGH] XSS — escape output in search route
  ...

Next steps:
  - Fix critical and high findings first
  - Re-run scan after fixes to verify remediation
  - Consider threat-modeling skill for design-level security analysis
```

## Integration with Other Skills

- **After `threat-modeling`**: Run DAST to validate that identified threats are mitigated
- **Before `security-review`**: DAST findings focus the code review on concrete vulnerabilities
- **With `find-bugs`**: DAST covers runtime issues that static analysis misses

## Limitations

- Active scanning (ZAP full scan) can modify data — always warn before running
- Cannot test business logic flaws (IDOR, broken access control) — use `threat-modeling` for those
- Nuclei is template-based — may miss novel vulnerability patterns
- ZAP active scans can be slow (10-30 min) on large applications
- Docker required for ZAP tier; Nuclei works without Docker
- macOS Docker networking requires `host.docker.internal` workaround

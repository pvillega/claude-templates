---
name: hetzner
description: >
  Deep Hetzner operational intuition — Cloud vs Robot vs Storage Box product split,
  server-type taxonomy (cx/cpx/ccx/cax/ax), region/feature availability matrix,
  IPv4 cost model, free egress caps, snapshot vs backup vs image distinctions,
  firewall default-deny semantics, hcloud CLI patterns, API token scoping,
  Floating-IP guest-side aliasing, cloud-init datasource, Terraform provider drift.
  Load ONLY when the task is about choosing/sizing Hetzner resources, planning a
  migration to/from Hetzner, automating with hcloud/Terraform/cloud-init, or
  diagnosing Hetzner-specific gotchas. Do NOT load for generic IaaS questions,
  Linux admin, or non-Hetzner clouds — those don't need this skill.
  Triggers on: "hetzner cloud", "hcloud cli", "hcloud_server", "cax11",
  "cpx21", "ccx", "fsn1", "nbg1", "hel1", "ashburn hetzner",
  "hetzner robot", "ax101", "hetzner snapshot", "hetzner backup",
  "primary ip cost", "without-ipv4", "vswitch", "floating ip hetzner",
  "hetzner firewall", "storage box", "hetzner load balancer".
---

# Hetzner Operational Guide

Concise operational pointers for working across Hetzner Cloud, Robot, and Storage Box.

Assumes you know generic IaaS — VMs, VPCs, snapshots, load balancers, cloud-init. This skill covers the **Hetzner-specific** parts models gloss over: the three-product split, server-type codes, region gaps, the IPv4 cost trap, and the snapshot/backup/image distinction.

## When to use

Load when the question is about:
- Choosing a Hetzner server type / location (cx vs cpx vs ccx vs cax; fsn1 vs ash vs sin)
- Planning IP cost (IPv4 fee, opt-out, primary-IP lifecycle)
- Differentiating snapshots vs backups vs images
- hcloud CLI flags and multi-project context
- Hetzner Cloud API rate limits, pagination, token scope
- Firewall default policy and rule limits
- Load Balancer plan sizing (LB11/21/31) and managed certs
- Private Network / vSwitch (Cloud-to-Robot bridging)
- Floating IPs and reverse DNS
- cloud-init on Hetzner servers
- Terraform `hcloud` provider state drift
- Robot rescue system / dedicated server provisioning

**Do NOT load** for: generic Linux admin, generic Postgres/Docker/k8s questions, non-Hetzner cloud comparisons unless Hetzner is the target.

## Three products, three APIs, three bills

- **Hetzner Cloud** (`cloud.hetzner.com`, API `api.hetzner.cloud`): hourly-billed VPS, snapshots, networks, LBs. Console + REST + hcloud CLI + Terraform.
- **Hetzner Robot** (`robot.hetzner.com`): monthly-billed dedicated bare metal (AX/EX/RX/SX/GPU lines). Separate API, separate auth, separate invoice. Setup fees may apply.
- **Storage Box** (`hetzner.com/storage/storage-box`): FTP/SFTP/SCP/FTPS/SMB/WebDAV/SSH (ports 22 + 23) bulk storage, unlimited traffic, sub-accounts (≤100), 10 simultaneous connections per account.
- **Bridge**: a `vSwitch` connects a Cloud Private Network to Robot dedicated servers (one vSwitch per network, max).

## Server-type taxonomy

Codes are stable identifiers — use the exact code with hcloud / Terraform.

- **cx** (Intel x86, shared vCPU): cost-optimized. Current generation `cx22/cx32/cx42/cx52` was deprecated in Jan 2026; `cx23/cx33/cx43/cx53` is the live cost-optimized line.
- **cpx** (AMD EPYC x86, shared vCPU): regular performance. `cpx11/cpx21/.../cpx51` deprecated; `cpx12/cpx22/.../cpx62` is the current generation.
- **ccx** (dedicated x86 vCPU): guaranteed cycles, e.g. `ccx13`. For DBs, CPU-bound services.
- **cax** (Arm Ampere, shared vCPU): `cax11/cax21/cax31/cax41`. Available since April 2023. **Arm-only — verify ARM image variant exists for your distro before recommending.**
- **ax / ex / rx / sx / gpu** (Robot dedicated): bare metal lines, separate product. `ax101` is AMD; `rx` is Arm64; `gpu` is for AI workloads.

`hcloud server-type list -o json` is canonical for the *current* matrix and per-location pricing — never hardcode prices, server-types churn (deprecations every ~12-18 months).

## Locations and feature gaps

Six locations, four network zones:

| Code   | City              | Zone            |
|--------|-------------------|-----------------|
| fsn1   | Falkenstein, DE   | eu-central      |
| nbg1   | Nuremberg, DE     | eu-central      |
| hel1   | Helsinki, FI      | eu-central      |
| ash    | Ashburn, VA, US   | us-east         |
| hil    | Hillsboro, OR, US | us-west         |
| sin    | Singapore         | ap-southeast    |

Gotchas:
- **Object Storage**: fsn1, nbg1, hel1 only.
- **Robot dedicated**: not available in ash / hil / sin.
- **Cloud Shared (Intel/AMD/Ampere)**: documented availability is the three EU locations; verify before placing cax/cpx servers in US/SIN — gaps appear and shift.
- **All locations within a single Network must be in the same network zone.** You cannot put a fsn1 server and an ash server in one Private Network.
- Floating IPs and IP-targeted Load Balancers are zone-bound; IP-based LB targets are EU-Central-only.

## Networking and the IPv4 cost trap

- **IPv4 is paid, IPv6 is free.** Primary IPv4 ≈ €0.50/month (€0.0008/h). IPv6 is free.
- **No public NIC unless a Primary IP is assigned.** `hcloud server create --without-ipv4` skips IPv4. `--without-ipv6` exists but rarely useful.
- **Trap**: deleting a server does NOT free its Primary IP. The IP keeps billing until you `hcloud primary-ip delete`. Detached IPs are silent cost.
- **Free egress** is bundled per server type (typically 20 TB/month on common types — verify per type via `hcloud server-type list -o json`). Overage is billed in 100 MB blocks. Inbound and Hetzner-internal traffic is free.
- **Private Networks**: free, ≤100 attached resources (servers + LBs combined) per network, ≤50 subnets per network, ≤3 networks per server, ≤5 alias IPs per server.
- **Floating IPs** vs **Primary IPs**: Floating IPs reassign across servers in the same zone. Both server's Primary IP and the assigned Floating IP must match family (IPv4↔IPv4). **Floating IP is not Anycast** and requires in-guest network alias config (the guest does not learn about it from DHCP — add the IP to the interface manually or via cloud-init `write_files` netplan).
- **Reverse DNS (PTR)**: settable on Primary IP and Floating IP only, via Console or `hcloud primary-ip set-rdns` / API.

## Firewalls

- **No firewall attached → all in/out allowed.** This is the default for new servers.
- **Firewall attached → default-deny inbound, default-allow outbound.** Add explicit inbound rules or you lock yourself out of SSH.
- Limits: ≤500 effective rules per firewall, ≤5 firewalls per server, ≤50 firewalls per project.
- Stateful behavior is not explicitly documented — assume conservative semantics and test return-traffic rules.

## Snapshots vs Backups vs Images — different products

- **Image** (Hetzner-provided): free, fixed OS images (Debian, Ubuntu, Rocky, etc.), cloud-init compatible. Base for `hcloud server create --image debian-12`.
- **Snapshot**: manual disk capture. Persists until you delete it. Billed per-GB-month ongoing. Project default: ≤30 snapshots. Usable as `--image` source for new servers.
- **Backup**: opt-in per-server (`--enable-backup` or post-create). Surcharge ≈ 20% of server price. **Exactly 7 backup slots, rotated daily**: oldest is deleted when the 8th is created. Cannot pull individual files; must restore whole backup or **promote a backup to a snapshot** (then live independently of the server).
- **Source-server deletion**: snapshots are independent and survive. Backup behavior on server deletion is *not clearly documented* — promote critical backups to snapshots before deleting the server.

## hcloud CLI

Install via Homebrew (`brew install hcloud`), Go install, or release binary.

- **Auth**: project tokens via `hcloud context create <name>` then `hcloud context use <name>`. One context = one token = one project. Multi-project = multiple contexts.
- **Token scope**: a single token grants either Read or Read+Write to **the entire project**. There are no sub-roles, no per-resource ACL. If a workflow needs least-privilege at sub-project granularity, split into multiple projects.
- **Output**: `-o json`, `-o yaml`, `-o columns=name,type,location,status` for scripting.
- **Create server**:
  ```
  hcloud server create \
    --name web1 \
    --type cpx21 \
    --image debian-12 \
    --location fsn1 \
    --ssh-key my-key \
    --network mynet \
    --firewall web-fw \
    --without-ipv4 \
    --user-data-from-file cloud-init.yml \
    --enable-backup \
    --label env=prod
  ```
- Other useful flags: `--primary-ipv4 <id>` (attach existing paid IP), `--placement-group <id>` (anti-affinity), `--enable-protection delete,rebuild` (lock from accidental destroy), `--volume <id> --automount`.

## API and rate limits

- REST at `https://api.hetzner.cloud/v1`. Bearer token in `Authorization` header.
- **Rate limit: 3600 requests/hour per project.** Headers: `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset` (UNIX ts). Refills 1 req/sec.
- **Pagination**: `?page=N&per_page=M`. Default `per_page=25`, **maximum `per_page=50`** (some endpoints allow more — check the per-endpoint reference).
- High-throughput automation (cluster autoscaler, Crossplane, mass reconciliation) hits the limit easily; backoff and cache `server-type list` / `image list`.

## Load Balancers

- Three plans:
  - **LB11**: 5 services, 25 targets, 10 SSL certs, 1 TB included, ≤10k connections.
  - **LB21**: 15 services, 75 targets, 25 certs, 2 TB, ≤20k connections.
  - **LB31**: 30 services, 150 targets, 50 certs, 3 TB, ≤40k connections.
- Targets: server IDs (preferred, by-IP also possible). In a Private Network, target by private IP.
- Algorithms: round-robin, least-connections.
- **Managed Let's Encrypt cert**: requires Hetzner DNS as authoritative (or ACME-challenge delegation to Hetzner DNS via CNAME). Hetzner handles renewal. Otherwise upload your own cert.
- Health checks: TCP, HTTP, HTTPS — verify per-protocol fields against the current API reference, schema can change.

## cloud-init

- Datasource name: `Hetzner` (`DataSourceHetzner` in upstream cloud-init). Metadata exposed at `http://169.254.169.254/hetzner/v1/` with `metadata` and `userdata` endpoints.
- Pass at create with `hcloud server create --user-data-from-file cloud-init.yml`.
- Hetzner injects `hostname` from server name and `ssh_authorized_keys` from project keys you pass with `--ssh-key`. Don't redundantly set these in user-data unless overriding.
- For Floating IPs, add the alias IP via `write_files` (netplan / systemd-networkd snippet) — Hetzner's DHCP does not push the floating IP to the guest.

## Terraform `hetznercloud/hcloud` provider

Resources: `hcloud_server`, `hcloud_network`, `hcloud_network_subnet`, `hcloud_network_route`, `hcloud_firewall`, `hcloud_firewall_attachment`, `hcloud_load_balancer`, `hcloud_load_balancer_service`, `hcloud_load_balancer_target`, `hcloud_volume`, `hcloud_volume_attachment`, `hcloud_floating_ip`, `hcloud_floating_ip_assignment`, `hcloud_primary_ip`, `hcloud_snapshot`, `hcloud_ssh_key`, `hcloud_certificate`, `hcloud_placement_group`.

Drift gotchas:
- `hcloud_server.image` drifts as the source image is updated by Hetzner; pin to specific image versions or use `lifecycle.ignore_changes = ["image"]`.
- `hcloud_snapshot` references its source server — if the server is recreated, the snapshot resource may need re-import.
- Rebuild changes the disk; Terraform will recreate `hcloud_server` on `image` change unless ignored.

## Robot specifics

- **Rescue system**: PXE-booted Debian environment. Activated via Robot UI per-server, valid for **one boot, expiring after 60 minutes if not rebooted into**. SSH on port 22 or 222 as root with provided creds. Use for password reset, fsck, fresh OS install via `installimage`.
- **vKVM** (KVM-over-IP): request via Robot UI; for low-level boot/BIOS access when even rescue won't help.
- **BGP / extra IP ranges**: /28 and larger ranges and BGP sessions handled via Robot ticket / UI, not programmatic.
- **Auth**: Robot uses webservice credentials, NOT Cloud project tokens. Distinct API.

## Common pitfalls

- **IPv4 cost survives `server delete`** — separately delete the Primary IP.
- **Backups are 7-slot rotating, not archival** — promote anything you want to keep to a snapshot.
- **Rebuild is destructive of disk** (`hcloud server rebuild` with new image wipes it). **Server-type change ("rescale") preserves disk** for upgrades; downgrade may be blocked if the new disk is smaller than current usage.
- **Floating IP needs in-guest config** — assigning via API/UI is half the work; the guest must add the IP as an alias.
- **PTR records are manual** — set per IP; no auto-PTR from hostname.
- **One project token = full project access** — segment workloads across projects for blast-radius control, not via token roles.
- **API rate limit is per project**, so a noisy autoscaler can starve other tooling sharing the same project.
- **`cax` Arm coverage** is incomplete in some regions and some images — check region + image variant before recommending.
- **Network zone mismatch** silently rejects subnet/server attachment to a Private Network spanning zones.

## Authoritative references

**Cloud docs** (`docs.hetzner.com/cloud/`):
- [Locations](https://docs.hetzner.com/cloud/general/locations)
- [Networks overview](https://docs.hetzner.com/cloud/networks/overview)
- [Firewalls overview](https://docs.hetzner.com/cloud/firewalls/overview)
- [Backups & snapshots](https://docs.hetzner.com/cloud/servers/backups-snapshots/overview)
- [Primary IPs](https://docs.hetzner.com/cloud/servers/primary-ips/overview)
- [Floating IPs](https://docs.hetzner.com/cloud/floating-ips/overview)
- [Load Balancer FAQ](https://docs.hetzner.com/cloud/load-balancers/faq)

**Cloud API** (`docs.hetzner.cloud`):
- [API reference](https://docs.hetzner.cloud/reference/cloud) — rate limits, pagination, auth
- [Changelog](https://docs.hetzner.cloud/changelog) — server-type generations, location additions, deprecations

**Tooling**:
- [hcloud CLI](https://github.com/hetznercloud/cli)
- [Terraform provider](https://github.com/hetznercloud/terraform-provider-hcloud)
- [cloud-init Hetzner datasource](https://github.com/number5/cloud-init/blob/main/cloudinit/sources/DataSourceHetzner.py)

**Robot / Storage Box**:
- [Robot rescue system](https://docs.hetzner.com/robot/dedicated-server/troubleshooting/hetzner-rescue-system)
- [Storage Box](https://docs.hetzner.com/storage/storage-box/general/)
- [Dedicated server lines](https://www.hetzner.com/dedicated-rootserver/)

**Status / community**:
- `status.hetzner.com` for ongoing incidents
- `community.hetzner.com/tutorials` for vetted how-tos (e.g. cert-manager + Hetzner DNS, basic cloud-config)

## Guardrails

Before recommending any non-trivial Hetzner change (server type, location, IP attachment, backup strategy):
1. Quote the exact resource code (`cpx21`, `cax11`, `LB21`, location `fsn1`).
2. Verify availability of that resource in the target location and image — `hcloud server-type list -o json` and `hcloud location list -o json`.
3. State the IPv4 cost and whether `--without-ipv4` is appropriate.
4. Cite the official Hetzner doc page or hcloud command for the recommendation.

**Pricing and limits change. Always verify the current value at hetzner.com or docs.hetzner.com before quoting numbers.**

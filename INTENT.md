# INTENT.md — J1-PIPELINE Phase -1 (ORACLE)

**Repository:** `OneByJorah/EdgeGateway`
**Analysis Date:** 2026-07-05
**Analyst:** J1-PIPELINE ORACLE (read-only)
**Status:** Intent Reconstructed

---

## What This System Does

**EdgeGateway** is a two-script provisioning system that transforms a Raspberry Pi (or any Debian/Ubuntu ARM host) into a self-contained secure edge gateway. It combines four subsystems into a single, repeatable deployment:

| Subsystem | Role | Technology |
|-----------|------|------------|
| **WiFi Access Point** | Creates an internal hotspot (`wlan0`) for client devices to connect | `hostapd` + `dnsmasq` |
| **WARP Tunnel** | Routes *all* traffic (AP clients + WAN uplink) through Cloudflare's encrypted tunnel for DNS privacy and outbound proxying | `cloudflare-warp` client |
| **Monitoring Dashboard** | Real-time web UI showing WARP status, CPU/RAM/temperature, connected clients, throughput, and traffic totals | Flask + Flask-SocketIO + eventlet |
| **Telegram Bot** | Remote management via Telegram — status queries, WARP toggle/reconnect, service restart, Pi reboot | `python-telegram-bot` (v20.8) |

### Technical Architecture

```
[ISP Router] --eth0--> [Raspberry Pi] --wlan0 (AP)--> [Client Devices]
                           |
                     Cloudflare WARP tunnel
                           |
                    [Cloudflare Edge]
                           |
                      [Internet]
```

- **eth0** = WAN uplink from ISP router (LAN cable)
- **wlan0** = WiFi Access Point (internal hotspot, SSID: `PiGateway`)
- **CloudflareWARP** = virtual tunnel interface — all forwarded traffic is MASQUERADEd through it
- **Fallback**: If WARP is down, traffic routes via raw WAN (eth0) as a degraded fallback
- **WARP Watchdog**: Cron job every 60s that reconnects WARP if the tunnel drops

### Key Components

| File | Purpose |
|------|---------|
| `01_install.sh` | System update, dependency install (hostapd, dnsmasq, iptables, Python), Cloudflare WARP client, Python venv with Flask/SocketIO/Telegram, hostapd config, dnsmasq config, iptables NAT rules, WARP registration, service enablement |
| `02_configure.sh` | WARP watchdog script, gateway stats helper (`gw-stats.sh`), Flask dashboard app (`dashboard.py`), Telegram bot (`bot.py`), systemd units for both services |
| `templates/dashboard.html` | Dark-themed real-time dashboard with stats cards, control buttons, and DHCP lease table |

### API Surface (Dashboard)

| Endpoint | Method | Action |
|----------|--------|--------|
| `/` | GET | Dashboard HTML |
| `/api/stats` | GET | JSON system stats |
| `/api/clients` | GET | JSON DHCP lease list |
| `/api/warp/toggle` | POST | Connect/disconnect WARP |
| `/api/warp/reconnect` | POST | Full WARP reconnect cycle |
| `/api/restart/<service>` | POST | Restart hostapd, dnsmasq, or warp-svc |
| `/api/reboot` | POST | Reboot the Pi |

### Telegram Bot Commands

| Command | Action |
|---------|--------|
| `/start` | Show inline keyboard menu |
| `/status` | Display full system status |
| `/clients` | List connected DHCP clients |
| Inline buttons | WARP toggle, WARP reconnect, restart hostapd/dnsmasq, reboot Pi |

### Operational Role

EdgeGateway is a **turnkey edge appliance** — deploy it on a Raspberry Pi with two commands, and it becomes a privacy-respecting WiFi hotspot that tunnels all traffic through Cloudflare WARP. It is consumed by:

- **End users** connecting to the `PiGateway` SSID — they get internet with DNS privacy (1.1.1.1) and encrypted outbound tunneling
- **The Pi's admin** — who monitors and controls the gateway via the web dashboard or Telegram bot
- **JorahOne's edge infrastructure** — as a repeatable, documented building block for privacy-first edge networking

---

## Why This Was Built

### Real Problem

Setting up a privacy-respecting edge gateway on a Raspberry Pi traditionally requires:

1. Manually configuring `hostapd` for WiFi AP mode
2. Manually configuring `dnsmasq` for DHCP/DNS
3. Manually setting up `iptables` NAT rules for traffic forwarding
4. Installing and registering a VPN/tunnel client (WireGuard, OpenVPN, or Cloudflare WARP)
5. Building a monitoring interface from scratch
6. Setting up remote management (SSH-only, no mobile-friendly option)

This is error-prone, time-consuming, and produces a fragile, non-repeatable configuration. A single typo in `dnsmasq.conf` or a missed `iptables` rule breaks the entire gateway. There is no "one command to rule them all" for Pi-based WARP gateways.

### Why Existing Tools Were Insufficient

- **Commercial travel routers (GL.iNet, etc.)**: Proprietary, limited VPN protocol support, no Cloudflare WARP integration, no programmable API surface.
- **OpenWrt**: Powerful but steep learning curve, not Raspberry Pi-native, no WARP client in package repos.
- **Pi-hole**: DNS-level only — no traffic tunneling, no WiFi AP, no remote management.
- **DIY scripts on GitHub**: Fragmented — one repo for hostapd, another for VPN, another for monitoring. No unified, tested, two-step provisioning flow.
- **Cloudflare WARP standalone**: No WiFi AP integration, no dashboard, no remote management.

EdgeGateway fills the gap: a **unified, two-command, repeatable provisioning system** that combines all of these into a single coherent deployment.

### What Triggered Development

The initial commit (`b176ed4` — "Initial commit: Pi Gateway installer scripts + docs") and the project's evolution show a clear trajectory:

1. **Initial need** (June 15, 2026): A simple Pi-based gateway with WARP tunneling. The initial commit included both root-level files AND a `pi-router/` subdirectory with duplicate files — suggesting the project was originally named `pi-router` and later renamed to `EdgeGateway`.
2. **Security hardening** (June 15, 2026): Cleanup pass (`10839ba` — "Fix: full project cleanup and security hardening").
3. **Dashboard** (June 15, 2026): Real-time monitoring UI (`41a7f55` — "Add dashboard screenshot").
4. **Repo rename** (June 17, 2026): Migrated from `pi-router` to `EdgeGateway` branding across three commits (`3bed448` → `f8601ee` → `8cf0248`).
5. **Documentation maturity** (June 17–July 4, 2026): Multiple README iterations refining the narrative, aligning to J1 brand standard, and documenting host requirements.
6. **Code quality** (July 4, 2026): Ruff auto-fixes and portfolio standardization (`1619a2b`).
7. **Dependency bumps** (July 4, 2026): Dependabot PRs for `actions/checkout` and `github/codeql-action`.
8. **Security audit** (July 5, 2026): Email reference sanitization (`6401607` — "audit(EdgeGateway): sanitize email references").

The project was built iteratively, starting from a working installer and layering on observability (dashboard), remote management (Telegram bot), reliability (WARP watchdog), and security hardening over time.

### Ecosystem Fit

EdgeGateway is part of the **OneByJorah** portfolio of infrastructure tools. It complements:

- **JorahOne's edge computing strategy**: Lightweight, ARM-optimized, privacy-first networking for edge deployments
- **The broader ecosystem**: Sits alongside other JorahOne repos as a self-contained, deployable component — not a library or framework, but a turnkey appliance
- **MIT licensing**: Open-source, community-friendly, aligned with JorahOne's permissive licensing model

```
OneByJorah Ecosystem
├── EdgeGateway          ← Turnkey Pi-based WARP gateway appliance
├── EdgeRouter           ← (sibling: router-focused infrastructure)
└── [other J1 repos]    ← Self-contained deployable components
```

---

## Operational Classification

**Classification: PRODUCTION** — this is a deployable, self-contained edge appliance with monitoring, self-healing, and a security disclosure process.

Evidence:
- **Version**: CHANGELOG.md declares v1.0.0 (though no git tag exists — minor gap)
- **Health checks**: systemd-managed services with `Restart=always` and `RestartSec=5/10`; WARP watchdog cron job for self-healing
- **CI/CD**: CodeQL analysis on push/PR + weekly schedule; Dependabot for GitHub Actions dependency updates
- **Security posture**: SECURITY.md with 90-day disclosure timeline, dedicated security contact email, iptables firewall rules, AP subnet restriction on POST endpoints, Telegram admin whitelist
- **Security audits in git history**: Two security-focused commits — `10839ba` (full project cleanup and security hardening) and `6401607` (email reference sanitization)
- **Monitoring**: Real-time web dashboard (Flask + SocketIO), Telegram bot for remote status, `gw-stats.sh` for JSON metrics, vnstat traffic tracking, DHCP lease monitoring
- **Community readiness**: CONTRIBUTING.md, CODE_OF_CONDUCT.md (Contributor Covenant v2.1), bug report template, feature request template, PR template
- **No live deployment evidence**: `deploy_log.txt` confirms the system is NOT deployable in the current analysis environment (requires root + Cloudflare WARP)

---

## Key Architectural Decisions

1. **Two-phase provisioning** (`01_install.sh` → `02_configure.sh`): Separates system-level installation (requires reboot) from application deployment. User can edit `config.env` between phases. This is a deliberate UX choice — the first script handles all the heavy system changes, the second deploys the application layer.

2. **Python venv isolation**: Dashboard and bot run in `/opt/EdgeGateway/venv` — no system Python contamination. All dependencies (Flask, SocketIO, python-telegram-bot, psutil, gunicorn, eventlet) are isolated.

3. **Config.env pattern**: All configuration centralized in `/etc/EdgeGateway/config.env` — single source of truth, sourced by both systemd units and scripts. No scattered config files.

4. **WARP watchdog**: Cron-based self-healing — if the tunnel drops, it reconnects automatically within 60 seconds. This is critical for a gateway that must stay online.

5. **Fallback routing**: If WARP is unreachable, traffic falls back to raw WAN (eth0) — degraded but not dead. The iptables rules include a fallback MASQUERADE on `$WAN_IFACE`.

6. **AP subnet restriction**: Dashboard POST endpoints check client IP against the AP subnet — prevents WAN-side admin access. This is a security-by-design choice.

7. **Telegram admin whitelist**: Only `ADMIN_CHAT_ID` users can control the gateway via bot. The bot validates `update.effective_user.id` against the whitelist on every interaction.

8. **No Docker**: Deliberately bare-metal — the system needs direct access to network interfaces (hostapd, iptables, WARP tunnel) that Docker would complicate. The `stack_manifest.json` confirms `has_docker: false`.

9. **ARM-first design**: The Cloudflare WARP apt repo is configured for `arm64` only. This is a deliberate Raspberry Pi focus — x86_64 hosts would need a different source.

---

## Repository Structure

```
EdgeGateway/
├── 01_install.sh              # Step 1: System + WARP + AP + firewall install
├── 02_configure.sh            # Step 2: Dashboard + Telegram bot + systemd units
├── templates/
│   └── dashboard.html         # Real-time monitoring UI (Flask template)
├── .github/
│   ├── workflows/
│   │   └── codeql.yml         # CodeQL security analysis (weekly + push/PR)
│   ├── dependabot.yml         # Weekly GitHub Actions dependency updates
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md
├── README.md                  # Project documentation
├── CHANGELOG.md               # v1.0.0 release notes
├── ROADMAP.md                 # Future plans (production stability, docs, tests)
├── SECURITY.md                # Vulnerability disclosure policy (90-day timeline)
├── CONTRIBUTING.md            # Contribution guidelines
├── CODE_OF_CONDUCT.md         # Contributor Covenant v2.1
├── LICENSE                    # MIT
├── .gitignore
├── stack_manifest.json        # Deployment metadata
├── deploy_log.txt             # Deployment attempt log
├── review_findings.json       # Code review findings (1 finding: README missing requirements note)
├── INTENT.md                  # This file
└── screenshot-dashboard.png   # Dashboard preview image
```

---

## Notes

- **Repo rename**: The project was originally named `pi-router` (evidenced by the initial commit `b176ed4` which included a `pi-router/` subdirectory with duplicate files). It was renamed to `EdgeGateway` on June 17, 2026 across three commits. The `pi-router/` directory was subsequently removed.
- **No git tags**: CHANGELOG.md declares v1.0.0 but no corresponding git tag exists. This is a minor release-process gap.
- **No `docs/` directory**: All documentation lives in the README. No separate docs folder exists.
- **No test files**: No test suite exists — deployment is the only validation path. The ROADMAP.md lists "Test coverage expansion" as a current goal.
- **Dependabot ecosystem**: Correctly configured for `github-actions` only — no ecosystem mismatch (the repo has no `package.json` or `Dockerfile`).
- **Security audit history**: Two security-focused commits in the git log — `10839ba` ("Fix: full project cleanup and security hardening") and `6401607` ("audit(EdgeGateway): sanitize email references"). This is a positive maturity signal.
- **Default credentials**: Default AP password (`SuperSecret99`) is a placeholder — must be changed before production use. The script explicitly comments "← Change this!".
- **Single-point-of-failure**: The Raspberry Pi itself is the gateway — if it goes down, all AP clients lose internet. No HA/failover mechanism.
- **WARP dependency**: The system's privacy guarantees depend entirely on Cloudflare WARP availability. The fallback (raw WAN) provides no privacy.
- **Review finding (EGW-001)**: README omits documented `sudo` and Cloudflare WARP client package availability requirements. Severity: medium.

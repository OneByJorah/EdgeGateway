<!-- j1-brand:v2 -->
<div align="center">

# EdgeGateway

A Raspberry Pi Cloudflare WARP gateway — secure tunneling, DNS privacy, and an outbound proxy for edge devices, all managed from a web dashboard and Telegram bot.

[![GitHub](https://img.shields.io/badge/github-OneByJorah%2FEdgeGateway-FFB300?style=for-the-badge&labelColor=0d0d0c)](https://github.com/OneByJorah/EdgeGateway)
[![License](https://img.shields.io/badge/license-MIT-FFB300?style=for-the-badge&labelColor=0d0d0c)](LICENSE)
[![Language](https://img.shields.io/badge/Shell-FFB300?style=for-the-badge&labelColor=0d0d0c)](https://shellscript.org)
[![Built by](https://img.shields.io/badge/built%20by-JorahOne%20LLC-FFB300?style=for-the-badge&labelColor=0d0d0c)](https://github.com/OneByJorah)

</div>

---

## Why This Exists

Edge devices (IoT sensors, remote workstations, lab equipment) often need secure outbound connectivity without complex VPN configuration. EdgeGateway turns a Raspberry Pi into a Cloudflare WARP gateway with a two-step setup, DNS-over-HTTPS enforcement, a status dashboard, and a Telegram bot for remote management.

## Key Features

| Feature | Why It Matters |
|---|---|
| Cloudflare WARP tunneling | Encrypts all outbound traffic through Cloudflare's network |
| DNS-over-HTTPS enforcement | Prevents DNS leaks and spoofing |
| Two-step provisioning | `01_install.sh` + `02_configure.sh` — no manual config hunting |
| Web dashboard | Flask-based status UI at `http://<pi-ip>:8080` |
| ARM-optimized | Designed and tested for Raspberry Pi hardware |

## Quick Start

```bash
git clone https://github.com/OneByJorah/EdgeGateway.git
cd EdgeGateway
bash 01_install.sh      # installs dependencies + WARP client
bash 02_configure.sh    # registers WARP and sets up routing
```

The dashboard is available at `http://<raspberry-pi-ip>:8080`.

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌────────────────┐
│  Edge Device  │────▶│  Raspberry Pi │────▶│  Cloudflare     │
│  (IoT / Lab)  │     │  WARP Gateway │     │  WARP Network   │
└──────────────┘     └──────┬───────┘     └────────────────┘
                            │
                     ┌──────▼───────┐
                     │  Flask        │
                     │  Dashboard    │
                     │  :8080        │
                     └──────────────┘
```

## Documentation

| Doc | Description |
|---|---|
| [Installation Guide](docs/install.md) | Step-by-step Pi setup |
| [Configuration](docs/config.md) | WARP registration and routing options |
| [Dashboard Guide](docs/dashboard.md) | Using the web status dashboard |

---

## License

MIT © JorahOne, LLC — see [LICENSE](LICENSE)

<sub>Part of the JorahOne infrastructure ecosystem.</sub>

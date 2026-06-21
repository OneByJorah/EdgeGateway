# EdgeGateway (EdgeGateway)

**Version:** v0.1  
**Status:** Active Development  
**Repository:** https://github.com/OneByJorah/EdgeGateway

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Features](#features)
- [Getting Started](#getting-started)
- [Service Management](#service-management)
- [Project Structure](#project-structure)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)

---

## Overview

Cloudflare WARP / edge gateway setup for Raspberry Pi and home network tunneling.

---

## Architecture

Client → Local service (`EdgeGateway`) → data/processing modules → output/api layer.
Secrets and environment configuration are managed via environment files with restrictive permissions.

---

## Technology Stack

|| Layer | Stack |
|---|---|
| Runtime | Linux (Ubuntu 22.04+) |
| Primary Stack | Bash / Cloudflare WARP |
| VCS | Git + GitHub (`github.com/OneByJorah/EdgeGateway`) |
| Dev Port | Localhost / systemd service |

---

## Features

- Operational dashboard and monitoring (per repo).
- Exportable data / reports where supported.
- Extensible service-based design.
- Dark-themed UI where applicable.

---

## Getting Started

```bash
# 1. Clone the repository
git clone https://github.com/OneByJorah/EdgeGateway.git
cd EdgeGateway

# 2. Install dependencies
# (see specific subproject docs)

# 3. Start the service
# (see Service Management below)
```

---

## Service Management

```bash
# Start the service (example)
sudo systemctl start EdgeGateway.service
sudo systemctl enable EdgeGateway.service
```

Access the service via your configured localhost port or reverse proxy.

---

## Project Structure

```
EdgeGateway/
├── README.md
├── (additional project files)
```

---

## Screenshots

All screenshots are live captures from the local dev instance.

_(Screenshots will be added after build/run capture.)_

---

## Contributing

1. Create a feature branch off `main`.
2. Follow the existing code style.
3. Submit a PR with description and screenshots for UI changes.

---

## License

MIT

---

## Author

Built by **Jhonattan L. Jimenez**.

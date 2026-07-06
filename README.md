<div align="center">
  <img src="https://img.shields.io/badge/Raspberry%20Pi-A22846?style=for-the-badge&logo=raspberrypi&logoColor=white">
  <img src="https://img.shields.io/badge/Cloudflare%20WARP-F38020?style=for-the-badge&logo=cloudflare&logoColor=white">
  <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge">
</div>

<br>

<div align="center">
  <h1>🌐 EdgeGateway</h1>
  <p><strong>Raspberry Pi Cloudflare WARP Gateway</strong></p>
  <p>Secure tunneling, DNS privacy, and outbound proxy for edge devices — one-command setup</p>
  <p>
    <a href="#-features">Features</a> •
    <a href="#-quick-start">Quick Start</a> •
    <a href="#-installation">Installation</a> •
    <a href="#-dashboard">Dashboard</a>
  </p>
</div>

---

## ✨ Features

- **Cloudflare WARP** — Secure tunneling and DNS privacy for all traffic
- **Raspberry Pi Optimized** — Lightweight ARM architecture support
- **Two-Step Provisioning** — Install dependencies, then configure WARP
- **Connection Dashboard** — Lightweight HTML dashboard for WARP status monitoring
- **Outbound Proxy** — Route all traffic through Cloudflare WARP for privacy
- **Privacy-First** — DNS over HTTPS with Cloudflare's 1.1.1.1

## 🚀 Quick Start

### Requirements

- **Raspberry Pi** (3B+, 4B, or 5) running **Raspberry Pi OS** (Debian-based)
- **Root access** — both scripts must run with `sudo`
- **Cloudflare WARP client** — the install script adds the Cloudflare apt repo automatically
- **Ethernet WAN uplink** on `eth0` (LAN cable from ISP router)
- **WiFi chipset** supporting AP mode (built-in on Pi 3B+/4/5, or USB adapter)
- **Telegram Bot Token** (optional, for bot functionality) — create via [@BotFather](https://t.me/BotFather)

> ⚠️ **IMPORTANT**: Before running the installer, edit `01_install.sh` and change the default AP password (`AP_PASS="SuperSecret99"`). The default is a placeholder and MUST be changed for any production or public deployment.

```bash
git clone https://github.com/OneByJorah/EdgeGateway.git
cd EdgeGateway
chmod +x 01_install.sh 02_configure.sh
sudo ./01_install.sh
sudo ./02_configure.sh
```

## 🔧 Installation

### Step 1: Install (01_install.sh)

- Installs system dependencies
- Downloads and installs Cloudflare WARP client
- Configures system for ARM architecture

### Step 2: Configure (02_configure.sh)

- Registers WARP client with Cloudflare
- Sets up routing and DNS configuration
- Enables and starts WARP service

## 📊 Dashboard

After installation, open the status dashboard:

```bash
# The dashboard is served on port 5000
# Open in your browser:
# http://<raspberry-pi-ip>:5000
```

## 📁 Project Structure

```
EdgeGateway/
├── 01_install.sh          # System setup & WARP installation
├── 02_configure.sh        # WARP configuration & registration
├── templates/             # Dashboard HTML templates
├── screenshot-dashboard.png
└── README.md
```

## 📄 License

MIT © Jhonattan L. Jimenez

---

<div align="center">
  <p>🛡️ Secure edge networking, simplified for Raspberry Pi</p>
  <p><a href="https://github.com/OneByJorah">@OneByJorah</a></p>
</div>

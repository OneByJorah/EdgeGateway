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
# The dashboard is served on port 8080
# Open in your browser:
# http://<raspberry-pi-ip>:8080
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

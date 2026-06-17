# Pi Gateway — Full Setup Guide

## Architecture

```
Internet
    │
    ▼
[ISP Modem/Router]
    │
   eth0  ← WAN uplink (Raspberry Pi)
    │
    ▼
[Raspberry Pi]
 ├─ Cloudflare WARP tunnel (all traffic)
 ├─ wlan0 → WiFi Access Point (internal hotspot)
 │           SSID: PiGateway | 192.168.50.x
 └─ Dashboard :5000 | Telegram Bot
```

> **Note on interfaces:** This setup uses `wlan0` as the AP (internal hotspot)
> and `eth0` as the uplink. If your Pi has two WiFi adapters, adjust
> `AP_IFACE` in `config.env`. For a USB-to-Ethernet uplink, change `WAN_IFACE`.

---

## Prerequisites

- Raspberry Pi with 64-bit OS (Bookworm recommended)
- 1 GB RAM (sufficient — dashboard + bot use ~120 MB)
- Internet access via eth0 (LAN cable from ISP router)
- A Telegram Bot token (from @BotFather)
- Your Telegram user ID (from @userinfobot)

---

## Step 1 — Flash & SSH

```bash
# On your Pi:
sudo raspi-config
# → Interface Options → SSH → Enable
# → Localisation → Set locale, timezone, WLAN country
```

---

## Step 2 — Copy files to Pi

```bash
scp -r . pi@<PI_IP>:~/EdgeGateway/
ssh pi@<PI_IP>
cd ~/EdgeGateway
```

---

## Step 3 — Run installer

```bash
sudo bash 01_install.sh
```

This will:
- Update the system
- Install hostapd, dnsmasq, iptables
- Install Cloudflare WARP (arm64)
- Set up Python venv with Flask + Telegram bot library
- Configure WiFi AP on wlan0 (192.168.50.1)
- Set up NAT routing through WARP tunnel

---

## Step 4 — Set your Telegram credentials

```bash
sudo nano /etc/EdgeGateway/config.env
```

Edit these two lines:
```
BOT_TOKEN=123456789:ABCdef...
ADMIN_CHAT_ID=987654321
```

Multiple admin IDs: comma-separate them: `111,222,333`

---

## Step 5 — Deploy dashboard & bot

```bash
sudo bash 02_configure.sh
```

This deploys the Flask dashboard, Telegram bot, WARP watchdog, and systemd services.

---

## Step 6 — Reboot

```bash
sudo reboot
```

After reboot, you should see:
- `PiGateway` WiFi network appear
- Dashboard at http://192.168.50.1:5000
- Telegram bot responding to `/start`

---

## Telegram Bot Commands

| Command    | Description                        |
|------------|------------------------------------|
| `/start`   | Show control panel with buttons    |
| `/status`  | Quick status summary               |
| `/clients` | List connected DHCP clients        |

Inline buttons:
- 📊 Status — live stats
- 👥 Clients — DHCP lease list
- 🔄 WARP Toggle — connect/disconnect
- 🔁 WARP Reconnect — force reconnect
- ↩ Restart hostapd / dnsmasq
- 🔃 Reboot Pi

---

## Services

| Service         | Description                  |
|-----------------|------------------------------|
| `warp-svc`      | Cloudflare WARP daemon       |
| `hostapd`       | WiFi Access Point            |
| `dnsmasq`       | DHCP + DNS for AP clients    |
| `pi-dashboard`  | Web dashboard (port 5000)    |
| `pi-bot`        | Telegram control bot         |

```bash
# Check status
systemctl status pi-dashboard pi-bot warp-svc hostapd dnsmasq

# View logs
journalctl -u pi-dashboard -f
journalctl -u pi-bot -f
```

---

## WARP Watchdog

A cron job runs `/usr/local/bin/warp-watchdog.sh` every minute.
If WARP drops, it reconnects automatically.
If WARP stays down, traffic falls back to raw WAN via iptables fallback rule.

---

## Troubleshooting

**WiFi AP not appearing:**
```bash
sudo systemctl status hostapd
# Check: is wlan0 capable of AP mode?
iw list | grep "AP"
```

**WARP not connecting:**
```bash
warp-cli status
warp-cli connect
# Re-register if needed:
warp-cli disconnect
warp-cli register
warp-cli connect
```

**Clients not getting IP:**
```bash
sudo systemctl restart dnsmasq
journalctl -u dnsmasq -n 50
```

**Dashboard not loading:**
```bash
sudo systemctl restart pi-dashboard
journalctl -u pi-dashboard -n 30
```

---

## Changing AP Password / SSID / Country

```bash
sudo nano /etc/EdgeGateway/config.env
# Edit AP_SSID, AP_PASS, AP_COUNTRY
sudo bash 01_install.sh  # re-apply hostapd config
sudo systemctl restart hostapd
```

---

## Security Notes

- Dashboard restricts POST API calls to the AP subnet (192.168.50.x) only. Bind to AP interface only or add Flask-Login for auth.
- The Telegram bot checks `ADMIN_CHAT_ID` — only those IDs can control the gateway.
- iptables rules allow forwarding only through WARP tunnel by default.
- For production, consider UFW rules to block dashboard access from WAN side.

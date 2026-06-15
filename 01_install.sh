#!/bin/bash
# ============================================================
# Pi Gateway Installer
# LAN = Hotspot (eth0) | WiFi = Uplink (wlan0 → AP mode: wlan1)
# All traffic tunneled via Cloudflare WARP
# ============================================================
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
die()   { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

[[ $EUID -ne 0 ]] && die "Run as root: sudo bash 01_install.sh"

# ── Config ────────────────────────────────────────────────
AP_IFACE="wlan0"        # WiFi interface used as AP (internal hotspot)
WAN_IFACE="eth0"        # LAN port = uplink from ISP router/switch
BRIDGE_IFACE="br0"      # Optional bridge (unused here but reserved)

AP_SSID="PiGateway"
AP_PASS="SuperSecret99"   # ← Change this!
AP_CHANNEL=6
AP_IP="192.168.50.1"
AP_SUBNET="192.168.50.0/24"
AP_DHCP_START="192.168.50.10"
AP_DHCP_END="192.168.50.100"

WARP_MTU=1280
DASHBOARD_PORT=5000
BOT_TOKEN=""            # Set after install or in /etc/pi-gateway/config.env
ADMIN_CHAT_ID=""        # Your Telegram chat ID

# ── Persist config ────────────────────────────────────────
mkdir -p /etc/pi-gateway
cat > /etc/pi-gateway/config.env <<EOF
AP_IFACE=$AP_IFACE
WAN_IFACE=$WAN_IFACE
AP_SSID=$AP_SSID
AP_PASS=$AP_PASS
AP_IP=$AP_IP
AP_SUBNET=$AP_SUBNET
AP_DHCP_START=$AP_DHCP_START
AP_DHCP_END=$AP_DHCP_END
WARP_MTU=$WARP_MTU
DASHBOARD_PORT=$DASHBOARD_PORT
BOT_TOKEN=$BOT_TOKEN
ADMIN_CHAT_ID=$ADMIN_CHAT_ID
EOF
ok "Config written to /etc/pi-gateway/config.env"

# ── System update ─────────────────────────────────────────
info "Updating system..."
apt-get update -qq
apt-get upgrade -y -qq
ok "System updated"

# ── Install dependencies ──────────────────────────────────
info "Installing packages..."
apt-get install -y -qq \
    hostapd dnsmasq iptables iptables-persistent \
    python3 python3-pip python3-venv \
    curl wget gnupg2 lsb-release \
    net-tools iproute2 nftables \
    vnstat tcpdump \
    git jq bc
ok "Packages installed"

# ── Cloudflare WARP ───────────────────────────────────────
info "Installing Cloudflare WARP..."
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
    | gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=arm64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] \
https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/cloudflare-client.list
apt-get update -qq
apt-get install -y -qq cloudflare-warp
ok "Cloudflare WARP installed"

# ── Python venv for dashboard + bot ──────────────────────
info "Setting up Python environment..."
python3 -m venv /opt/pi-gateway/venv
/opt/pi-gateway/venv/bin/pip install -q --upgrade pip
/opt/pi-gateway/venv/bin/pip install -q \
    flask flask-socketio \
    python-telegram-bot==20.8 \
    psutil requests \
    gunicorn eventlet
ok "Python environment ready"

# ── Copy app files ────────────────────────────────────────
info "Installing gateway app files..."
mkdir -p /opt/pi-gateway/{templates,static}
# (Files will be copied by 02_configure.sh)

# ── Enable IP forwarding ──────────────────────────────────
info "Enabling IP forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf > /dev/null
ok "IP forwarding enabled"

# ── Configure hostapd ─────────────────────────────────────
info "Configuring hostapd (WiFi AP)..."
systemctl stop hostapd 2>/dev/null || true
cat > /etc/hostapd/hostapd.conf <<EOF
interface=$AP_IFACE
driver=nl80211
ssid=$AP_SSID
hw_mode=g
channel=$AP_CHANNEL
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$AP_PASS
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
country_code=US
EOF
sed -i 's|#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
ok "hostapd configured"

# ── Static IP for AP interface ────────────────────────────
info "Setting static IP on $AP_IFACE..."
cat >> /etc/dhcpcd.conf <<EOF

# Pi Gateway AP Interface
interface $AP_IFACE
    static ip_address=$AP_IP/24
    nohook wpa_supplicant
EOF
ok "Static IP set: $AP_IP"

# ── Configure dnsmasq ─────────────────────────────────────
info "Configuring dnsmasq (DHCP + DNS)..."
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak 2>/dev/null || true
cat > /etc/dnsmasq.conf <<EOF
# Pi Gateway dnsmasq config
interface=$AP_IFACE
bind-interfaces
server=1.1.1.1
server=1.0.0.1
domain-needed
bogus-priv
dhcp-range=$AP_DHCP_START,$AP_DHCP_END,12h
dhcp-option=3,$AP_IP
dhcp-option=6,$AP_IP
log-dhcp
log-queries
EOF
ok "dnsmasq configured"

# ── iptables NAT + WARP routing ───────────────────────────
info "Setting up iptables rules..."
# Flush existing
iptables -F
iptables -t nat -F
iptables -X

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow AP clients to forward
iptables -A FORWARD -i $AP_IFACE -o CloudflareWARP -j ACCEPT
iptables -A FORWARD -i $WAN_IFACE -o CloudflareWARP -j ACCEPT

# MASQUERADE out via WARP tunnel
iptables -t nat -A POSTROUTING -o CloudflareWARP -j MASQUERADE

# Fallback: also masquerade via WAN if WARP is down
iptables -t nat -A POSTROUTING -o $WAN_IFACE -j MASQUERADE

# Save rules
netfilter-persistent save
ok "iptables rules saved"

# ── Register WARP (non-interactive) ──────────────────────
info "Registering Cloudflare WARP..."
systemctl enable --now warp-svc
sleep 3
warp-cli --accept-tos register || warn "WARP already registered"
warp-cli set-mode warp
warp-cli connect || warn "WARP connect will retry on boot"
ok "WARP registered"

# ── Enable services ───────────────────────────────────────
info "Enabling services..."
systemctl unmask hostapd
systemctl enable hostapd dnsmasq warp-svc
ok "Services enabled"

# ── Install systemd units (created by next script) ───────
info "Done! Run 02_configure.sh to deploy dashboard & bot."
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Pi Gateway base install complete!   ${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "  AP SSID   : $AP_SSID"
echo "  AP Pass   : $AP_PASS"
echo "  AP IP     : $AP_IP"
echo ""
echo "  Next steps:"
echo "  1. Edit /etc/pi-gateway/config.env → add BOT_TOKEN + ADMIN_CHAT_ID"
echo "  2. Run: sudo bash 02_configure.sh"
echo "  3. Reboot: sudo reboot"
echo ""

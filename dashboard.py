#!/usr/bin/env python3
"""EdgeGateway Dashboard — lightweight Flask dashboard for WARP gateway status."""
import os, json, subprocess, time
from flask import Flask, render_template, jsonify, request
from flask_socketio import SocketIO
import threading

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins=[], async_mode="eventlet")
PORT = int(os.environ.get("DASHBOARD_PORT", 5000))
AP_SUBNET = os.environ.get("AP_SUBNET", "192.168.50.0/24")

def get_stats():
    try:
        r = subprocess.run(["/usr/local/bin/gw-stats.sh"], capture_output=True, text=True, timeout=10)
        return json.loads(r.stdout)
    except Exception as e:
        return {"error": str(e)}

def get_leases():
    leases = []
    try:
        with open("/var/lib/misc/dnsmasq.leases") as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) >= 4:
                    leases.append({"ip": parts[2], "mac": parts[1], "name": parts[3], "expires": parts[0]})
    except:
        pass
    return leases

@app.before_request
def restrict_subnet():
    if request.method == "POST":
        client_ip = request.remote_addr
        if not client_ip.startswith(AP_SUBNET.rsplit(".", 1)[0] + "."):
            return jsonify({"error": "Forbidden: not on AP subnet"}), 403

@app.route("/")
def index():
    return render_template("dashboard.html")

@app.route("/api/stats")
def api_stats():
    return jsonify(get_stats())

@app.route("/api/clients")
def api_clients():
    return jsonify(get_leases())

@app.route("/api/warp/toggle", methods=["POST"])
def warp_toggle():
    stats = get_stats()
    if stats.get("warp") == "Connected":
        subprocess.run(["warp-cli", "disconnect"])
        return jsonify({"action": "disconnected"})
    else:
        subprocess.run(["warp-cli", "connect"])
        return jsonify({"action": "connected"})

@app.route("/api/warp/reconnect", methods=["POST"])
def warp_reconnect():
    subprocess.run(["warp-cli", "disconnect"])
    time.sleep(2)
    subprocess.run(["warp-cli", "connect"])
    return jsonify({"action": "reconnected"})

@app.route("/api/restart/<service>", methods=["POST"])
def restart_service(service):
    allowed = ["hostapd", "dnsmasq", "warp-svc"]
    if service not in allowed:
        return jsonify({"error": "not allowed"}), 403
    subprocess.run(["systemctl", "restart", service])
    return jsonify({"action": f"restarted {service}"})

@app.route("/api/reboot", methods=["POST"])
def reboot_pi():
    subprocess.Popen(["bash", "-c", "sleep 3 && reboot"])
    return jsonify({"action": "rebooting in 3 seconds"})

def push_stats():
    while True:
        socketio.emit("stats", get_stats())
        time.sleep(3)

@socketio.on("connect")
def on_connect():
    pass

if __name__ == "__main__":
    t = threading.Thread(target=push_stats, daemon=True)
    t.start()
    socketio.run(app, host="0.0.0.0", port=PORT)

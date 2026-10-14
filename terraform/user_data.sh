#!/bin/bash
set -euxo pipefail

# ---------------------------------------------------------------------------
# System Updates
# ---------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update -y

# ---------------------------------------------------------------------------
# Python & Flask Application
# ---------------------------------------------------------------------------
apt-get install -y python3 python3-pip python3-venv

mkdir -p /opt/app
cd /opt/app

python3 -m venv venv
source venv/bin/activate
pip install flask

cat > app.py << 'FLASK_APP'
import json
import socket
import urllib.request
from datetime import datetime, timezone

from flask import Flask, request
from markupsafe import escape

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Instance metadata (IMDSv2). Cached once; falls back gracefully off-AWS.
# ---------------------------------------------------------------------------
_META = {}


def _imds(path, token):
    req = urllib.request.Request(
        f"http://169.254.169.254/latest/meta-data/{path}",
        headers={"X-aws-ec2-metadata-token": token},
    )
    return urllib.request.urlopen(req, timeout=1).read().decode()


def get_meta():
    if _META:
        return _META
    data = {"instance_id": "n/a", "az": "n/a", "private_ip": "n/a", "instance_type": "n/a"}
    try:
        tok_req = urllib.request.Request(
            "http://169.254.169.254/latest/api/token",
            method="PUT",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "300"},
        )
        token = urllib.request.urlopen(tok_req, timeout=1).read().decode()
        data["instance_id"] = _imds("instance-id", token)
        data["az"] = _imds("placement/availability-zone", token)
        data["private_ip"] = _imds("local-ipv4", token)
        data["instance_type"] = _imds("instance-type", token)
    except Exception:
        data["private_ip"] = socket.gethostbyname(socket.gethostname())
    _META.update(data)
    return _META


PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AWS VPC Demo</title>
<style>
:root{
  --navy:#0a1d3f; --navy2:#12306a; --ink:#16233b; --muted:#5d6b82; --line:#e2e8f2;
  --bg:#f3f6fb; --card:#ffffff; --brand:#2557d6; --req:#f59e0b; --res:#10b981;
  --sans:Inter,system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --mono:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 var(--sans);-webkit-font-smoothing:antialiased}
.hero{
  background:radial-gradient(900px 340px at 85% -10%,rgba(79,140,255,.35),transparent 60%),
             linear-gradient(135deg,var(--navy),var(--navy2));
  color:#fff;padding:56px 20px 112px;
}
.wrap{max-width:1040px;margin:0 auto}
.hero .wrap{display:flex;flex-wrap:wrap;gap:20px;align-items:flex-end;justify-content:space-between}
h1{margin:0;font-size:clamp(28px,4.4vw,42px);line-height:1.15;font-weight:700;letter-spacing:-.02em;max-width:18ch}
.sub{margin:14px 0 0;max-width:54ch;color:#bdd0f2;font-size:16px}
.pill{display:inline-flex;align-items:center;gap:9px;padding:9px 16px;border-radius:999px;
  background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.22);font-size:14px;font-weight:500}
.dot{width:9px;height:9px;border-radius:50%;background:#34d399;box-shadow:0 0 0 0 rgba(52,211,153,.7);animation:pulse 2s infinite}
@keyframes pulse{70%{box-shadow:0 0 0 9px rgba(52,211,153,0)}100%{box-shadow:0 0 0 0 rgba(52,211,153,0)}}

main{margin-top:-72px;padding:0 20px 56px}
.card{background:var(--card);border:1px solid var(--line);border-radius:16px;
  box-shadow:0 1px 2px rgba(16,35,70,.05),0 12px 32px -12px rgba(16,35,70,.18)}
.diagram{padding:18px 18px 8px}
.card-head{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px;padding:2px 6px 10px}
.card-head h2{margin:0}
svg{display:block;width:100%;height:auto}
svg text{font-family:var(--sans);fill:var(--ink)}
.t-md{font-size:16px;font-weight:600}
.t-sm{font-size:13px;fill:var(--muted)}
.t-zone{font-size:13px;font-weight:600}
.t-mono{font-family:var(--mono);font-size:12px;fill:var(--muted)}
.node{fill:#fff;stroke:#cfd9ea;stroke-width:1.5;filter:drop-shadow(0 4px 8px rgba(16,35,70,.10))}
.node.here{stroke:var(--brand);stroke-width:2.2}
.icon{fill:none;stroke:var(--brand);stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}
.icon .f{fill:var(--brand);stroke:none}
.link{stroke:#9db3dd;stroke-width:2;stroke-dasharray:5 7;fill:none;animation:dash 1.2s linear infinite}
@keyframes dash{to{stroke-dashoffset:-12}}
.ring{fill:none;stroke:var(--brand);stroke-width:2;transform-box:fill-box;transform-origin:center;animation:ring 2.6s ease-out infinite}
@keyframes ring{from{opacity:.7;transform:scale(1)}to{opacity:0;transform:scale(1.3)}}
.legend{display:flex;gap:22px;flex-wrap:wrap;padding:2px 6px 10px;color:var(--muted);font-size:13px}
.legend i{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:7px}

h2{font-size:19px;line-height:1.3;font-weight:650;margin:0 0 18px;letter-spacing:-.01em}
.grid{display:grid;grid-template-columns:1.2fr 1fr;gap:20px;margin-top:20px}
@media(max-width:820px){.grid{grid-template-columns:1fr}}
.panel{padding:26px}
ol{list-style:none;margin:0;padding:0;counter-reset:s}
li{position:relative;padding:0 0 20px 46px;counter-increment:s}
li:last-child{padding-bottom:0}
li::before{content:counter(s);position:absolute;left:0;top:0;width:30px;height:30px;border-radius:50%;
  background:#eaf0ff;color:var(--brand);display:grid;place-items:center;font-size:13px;font-weight:700}
li::after{content:"";position:absolute;left:14.5px;top:36px;bottom:6px;width:1px;background:var(--line)}
li:last-child::after{display:none}
li b{display:block;font-weight:600}
li span{color:var(--muted);font-size:14px}
code{font:12.5px var(--mono);background:#f1f4fa;color:#2a3a5c;padding:2px 7px;border-radius:6px;word-break:break-all}
dl{margin:0}
.row{display:flex;justify-content:space-between;gap:16px;padding:12px 0;border-bottom:1px solid var(--line);align-items:baseline}
.row:first-child{padding-top:0}
dt{color:var(--muted);font-size:14px;white-space:nowrap}
dd{margin:0;font:13px var(--mono);text-align:right;word-break:break-all}
button{margin-top:22px;width:100%;padding:12px;border:0;border-radius:10px;background:var(--brand);
  color:#fff;font:600 15px var(--sans);cursor:pointer;box-shadow:0 6px 16px -6px rgba(37,87,214,.6);transition:background .15s}
button:hover{background:#1d47b4}
button:focus-visible{outline:3px solid #9db8f5;outline-offset:2px}
footer{margin-top:26px;color:var(--muted);font-size:13px;text-align:center}
</style>
</head>
<body>
<header class="hero">
  <div class="wrap">
    <div>
      <h1>This request came through your VPC</h1>
      <p class="sub">Served from a private subnet. Nothing reached this instance directly: the load balancer received the request first and forwarded it.</p>
    </div>
    <div class="pill"><span class="dot"></span>Healthy · /health returns 200</div>
  </div>
</header>

<main>
<div class="wrap">
<section class="card diagram" aria-label="Request flow diagram">
  <div class="card-head"><h2>Request flow</h2>
    <div class="legend">
      <span><i style="background:#f59e0b"></i>Request in</span>
      <span><i style="background:#10b981"></i>Response back</span>
    </div>
  </div>
<svg viewBox="0 0 960 330" role="img" aria-labelledby="dt">
  <title id="dt">Request flow: Client to Internet Gateway to Application Load Balancer in the public subnet to the Flask instance in the private subnet.</title>

  <rect x="228" y="14" width="716" height="302" rx="16" fill="#f7f9ff" stroke="#9db5f0" stroke-width="1.5" stroke-dasharray="7 5"/>
  <text class="t-zone" x="300" y="42" style="fill:#2f55b8">VPC · 10.0.0.0/16</text>

  <rect x="296" y="62" width="258" height="230" rx="12" fill="#fff8ec" stroke="#f0c27a" stroke-width="1.5" stroke-dasharray="6 5"/>
  <text class="t-zone" x="314" y="88" style="fill:#a06a10">Public subnet</text>
  <rect x="618" y="62" width="310" height="230" rx="12" fill="#eef3ff" stroke="#8aa8ee" stroke-width="1.5" stroke-dasharray="6 5"/>
  <text class="t-zone" x="636" y="88" style="fill:#2f55b8">Private subnet</text>

  <path class="link" d="M130 165H185"/>
  <path class="link" d="M275 165H340"/>
  <path class="link" d="M510 165H670"/>

  <rect class="node" x="10" y="117" width="120" height="96" rx="12"/>
  <g class="icon" transform="translate(70 148)"><rect x="-12" y="-9" width="24" height="16" rx="2"/><path d="M-5 12H5M0 7V12"/></g>
  <text class="t-md" x="70" y="182" text-anchor="middle">Client</text>
  <text class="t-sm" x="70" y="200" text-anchor="middle">Your browser</text>

  <rect class="node" x="185" y="117" width="90" height="96" rx="12"/>
  <g class="icon" transform="translate(230 148)"><circle r="11"/><ellipse rx="5" ry="11"/><path d="M-11 0H11"/></g>
  <text class="t-md" x="230" y="182" text-anchor="middle">IGW</text>
  <text class="t-sm" x="230" y="200" text-anchor="middle">Internet in</text>

  <rect class="node" x="340" y="117" width="170" height="96" rx="12"/>
  <g class="icon" transform="translate(425 148)"><path d="M-13 0H-3M-3 0L8 -8M-3 0H10M-3 0L8 8"/><circle class="f" cx="10" cy="-8" r="2.4"/><circle class="f" cx="12" cy="0" r="2.4"/><circle class="f" cx="10" cy="8" r="2.4"/></g>
  <text class="t-md" x="425" y="182" text-anchor="middle">Load Balancer</text>
  <text class="t-sm" x="425" y="200" text-anchor="middle">Port 80 · health checks</text>

  <rect class="ring" x="670" y="117" width="200" height="96" rx="12"/>
  <rect class="node here" x="670" y="117" width="200" height="96" rx="12"/>
  <g class="icon" transform="translate(770 148)"><rect x="-12" y="-11" width="24" height="9" rx="2"/><rect x="-12" y="2" width="24" height="9" rx="2"/><circle class="f" cx="-7" cy="-6.5" r="1.2"/><circle class="f" cx="-7" cy="6.5" r="1.2"/></g>
  <text class="t-md" x="770" y="182" text-anchor="middle">Flask on EC2</text>
  <text class="t-sm" x="770" y="200" text-anchor="middle">Port 8000 · you are here</text>
  <text class="t-mono" x="770" y="244" text-anchor="middle">__PRIVATE_IP__</text>

  <circle r="7.5" fill="#f59e0b" stroke="#fff" stroke-width="2">
    <animateMotion dur="7s" repeatCount="indefinite" path="M130 165L700 165L130 165"/>
    <animate attributeName="fill" dur="7s" repeatCount="indefinite"
             values="#f59e0b;#f59e0b;#10b981;#10b981" keyTimes="0;0.49;0.5;1" calcMode="discrete"/>
  </circle>
</svg>
</section>

<div class="grid">
  <section class="card panel">
    <h2>What happened to this request</h2>
    <ol>
      <li><b>Your browser sent a request</b><span>Client address seen by the load balancer: <code>__CLIENT_IP__</code></span></li>
      <li><b>The internet gateway let it into the VPC</b><span>It is the only door between the internet and your subnets.</span></li>
      <li><b>The load balancer picked a healthy target</b><span>Protocol <code>__PROTO__</code> · trace <code>__TRACE__</code></span></li>
      <li><b>It was forwarded into the private subnet</b><span>This instance has no public IP, so only the load balancer can reach it.</span></li>
      <li><b>Flask answered at __TIME__</b><span>The response followed the same path back to your browser.</span></li>
    </ol>
  </section>

  <section class="card panel">
    <h2>Serving instance</h2>
    <dl>
      <div class="row"><dt>Instance</dt><dd>__INSTANCE_ID__</dd></div>
      <div class="row"><dt>Availability zone</dt><dd>__AZ__</dd></div>
      <div class="row"><dt>Private IP</dt><dd>__PRIVATE_IP__</dd></div>
      <div class="row"><dt>Type</dt><dd>__ITYPE__</dd></div>
      <div class="row"><dt>Hostname</dt><dd>__HOSTNAME__</dd></div>
      <div class="row"><dt>Host header</dt><dd>__HOST__</dd></div>
    </dl>
    <button type="button" onclick="location.reload()">Send another request</button>
  </section>
</div>

<footer>With more than one instance behind the load balancer, a new request may be served by a different one.</footer>
</div>
</main>
<script>
if (matchMedia("(prefers-reduced-motion: reduce)").matches) {
  document.querySelector("svg").pauseAnimations();
  document.querySelectorAll(".link,.ring,.dot").forEach(function (e) { e.style.animation = "none"; });
}
</script>
</body>
</html>
"""


@app.route("/")
def home():
    meta = get_meta()
    fwd = request.headers.get("X-Forwarded-For", request.remote_addr or "unknown")
    values = {
        "__CLIENT_IP__": fwd.split(",")[0].strip(),
        "__PROTO__": request.headers.get("X-Forwarded-Proto", "http"),
        "__TRACE__": request.headers.get("X-Amzn-Trace-Id", "not set"),
        "__TIME__": datetime.now(timezone.utc).strftime("%H:%M:%S UTC"),
        "__INSTANCE_ID__": meta["instance_id"],
        "__AZ__": meta["az"],
        "__PRIVATE_IP__": meta["private_ip"],
        "__ITYPE__": meta["instance_type"],
        "__HOSTNAME__": socket.gethostname(),
        "__HOST__": request.host,
    }
    html = PAGE
    for key, val in values.items():
        html = html.replace(key, str(escape(val)))
    return html


@app.route("/health")
def health():
    return "OK", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
FLASK_APP

# ---------------------------------------------------------------------------
# Run Flask as a systemd service (logs go to a file CloudWatch can tail)
# ---------------------------------------------------------------------------
cat > /etc/systemd/system/flask-app.service << SERVICE
[Unit]
Description=Flask Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
Environment=PYTHONUNBUFFERED=1
ExecStart=/opt/app/venv/bin/python app.py
StandardOutput=append:/var/log/flask-app.log
StandardError=append:/var/log/flask-app.log
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app

# ---------------------------------------------------------------------------
# CloudWatch Agent
# ---------------------------------------------------------------------------
apt-get install -y wget

wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
rm -f amazon-cloudwatch-agent.deb

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CW_CONFIG'
{
  "metrics": {
    "namespace": "CustomMetrics",
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    },
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}",
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}"
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/syslog",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/flask-app.log",
            "log_group_name": "/aws/ec2/flask-app",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CW_CONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "User data script completed successfully"
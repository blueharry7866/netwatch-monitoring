# NetWatch — Network Monitoring & Alerting System

A complete, dependency-free network monitoring system in Python.
Monitor switches, routers, servers and websites with ping, TCP and
HTTP checks, keep every result in SQLite, get **one alert per outage**
(not an email storm), and watch it all on a live web dashboard.

**Zero third-party dependencies.** Python 3.10+ is all you need —
the standard library does the checking, the storage, the alerting
and the dashboard.

> This is a generic, open-source tool. It contains no company data,
> no internal hostnames and no credentials — it is safe to publish
> on GitHub.

## Features

- **Three check types** — ICMP ping, TCP connect, HTTP GET (with expected status)
- **Concurrent scanning** — a slow device never blocks the rest (thread pool)
- **SQLite history** — every check, every alert, forever (prunable)
- **Smart alerting** — failure threshold (e.g. alert only after 2
  consecutive failures), one DOWN alert per outage, one RECOVERED
  alert, never a repeat while still down
- **Three alert channels** — console, SMTP email, webhook (Slack/Teams/anything)
- **Uptime reports** — per-device uptime %, average latency, outage
  count, in plain text or Markdown
- **Live dashboard** — auto-refreshing page + JSON API (`/api/devices`,
  `/api/history`, `/api/alerts`), no framework, no build step
- **Docker + CI ready** — Dockerfile and GitHub Actions workflow included
- **Tested** — unit tests for checks, storage, alert dedup and reports

## Quick start (2 minutes)

```bash
# No install needed for a first run — Python 3.10+ is enough.
python3 -m netwatch --db demo.db seed-demo
python3 -m netwatch --db demo.db scan
python3 -m netwatch --db demo.db report
python3 -m netwatch --db demo.db serve --port 8000
# Open http://localhost:8000
```

Or install it properly:

```bash
pip install .
netwatch init
netwatch seed-demo
netwatch scan
```

## Usage

```bash
# Add devices (groups help you organise core / access / servers)
netwatch add --name "Core Switch" --type ping --target 192.168.1.1 --group core
netwatch add --name "Web Server"  --type http --target https://example.com --group servers
netwatch add --name "Printer"     --type tcp  --target 192.168.1.50 --port 9100 --group access

netwatch list
netwatch scan                       # one scan now
netwatch scan --loop --interval 60  # scan forever, every 60 s
netwatch serve --port 8000          # dashboard
netwatch report --days 7            # text report
netwatch report --days 30 --format markdown
netwatch remove --name "Printer"
```

Schedule it with cron instead of the loop (one or the other, not both):

```cron
* * * * * cd /opt/netwatch && /usr/bin/python3 -m netwatch scan >> /var/log/netwatch.log 2>&1
```

## Alerts (email / webhook)

Copy `examples/config.example.json` to `config.json` and fill it in —
or, better on a server, use environment variables (they override the
file, and secrets then never sit in a file in the repo):

```bash
export NETWATCH_SMTP_HOST="smtp.example.com"
export NETWATCH_SMTP_USER="alerts@example.com"
export NETWATCH_SMTP_PASS="..."          # never commit this
export NETWATCH_SMTP_FROM="alerts@example.com"
export NETWATCH_SMTP_TO="admin@example.com"
export NETWATCH_WEBHOOK_URL="https://hooks.slack.com/services/..."   # optional
```

Alert logic, in one paragraph: a device is only *confirmed* DOWN
after `failure_threshold` consecutive failures. The first confirmed
DOWN sends one alert; while it stays down, nothing repeats. When it
recovers, one RECOVERED alert is sent. That is the whole dedup rule,
and it is covered by a test (`tests/test_store_alerts.py`).

## Project structure

```
netwatch/
├── netwatch/
│   ├── checks.py    # ping / tcp / http, concurrent runner
│   ├── config.py    # settings (JSON + env) and device model
│   ├── store.py     # SQLite: devices, results, alerts, uptime math
│   ├── alerts.py    # dedup + email / webhook / console channels
│   ├── scanner.py   # one scan cycle + loop mode
│   ├── report.py    # text + Markdown reports
│   ├── server.py    # dashboard + JSON API (http.server only)
│   └── cli.py       # argparse CLI
├── tests/           # unittest, no network dependency (mocked)
├── examples/        # config.example.json
├── .github/workflows/ci.yml
├── Dockerfile
└── pyproject.toml
```

## Dashboard API

| Route | Returns |
|---|---|
| `GET /` | Dashboard page |
| `GET /api/devices` | Devices + latest status + 24 h uptime |
| `GET /api/history?device_id=N&limit=100` | Recent results for one device |
| `GET /api/alerts` | Recent alerts |

## Tests

```bash
python3 -m unittest discover -s tests -v
```

Tests mock the network (ping output, HTTP errors, refused TCP), so
they pass offline and in CI.

## Honest limits

- Ping needs the system `ping` binary (installed by default on
  Linux/macOS/Windows; the Dockerfile installs it). If it is missing,
  ping checks report DOWN with "ping binary not found" instead of
  crashing the scan.
- This is host/service monitoring, not SNMP polling or flow analysis:
  it tells you *whether* a device answers and *how fast*, not its
  interface counters or CPU. SNMP is a natural v2 extension.
- SQLite is perfect for one monitoring node; for thousands of
  devices or multiple pollers, move the store to Postgres.

## License

MIT — see `LICENSE`. Use it, fork it, put it on your CV.

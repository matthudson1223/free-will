# free-will server

FastAPI backend that gives the iOS app full access to the free-will folder via streaming Claude conversations.

## Prerequisites

- Python 3.12+
- `uv` at `~/.local/bin/uv` (already installed on this machine)
- Logged in via `claude login` — credentials are read automatically from `~/.claude/.credentials.json`

## First run

```bash
cd /home/developer/free-will/integrations/app-server
./start.sh
```

On first start the server prints the iOS app API key:

```
*** iOS API KEY: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ***
```

Copy it — you'll paste it into the iOS app's Settings screen.

## Keep it running (tmux)

```bash
tmux new -s freewill
./start.sh
# Detach: Ctrl-B D
# Reattach: tmux attach -t freewill
```

## iOS app connection

The iPhone is already on your Tailscale network. Get the server's Tailscale IP:

```bash
tailscale ip -4
```

Use that IP in the iOS app Settings: `http://<tailscale-ip>:8765`

If Tailscale is unavailable, install ngrok and run `ngrok http 8765` as a fallback.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check |
| `WS` | `/ws/chat/{id}?key=...` | Streaming Claude chat |
| `POST` | `/conversations` | Create conversation |
| `GET` | `/conversations` | List conversations |
| `GET` | `/conversations/{id}/messages` | Message history |
| `PATCH` | `/conversations/{id}` | Rename conversation |
| `GET` | `/journal` | List journal entries |
| `GET` | `/journal/{date}` | Read entry |
| `POST` | `/journal/{date}` | Create entry |
| `GET` | `/habits` | Full habit history |
| `GET` | `/habits/today` | Today's habits |
| `POST` | `/habits/{date}/{habit}` | Toggle a habit |
| `GET` | `/files?path=` | Browse directory |

# openclaw-services

Multi-tenant OpenClaw infrastructure with Tailscale. Each client runs in full isolation with their own stack, Tailscale identity, and workspace.

## What's Inside

- `provision.sh` — spin up a new client stack in one command
- `status.sh` — check running state of all client stacks
- `docker-compose.no-tailscale.yml` — alternative compose for clients without Tailscale
- `template/` — workspace starter files copied into each new client
- `CLIENTS.md` — master inventory of all provisioned clients

## Quick Start

```bash
# With Tailscale (default)
./provision.sh <slug> <tier>

# Without Tailscale
./provision.sh <slug> <tier> simple
```

Then fill in `.env` inside the client directory and run:

```bash
cd <slug>
docker compose up -d
```

## Client Structure

Each provisioned client gets:
```
<slug>/
├── docker-compose.yml
├── .env                    # gitignored — contains secrets
├── data/
│   ├── .openclaw/          # gateway config + sessions
│   └── workspace/          # persona, memory, agents
└── tailscale/              # gitignored
```

## Tiers

- `starter` — basic assistant, no custom agents
- `pro` — full agent team, skills enabled
- `enterprise` — custom setup per client

## See Also

- [openclaw-docker-compose](https://github.com/picoinno/openclaw-docker-compose) — single-tenant public template
- [openclaw-services-lite](https://github.com/picoinno/openclaw-services-lite) — lightweight multi-tenant, no Tailscale

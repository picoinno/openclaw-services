# OpenClaw Client Inventory

> Managed by MyanClaw 🐾
> Add a new entry when provisioning. Update `status` when state changes.

---

## clients

```yaml
clients:
  # Example entry — replace with real client after provisioning
  # - slug: example-client
  #   name: Example Client
  #   tier: pro
  #   server: homeserver
  #   tailscale_host: openclaw-example-client
  #   telegram_bot: ~
  #   status: pending
  #   provisioned: 2026-01-01
  #   notes: ~
```

---

## Schema

```yaml
# slug          — unique identifier, used as directory name
# name          — full client/company name
# tier          — starter | pro | enterprise
# server        — homeserver | vps | client-vps
# tailscale_host — Tailscale machine name (auto-set by provision.sh)
# telegram_bot  — Telegram bot username (@handle)
# status        — pending | active | suspended | offboarded
# provisioned   — date provisioned (YYYY-MM-DD)
# notes         — any free-form notes
```

---

## Scripts

```bash
# Add new client
./provision.sh <slug> <tier>

# Check all stacks
./status.sh

# Check single client
./status.sh <slug>
```

---

## Offboarding

1. `docker compose down` inside the client dir
2. Archive or delete the directory
3. Set `status: offboarded` in the entry above
4. Remove Tailscale device from dashboard

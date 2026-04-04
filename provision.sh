#!/bin/bash
# provision.sh — Provision a new OpenClaw client stack
# Usage: ./provision.sh <slug> <tier>
# Example: ./provision.sh acme-corp pro

set -e

SLUG="$1"
TIER="${2:-starter}"
MODE="${3:-tailscale}"  # tailscale | simple
TEMPLATE_DIR="$(cd "$(dirname "$0")/../openclaw-docker-compose" && pwd)"
TARGET_DIR="$(cd "$(dirname "$0")" && pwd)/$SLUG"
CLIENTS_FILE="$(cd "$(dirname "$0")" && pwd)/CLIENTS.md"

# --- Validate ---
if [ -z "$SLUG" ]; then
  echo "❌ Usage: ./provision.sh <slug> <tier>"
  echo "   Example: ./provision.sh acme-corp pro"
  exit 1
fi

if [ -d "$TARGET_DIR" ]; then
  echo "❌ Client '$SLUG' already exists at $TARGET_DIR"
  exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "❌ Template not found at $TEMPLATE_DIR"
  echo "   Make sure openclaw-docker-compose is cloned at ../openclaw-docker-compose"
  exit 1
fi

echo "🚀 Provisioning client: $SLUG (tier: $TIER, mode: $MODE)"

# --- Copy template ---
mkdir -p "$TARGET_DIR"

if [ "$MODE" = "simple" ]; then
  cp "$SERVICES_DIR/docker-compose.no-tailscale.yml" "$TARGET_DIR/docker-compose.yml"
else
  cp "$TEMPLATE_DIR/docker-compose.yml" "$TARGET_DIR/"
fi

cp "$TEMPLATE_DIR/.env.example" "$TARGET_DIR/.env"
cp "$TEMPLATE_DIR/openclaw.json.template" "$TARGET_DIR/"

# Copy workspace starter if it exists
if [ -d "$TEMPLATE_DIR/data/workspace" ]; then
  cp -r "$TEMPLATE_DIR/data" "$TARGET_DIR/"
fi

# Copy scripts
if [ -d "$TEMPLATE_DIR/scripts" ]; then
  cp -r "$TEMPLATE_DIR/scripts" "$TARGET_DIR/"
fi

# --- Pre-write openclaw.json with correct model ---
# Prevents gateway from booting with Anthropic default when no Anthropic key is set
AI_MODEL=$(grep "^AI_MODEL=" "$TARGET_DIR/.env" | cut -d'=' -f2)
mkdir -p "$TARGET_DIR/data/.openclaw"
cat > "$TARGET_DIR/data/.openclaw/openclaw.json" << EOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "$AI_MODEL",
        "fallbacks": [
          "openrouter/minimax/minimax-m2.7",
          "openrouter/qwen/qwen3.5-9b"
        ]
      },
      "maxConcurrent": 4,
      "subagents": { "maxConcurrent": 8 },
      "compaction": { "mode": "safeguard" }
    }
  },
  "messages": { "ackReactionScope": "group-mentions" },
  "channels": {
    "telegram": { "enabled": true, "dmPolicy": "pairing" }
  }
}
EOF

# --- Generate tokens ---
OPENCLAW_TOKEN=$(openssl rand -hex 32)
BROWSER_TOKEN=$(openssl rand -hex 32)
TS_HOSTNAME="openclaw-$SLUG"

# --- Pre-fill .env ---
sed -i "1s/^/COMPOSE_PROJECT_NAME=$SLUG\n/" "$TARGET_DIR/.env"
sed -i "s/^OPENCLAW_TOKEN=.*/OPENCLAW_TOKEN=$OPENCLAW_TOKEN/" "$TARGET_DIR/.env"
sed -i "s/^BROWSER_TOKEN=.*/BROWSER_TOKEN=$BROWSER_TOKEN/" "$TARGET_DIR/.env"
sed -i "s/^TS_HOSTNAME=.*/TS_HOSTNAME=$TS_HOSTNAME/" "$TARGET_DIR/.env"

# --- Add to CLIENTS.md ---
DATE=$(date +%Y-%m-%d)
sed -i "s/| _(none yet)_ .*/| $SLUG | _(fill in)_ | $TIER | _(fill in)_ | $TS_HOSTNAME | pending | Provisioned $DATE |\n| _(none yet)_ | | | | | | |/" "$CLIENTS_FILE"

echo ""
echo "✅ Client '$SLUG' provisioned at:"
echo "   $TARGET_DIR"
echo ""
echo "📋 Next steps:"
echo "   1. cd $TARGET_DIR"
echo "   2. Edit .env — fill in:"
echo "      - OPENROUTER_API_KEY (or other AI provider)"
echo "      - TELEGRAM_BOT_TOKEN"
if [ "$MODE" != "simple" ]; then
  echo "      - TS_AUTHKEY"
fi
echo "      (OPENCLAW_TOKEN and BROWSER_TOKEN are pre-generated)"
echo "   3. Edit data/workspace/USER.md — fill in client info"
echo "   4. Edit data/workspace/SOUL.md — customize agent persona if needed"
echo "   5. docker compose up -d"
echo "   6. Pair Telegram: docker compose run --rm openclaw-cli pairing approve telegram <code>"
echo "   7. Update CLIENTS.md with real name, server, and status → active"
echo ""
echo "🔑 Generated tokens (already in .env):"
echo "   OPENCLAW_TOKEN: $OPENCLAW_TOKEN"
echo "   BROWSER_TOKEN:  $BROWSER_TOKEN"
echo "   TS_HOSTNAME:    $TS_HOSTNAME"

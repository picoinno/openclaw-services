#!/bin/bash
# status.sh — Show status of all OpenClaw client stacks
# Usage: ./status.sh [slug]   (no arg = all clients)

SERVICES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Check specific client or all
TARGET="$1"

echo ""
echo -e "${BOLD}🐾 OpenClaw Client Stack Status${RESET}"
echo -e "$(date '+%Y-%m-%d %H:%M:%S')"
echo "────────────────────────────────────────────────────────"

TOTAL=0
RUNNING=0
STOPPED=0
PARTIAL=0

check_client() {
  local slug="$1"
  local dir="$SERVICES_DIR/$slug"

  if [ ! -f "$dir/docker-compose.yml" ]; then
    return
  fi

  TOTAL=$((TOTAL + 1))

  # Get container states
  local statuses
  statuses=$(docker compose -f "$dir/docker-compose.yml" --project-directory "$dir" ps --format "{{.Name}} {{.State}}" 2>/dev/null)

  if [ -z "$statuses" ]; then
    echo -e "  ${YELLOW}⬛ $slug${RESET} — not started"
    STOPPED=$((STOPPED + 1))
    return
  fi

  local total_containers
  total_containers=$(echo "$statuses" | wc -l | tr -d ' ')
  local running_containers
  running_containers=$(echo "$statuses" | grep -c "running" || true)

  # Get Tailscale hostname from .env
  local ts_host=""
  if [ -f "$dir/.env" ]; then
    ts_host=$(grep "^TS_HOSTNAME=" "$dir/.env" | cut -d'=' -f2)
  fi

  # Get AI model
  local ai_model=""
  if [ -f "$dir/.env" ]; then
    ai_model=$(grep "^AI_MODEL=" "$dir/.env" | cut -d'=' -f2)
  fi

  if [ "$running_containers" -eq "$total_containers" ]; then
    echo -e "  ${GREEN}✅ $slug${RESET}"
    RUNNING=$((RUNNING + 1))
  elif [ "$running_containers" -eq 0 ]; then
    echo -e "  ${RED}🔴 $slug${RESET} — all stopped"
    STOPPED=$((STOPPED + 1))
  else
    echo -e "  ${YELLOW}⚠️  $slug${RESET} — partial ($running_containers/$total_containers running)"
    PARTIAL=$((PARTIAL + 1))
  fi

  # Container details
  echo "$statuses" | while read -r name state; do
    if [ "$state" = "running" ]; then
      echo -e "     ${GREEN}▸${RESET} $name  ${GREEN}running${RESET}"
    else
      echo -e "     ${RED}▸${RESET} $name  ${RED}$state${RESET}"
    fi
  done

  [ -n "$ts_host" ] && echo -e "     ${CYAN}tailscale:${RESET} $ts_host"
  [ -n "$ai_model" ] && echo -e "     ${CYAN}model:${RESET}     $ai_model"
  echo ""
}

if [ -n "$TARGET" ]; then
  # Single client
  if [ -d "$SERVICES_DIR/$TARGET" ]; then
    check_client "$TARGET"
  else
    echo -e "  ${RED}❌ Client '$TARGET' not found${RESET}"
  fi
else
  # All clients
  for dir in "$SERVICES_DIR"/*/; do
    slug=$(basename "$dir")
    # Skip non-client dirs
    [ "$slug" = "scripts" ] && continue
    check_client "$slug"
  done
fi

if [ -z "$TARGET" ]; then
  echo "────────────────────────────────────────────────────────"
  echo -e "  Total: ${BOLD}$TOTAL${RESET}  |  ${GREEN}Running: $RUNNING${RESET}  |  ${YELLOW}Partial: $PARTIAL${RESET}  |  ${RED}Stopped: $STOPPED${RESET}"
  echo ""

  if [ "$TOTAL" -eq 0 ]; then
    echo -e "  ${YELLOW}No clients provisioned yet.${RESET}"
    echo -e "  Run ${CYAN}./provision.sh <slug> <tier>${RESET} to add one."
    echo ""
  fi
fi

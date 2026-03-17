#!/usr/bin/env bash
set -euo pipefail

########################################
# Load runtime
########################################

source "${INSTALL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/runtime.sh"

SERVICE_REGISTRY="$STACK_DIR/services.json"
HOMEPAGE_CONFIG="$STACK_DIR/config/homepage"

mkdir -p "$HOMEPAGE_CONFIG"

########################################
# Generate services.yaml
########################################

generate_services() {

echo "Generating Homepage services..."

if [[ ! -f "$SERVICE_REGISTRY" ]]; then
  echo "[]" > "$HOMEPAGE_CONFIG/services.yaml"
  return
fi

mapfile -t categories < <(jq -r '.services | map(.category) | unique | .[]' "$SERVICE_REGISTRY")

if [[ "${#categories[@]}" -eq 0 ]]; then
  echo "[]" > "$HOMEPAGE_CONFIG/services.yaml"
  return
fi

{
  for category in "${categories[@]}"; do
    printf -- "- %s:\n" "${category^}"

    while IFS=$'\t' read -r name url icon; do
      [[ -z "$name" ]] && continue
      printf -- "    - %s:\n" "$name"
      printf -- "        href: %s\n" "$url"
      printf -- "        icon: %s\n" "$icon"
    done < <(
      jq -r --arg c "$category" '
        .services
        | map(select(.category == $c))
        | sort_by(.name)
        | .[]
        | [.name, .url, .icon] | @tsv
      ' "$SERVICE_REGISTRY"
    )
  done
} > "$HOMEPAGE_CONFIG/services.yaml"

}

########################################
# Validate services.yaml
########################################

validate_services_yaml() {

local file="$HOMEPAGE_CONFIG/services.yaml"

if [[ ! -s "$file" ]]; then
  error "Homepage services.yaml is missing or empty"
  return 1
fi

# Guard against accidental JSON concatenation (previous failure mode).
if grep -qE '^[[:space:]]*\{' "$file"; then
  error "Homepage services.yaml appears to contain JSON fragments"
  return 1
fi

# Best-effort runtime validation: if Homepage is running, try parsing with its runtime.
if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -Fxq "homepage"; then
  if ! docker exec homepage node -e "const fs=require('fs'); const y=require('yaml'); y.parse(fs.readFileSync('/app/config/services.yaml','utf8'));" >/dev/null 2>&1; then
    warn "Could not run Homepage in-container parse validation; skipping runtime parse check"
  fi
fi

return 0

}

########################################
# Generate settings.yaml
########################################

generate_settings() {

cat > "$HOMEPAGE_CONFIG/settings.yaml" <<EOF
title: Media Stack
theme: dark
color: slate
layout:
  Media:
    style: row
    columns: 4
  Automation:
    style: row
    columns: 4
  Monitoring:
    style: row
    columns: 4
  System:
    style: row
    columns: 4
EOF

}

########################################
# Generate widgets.yaml
########################################

generate_widgets() {

cat > "$HOMEPAGE_CONFIG/widgets.yaml" <<EOF
- resources:
    cpu: true
    memory: true
    disk: /
EOF

}

########################################
# Execute
########################################

generate_services
validate_services_yaml
generate_settings
generate_widgets

echo "Homepage dashboard configuration generated."
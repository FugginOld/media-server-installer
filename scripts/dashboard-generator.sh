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

jq -r '
.services
| group_by(.category)
| map({
    (.[0].category):
      map({
        (.name): {
          href: .url,
          icon: .icon
        }
      })
  })
| .[]
' "$SERVICE_REGISTRY" > "$HOMEPAGE_CONFIG/services.yaml"

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
generate_settings
generate_widgets

echo "Homepage dashboard configuration generated."
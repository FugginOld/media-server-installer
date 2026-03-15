#!/usr/bin/env bash
set -euo pipefail

########################################
# Plugin discovery
########################################

discover_plugins() {

find "$PLUGIN_DIR" -type f -name "*.sh" \
! -path "*/_template/*"

}

########################################
# Plugin metadata registries
########################################

declare -Ag PLUGIN_PATHS
declare -Ag PLUGIN_CATEGORIES
declare -Ag PLUGIN_DEPENDENCIES
declare -Ag PLUGIN_PORTS
declare -Ag PLUGIN_DASHBOARD

########################################
# Load plugins once
########################################

load_plugins() {

while IFS= read -r file
do

PLUGIN_NAME=""
PLUGIN_CATEGORY=""
PLUGIN_DEPENDS=()
PLUGIN_PORTS=()
PLUGIN_DASHBOARD=false

# Load plugin metadata
source "$file"

name=$(basename "$file" .sh)

PLUGIN_PATHS["$name"]="$file"
PLUGIN_CATEGORIES["$name"]="${PLUGIN_CATEGORY:-Misc}"
PLUGIN_DEPENDENCIES["$name"]="${PLUGIN_DEPENDS[*]:-}"
PLUGIN_PORTS["$name"]="${PLUGIN_PORTS[*]:-}"
PLUGIN_DASHBOARD["$name"]="${PLUGIN_DASHBOARD:-false}"

done < <(discover_plugins)

}

########################################
# Get plugin path
########################################

get_plugin_path() {

local name="$1"

echo "${PLUGIN_PATHS[$name]}"

}

########################################
# Get plugin dependencies
########################################

get_plugin_dependencies() {

local name="$1"

echo "${PLUGIN_DEPENDENCIES[$name]}"

}

########################################
# Get plugin category
########################################

get_plugin_category() {

local name="$1"

echo "${PLUGIN_CATEGORIES[$name]}"

}

########################################
# Get plugin ports
########################################

get_plugin_ports() {

local name="$1"

echo "${PLUGIN_PORTS[$name]}"

}

########################################
# Export functions
########################################

export -f discover_plugins
export -f load_plugins
export -f get_plugin_path
export -f get_plugin_dependencies
export -f get_plugin_category
export -f get_plugin_ports

#!/usr/bin/env bash

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"


########################################
# Load media-stack runtime environment
########################################


########################################
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

CONFIG_FILE="$STACK_DIR/stack.env"

########################################
# Setup directory structure
########################################

setup_directories() {

echo ""
echo "================================"
echo " Media Stack Directory Setup"
echo "================================"
echo ""

########################################
# Choose layout
########################################

echo "Choose directory layout:"
echo ""
echo "1) Default layout"
echo "2) TRaSH Guides layout"
echo ""

read -rp "Selection [1]: " LAYOUT
LAYOUT=${LAYOUT:-1}

########################################
# Base storage path
########################################

DEFAULT_BASE="/data"

read -rp "Enter base storage path [$DEFAULT_BASE]: " BASE_PATH
BASE_PATH=${BASE_PATH:-$DEFAULT_BASE}

########################################
# Default layout
########################################

if [ "$LAYOUT" = "1" ]; then

MEDIA_PATH="$BASE_PATH/media"
MOVIES_PATH="$MEDIA_PATH/movies"
TV_PATH="$MEDIA_PATH/tv"
DOWNLOADS_PATH="$BASE_PATH/downloads"

########################################
# TRaSH layout
########################################

else

MEDIA_PATH="$BASE_PATH/media"
MOVIES_PATH="$MEDIA_PATH/movies"
TV_PATH="$MEDIA_PATH/tv"

DOWNLOADS_PATH="$BASE_PATH/downloads"
COMPLETE_PATH="$DOWNLOADS_PATH/complete"
INCOMPLETE_PATH="$DOWNLOADS_PATH/incomplete"

fi

########################################
# Create directories
########################################

mkdir -p "$MEDIA_PATH"
mkdir -p "$MOVIES_PATH"
mkdir -p "$TV_PATH"
mkdir -p "$DOWNLOADS_PATH"
mkdir -p "$CONFIG_DIR"

if [ "$LAYOUT" = "2" ]; then
mkdir -p "$COMPLETE_PATH"
mkdir -p "$INCOMPLETE_PATH"
fi

########################################
# Persist paths to stack.env
########################################

cat >> "$CONFIG_FILE" <<EOF

MEDIA_PATH=$MEDIA_PATH
MOVIES_PATH=$MOVIES_PATH
TV_PATH=$TV_PATH
DOWNLOADS_PATH=$DOWNLOADS_PATH
EOF

########################################
# Display results
########################################

echo ""
echo "Directory structure created:"
echo ""

echo "Media: $MEDIA_PATH"
echo "Movies: $MOVIES_PATH"
echo "TV: $TV_PATH"
echo "Downloads: $DOWNLOADS_PATH"
echo "Config: $CONFIG_DIR"

if [ "$LAYOUT" = "2" ]; then
echo "Downloads Complete: $COMPLETE_PATH"
echo "Downloads Incomplete: $INCOMPLETE_PATH"
fi

echo ""

}

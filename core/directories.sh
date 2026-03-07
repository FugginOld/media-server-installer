#!/usr/bin/env bash

########################################
# Directory Management
#
# Handles filesystem layout for media,
# downloads, and configuration.
#
# Supports:
#  - Default layout
#  - TRaSH Guides layout
########################################

STACK_DIR="/opt/media-stack"

MEDIA_PATH=""
MOVIES_PATH=""
TV_PATH=""
DOWNLOADS_PATH=""
CONFIG_PATH="$STACK_DIR/config"

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
# Ask for base storage path
########################################

read -rp "Enter base storage path [/data]: " BASE_PATH
BASE_PATH=${BASE_PATH:-/data}

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
INCOMPLETE_PATH="$DOWNLOADS_PATH/incomplete"

fi

########################################
# Create directories
########################################

mkdir -p "$MEDIA_PATH"
mkdir -p "$MOVIES_PATH"
mkdir -p "$TV_PATH"
mkdir -p "$DOWNLOADS_PATH"
mkdir -p "$CONFIG_PATH"

########################################
# Create incomplete directory if needed
########################################

if [ "$LAYOUT" = "2" ]; then
mkdir -p "$INCOMPLETE_PATH"
fi

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
echo "Config: $CONFIG_PATH"

echo ""

}
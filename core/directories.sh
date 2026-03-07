#!/usr/bin/env bash

########################################
# Directory Variables
########################################

STACK_DIR="/opt/media-stack"

MEDIA_PATH=""
MOVIES_PATH=""
TV_PATH=""
DOWNLOADS_PATH=""
CONFIG_DIR=""

########################################
# Setup directories
########################################

setup_directories() {

echo ""
echo "Media Stack Directory Setup"
echo ""

echo "Select directory layout:"
echo "1) Default"
echo "2) TRaSH Guides"

read -rp "Selection: " LAYOUT

echo ""
read -rp "Enter base storage path (example: /data): " BASE_PATH

########################################
# Default Layout
########################################

if [ "$LAYOUT" = "1" ]; then

MEDIA_PATH="$BASE_PATH/media"
MOVIES_PATH="$MEDIA_PATH/movies"
TV_PATH="$MEDIA_PATH/tv"

DOWNLOADS_PATH="$BASE_PATH/downloads"
CONFIG_DIR="$BASE_PATH/config"

########################################
# TRaSH Layout
########################################

else

MEDIA_PATH="$BASE_PATH/media"
MOVIES_PATH="$MEDIA_PATH/movies"
TV_PATH="$MEDIA_PATH/tv"

DOWNLOADS_PATH="$BASE_PATH/downloads"
CONFIG_DIR="$BASE_PATH/config"

fi

########################################
# Create directories
########################################

mkdir -p "$MOVIES_PATH"
mkdir -p "$TV_PATH"
mkdir -p "$DOWNLOADS_PATH"
mkdir -p "$DOWNLOADS_PATH/incomplete"
mkdir -p "$CONFIG_DIR"

echo ""
echo "Directory structure created:"
echo "$MEDIA_PATH"
echo "$DOWNLOADS_PATH"
echo "$CONFIG_DIR"
echo ""

}
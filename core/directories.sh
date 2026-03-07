#!/usr/bin/env bash

########################################
# Directory layout selection
########################################

DIR_LAYOUT="default"

select_directory_layout() {

DIR_LAYOUT=$(whiptail \
--title "Directory Structure" \
--menu "Select media directory layout" \
15 70 2 \
"default" "Simple layout (movies / tv / downloads)" \
"trash" "TRaSH Guides layout" \
3>&1 1>&2 2>&3)

echo "Selected layout: $DIR_LAYOUT"

}

########################################
# Configure directory variables
########################################

configure_media_directories() {

case "$DIR_LAYOUT" in

default)

MOVIES_PATH="$MEDIA_PATH/movies"
TV_PATH="$MEDIA_PATH/tv"
DOWNLOADS_PATH="$DOWNLOAD_PATH"

;;

trash)

DATA_ROOT="$MEDIA_PATH/data"

MEDIA_ROOT="$DATA_ROOT/media"
USENET_ROOT="$DATA_ROOT/usenet"

MOVIES_PATH="$MEDIA_ROOT/movies"
TV_PATH="$MEDIA_ROOT/tv"

DOWNLOADS_PATH="$USENET_ROOT/complete"
INCOMPLETE_PATH="$USENET_ROOT/incomplete"

;;

*)

MOVIES_PATH="$MEDIA_PATH/movies"
TV_PATH="$MEDIA_PATH/tv"
DOWNLOADS_PATH="$DOWNLOAD_PATH"

;;

esac

echo "Movies path: $MOVIES_PATH"
echo "TV path: $TV_PATH"
echo "Downloads path: $DOWNLOADS_PATH"

}

########################################
# Create directory structure
########################################

create_media_folders() {

echo "Creating media directories..."

mkdir -p "$MOVIES_PATH"
mkdir -p "$TV_PATH"
mkdir -p "$DOWNLOADS_PATH"

if [ "$DIR_LAYOUT" = "trash" ]; then

mkdir -p "$INCOMPLETE_PATH"

fi

}
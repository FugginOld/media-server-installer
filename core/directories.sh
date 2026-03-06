#!/usr/bin/env bash

########################################
# Directory Layout Selection
########################################

DIR_LAYOUT="default"

select_directory_layout() {

DIR_LAYOUT=$(whiptail \
--title "Directory Structure" \
--menu "Choose media directory layout:" \
15 70 4 \
"default" "Simple layout (movies / tv / downloads)" \
"trash" "TRaSH Guides layout" \
3>&1 1>&2 2>&3)

echo "Selected directory layout: $DIR_LAYOUT"

}

########################################
# Configure Directory Paths
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

MOVIES_PATH="$DATA_ROOT/media/movies"
TV_PATH="$DATA_ROOT/media/tv"

USENET_PATH="$DATA_ROOT/usenet"

DOWNLOADS_PATH="$USENET_PATH/complete"
INCOMPLETE_PATH="$USENET_PATH/incomplete"

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
# Create Directory Structure
########################################

create_media_folders() {

echo "Creating media directories..."

mkdir -p "$MOVIES_PATH"
mkdir -p "$TV_PATH"

if [ "$DIR_LAYOUT" = "trash" ]; then

mkdir -p "$INCOMPLETE_PATH"
mkdir -p "$DOWNLOADS_PATH"

else

mkdir -p "$DOWNLOADS_PATH"

fi

}

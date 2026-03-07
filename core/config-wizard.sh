#!/usr/bin/env bash

CONFIG_FILE="/opt/media-stack/stack.env"

TIMEZONE="UTC"
PUID="1000"
PGID="1000"
PLEX_CLAIM=""
SAB_API_KEY=""

configure_timezone() {

TIMEZONE=$(whiptail \
--title "Timezone" \
--inputbox "Enter timezone (example America/New_York)" \
10 60 "$TIMEZONE" \
3>&1 1>&2 2>&3)

}

configure_user_ids() {

PUID=$(whiptail \
--title "User ID" \
--inputbox "Enter PUID" \
10 60 "$PUID" \
3>&1 1>&2 2>&3)

PGID=$(whiptail \
--title "Group ID" \
--inputbox "Enter PGID" \
10 60 "$PGID" \
3>&1 1>&2 2>&3)

}

configure_plex() {

PLEX_CLAIM=$(whiptail \
--title "Plex Claim Token" \
--inputbox "Enter Plex claim token (optional)" \
10 60 "" \
3>&1 1>&2 2>&3)

}

configure_sab() {

SAB_API_KEY=$(whiptail \
--title "SABnzbd API Key" \
--inputbox "Enter SAB API key (optional)" \
10 60 "" \
3>&1 1>&2 2>&3)

}

save_config() {

mkdir -p /opt/media-stack

cat <<EOF > $CONFIG_FILE
TIMEZONE=$TIMEZONE
PUID=$PUID
PGID=$PGID
PLEX_CLAIM=$PLEX_CLAIM
SAB_API_KEY=$SAB_API_KEY
EOF

}

run_configuration_wizard() {

configure_timezone
configure_user_ids
configure_plex
configure_sab

save_config

}
#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
REGISTRY_FILE="$STACK_DIR/services.json"

init_registry() {

if [ ! -f "$REGISTRY_FILE" ]; then

cat <<EOF > $REGISTRY_FILE
{
  "services": []
}
EOF

fi

}

register_service() {

NAME=$1
URL=$2
CATEGORY=$3
ICON=$4

init_registry

TMP_FILE=$(mktemp)

jq ".services += [{
  \"name\": \"$NAME\",
  \"url\": \"$URL\",
  \"category\": \"$CATEGORY\",
  \"icon\": \"$ICON\"
}]" $REGISTRY_FILE > $TMP_FILE

mv $TMP_FILE $REGISTRY_FILE

}

list_services() {

cat $REGISTRY_FILE

}
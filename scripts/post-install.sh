#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"

RADARR_URL="http://localhost:7878"
SONARR_URL="http://localhost:8989"
PROWLARR_URL="http://localhost:9696"
SAB_URL="http://localhost:8080"

########################################
# Wait for services
########################################

wait_for_service() {

URL=$1
NAME=$2

echo "Waiting for $NAME..."

until curl -s "$URL" >/dev/null
do
sleep 5
done

echo "$NAME is ready"

}

########################################
# Detect installed services
########################################

SERVICES_FILE="$STACK_DIR/services.json"

has_service() {

jq -e ".services[] | select(.name == \"$1\")" \
$SERVICES_FILE >/dev/null

}

########################################
# Wait for core services
########################################

if has_service "Radarr"; then
wait_for_service "$RADARR_URL/api/v3/system/status" "Radarr"
fi

if has_service "Sonarr"; then
wait_for_service "$SONARR_URL/api/v3/system/status" "Sonarr"
fi

if has_service "Prowlarr"; then
wait_for_service "$PROWLARR_URL/api/v1/system/status" "Prowlarr"
fi

if has_service "SABnzbd"; then
wait_for_service "$SAB_URL" "SABnzbd"
fi

########################################
# Retrieve API keys
########################################

get_api_key() {

CONTAINER=$1
FILE=$2

docker exec $CONTAINER grep ApiKey $FILE \
| sed -e 's/.*<ApiKey>//' -e 's/<\/ApiKey>//'

}

########################################
# Extract keys
########################################

if has_service "Radarr"; then
RADARR_KEY=$(get_api_key radarr /config/config.xml)
fi

if has_service "Sonarr"; then
SONARR_KEY=$(get_api_key sonarr /config/config.xml)
fi

if has_service "Prowlarr"; then
PROWLARR_KEY=$(get_api_key prowlarr /config/config.xml)
fi

########################################
# Configure SAB categories
########################################

if has_service "SABnzbd"; then

echo "Configuring SABnzbd categories..."

curl -s "$SAB_URL/api?mode=set_config&section=categories&name=movies&dir=movies"
curl -s "$SAB_URL/api?mode=set_config&section=categories&name=tv&dir=tv"

fi

########################################
# Connect Radarr to SAB
########################################

if has_service "Radarr" && has_service "SABnzbd"; then

echo "Connecting Radarr → SABnzbd"

curl -s -X POST "$RADARR_URL/api/v3/downloadclient" \
-H "X-Api-Key: $RADARR_KEY" \
-H "Content-Type: application/json" \
-d '{
"name":"SABnzbd",
"implementation":"Sabnzbd",
"enable":true,
"fields":[
{"name":"host","value":"sabnzbd"},
{"name":"port","value":8080},
{"name":"category","value":"movies"}
]
}'

fi

########################################
# Connect Sonarr to SAB
########################################

if has_service "Sonarr" && has_service "SABnzbd"; then

echo "Connecting Sonarr → SABnzbd"

curl -s -X POST "$SONARR_URL/api/v3/downloadclient" \
-H "X-Api-Key: $SONARR_KEY" \
-H "Content-Type: application/json" \
-d '{
"name":"SABnzbd",
"implementation":"Sabnzbd",
"enable":true,
"fields":[
{"name":"host","value":"sabnzbd"},
{"name":"port","value":8080},
{"name":"category","value":"tv"}
]
}'

fi

########################################
# Link Prowlarr to Radarr
########################################

if has_service "Prowlarr" && has_service "Radarr"; then

echo "Connecting Prowlarr → Radarr"

curl -s -X POST "$PROWLARR_URL/api/v1/applications" \
-H "X-Api-Key: $PROWLARR_KEY" \
-H "Content-Type: application/json" \
-d "{
'name':'Radarr',
'implementation':'Radarr',
'enable':true,
'fields':[
{'name':'baseUrl','value':'$RADARR_URL'},
{'name':'apiKey','value':'$RADARR_KEY'}
]
}"

fi

########################################
# Link Prowlarr to Sonarr
########################################

if has_service "Prowlarr" && has_service "Sonarr"; then

echo "Connecting Prowlarr → Sonarr"

curl -s -X POST "$PROWLARR_URL/api/v1/applications" \
-H "X-Api-Key: $PROWLARR_KEY" \
-H "Content-Type: application/json" \
-d "{
'name':'Sonarr',
'implementation':'Sonarr',
'enable':true,
'fields':[
{'name':'baseUrl','value':'$SONARR_URL'},
{'name':'apiKey','value':'$SONARR_KEY'}
]
}"

fi

########################################
# Dynamic Grafana dashboards
########################################

if has_service "Grafana"; then

echo "Configuring Grafana dashboards..."

bash ./scripts/grafana-dynamic.sh

fi

echo "Post-install configuration complete"
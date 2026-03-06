#!/usr/bin/env bash

########################################
# Post Install Automation
########################################

STACK_DIR="/opt/media-stack"

RADARR_URL="http://radarr:7878"
SONARR_URL="http://sonarr:8989"
PROWLARR_URL="http://prowlarr:9696"
SAB_URL="http://sabnzbd:8080"

echo "Starting post-install configuration..."

########################################
# Wait for services to start
########################################

wait_for_service() {

URL=$1
NAME=$2

echo "Waiting for $NAME..."

until curl -s $URL >/dev/null
do
sleep 5
done

echo "$NAME is ready."

}

wait_for_service "$RADARR_URL/api/v3/system/status" "Radarr"
wait_for_service "$SONARR_URL/api/v3/system/status" "Sonarr"
wait_for_service "$PROWLARR_URL/api/v1/system/status" "Prowlarr"
wait_for_service "$SAB_URL" "SABnzbd"

########################################
# Retrieve API Keys
########################################

echo "Retrieving API keys..."

RADARR_KEY=$(docker exec radarr grep ApiKey /config/config.xml | sed -e 's/.*<ApiKey>//' -e 's/<\/ApiKey>//')
SONARR_KEY=$(docker exec sonarr grep ApiKey /config/config.xml | sed -e 's/.*<ApiKey>//' -e 's/<\/ApiKey>//')
PROWLARR_KEY=$(docker exec prowlarr grep ApiKey /config/config.xml | sed -e 's/.*<ApiKey>//' -e 's/<\/ApiKey>//')

########################################
# Configure SABnzbd categories
########################################

echo "Configuring SABnzbd categories..."

curl -s "$SAB_URL/api?mode=set_config&section=categories&name=movies&dir=movies"
curl -s "$SAB_URL/api?mode=set_config&section=categories&name=tv&dir=tv"

########################################
# Add SABnzbd to Radarr
########################################

echo "Connecting Radarr → SABnzbd..."

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

########################################
# Add SABnzbd to Sonarr
########################################

echo "Connecting Sonarr → SABnzbd..."

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

########################################
# Link Prowlarr to Radarr
########################################

echo "Connecting Prowlarr → Radarr..."

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

########################################
# Link Prowlarr to Sonarr
########################################

echo "Connecting Prowlarr → Sonarr..."

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

########################################
# Grafana dashboard provisioning
########################################

if docker ps | grep -q grafana; then

echo "Provisioning Grafana dashboards..."

mkdir -p $STACK_DIR/config/grafana/dashboards

fi

echo "Post-install automation complete."

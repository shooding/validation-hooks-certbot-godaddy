#!/bin/bash

LOG_DIR="/tmp"
LOG_FILE="$LOG_DIR/cleanup.$CERTBOT_DOMAIN.log"

echo "" > $LOG_FILE

function log {
  DATE=$(date)
  echo "$DATE: $1" >> $LOG_FILE
}

log "[BEGIN]"

# Get your API key from https://developer.godaddy.com
API_KEY="your_api_key_here"
API_SECRET="your_api_secret_here"

# Init variables
DOMAIN=""
SUBDOMAIN=""

# Detection of root domain or subdomain
if [ "$(uname -s)" == "Darwin" ]
then
  # macOS
  DOMAIN=$(expr "$CERTBOT_DOMAIN" : '.*\.\(.*\..*\)')
  if [[ ! -z "${DOMAIN// }" ]]
  then
    log "SUBDOMAIN DETECTED"
    SUBDOMAIN=$(echo "$CERTBOT_DOMAIN" | awk -F".$DOMAIN" '{print $1}')
  else
    DOMAIN=$CERTBOT_DOMAIN
  fi
else
  # linux
  DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')
  if [[ ! -z "${DOMAIN// }" ]]
  then
    log "SUBDOMAIN DETECTED"
    SUBDOMAIN=$(echo "$CERTBOT_DOMAIN" | sed "s/.$DOMAIN//")    
  else
    DOMAIN=$CERTBOT_DOMAIN
  fi
fi

log "DOMAIN $DOMAIN"
log "SUBDOMAIN $SUBDOMAIN"

# Update TXT record
RECORD_TYPE="TXT"
RECORD_VALUE="none"

if [[ ! -z "${SUBDOMAIN// }" ]]
then
  RECORD_NAME="_acme-challenge.$SUBDOMAIN"
else
  RECORD_NAME="_acme-challenge"
fi

log "RECORD_NAME $RECORD_NAME"

# Update the previous record to default value
RESPONSE_CODE=$(curl -s -X PUT -w %{http_code} \
-H "Authorization: sso-key $API_KEY:$API_SECRET" \
-H "Content-Type: application/json" \
-d "[{\"data\": \"$RECORD_VALUE\", \"ttl\": 600}]" \
"https://api.godaddy.com/v1/domains/$DOMAIN/records/$RECORD_TYPE/$RECORD_NAME")

if [ "$RESPONSE_CODE" == "200" ]
then
  log "OK"
else
  log "KO"
  log $RESPONSE_CODE
fi

log "[END]"

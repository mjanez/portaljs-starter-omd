#!/bin/bash
# =============================================================================
# OpenMetadata Bot Token Initialization Script
# =============================================================================
# This script creates a bot token in OpenMetadata and updates the .env
# file with the generated token for PortalJS to use.
#
# Prerequisites:
#   - OpenMetadata server must be running and healthy
#   - curl and jq must be installed
#
# Usage:
#   chmod +x scripts/00_init-bot-token.sh
#   ./scripts/00_init-bot-token.sh
# =============================================================================

set -e

# Configuration
OPENMETADATA_URL="${OPENMETADATA_URL:-http://localhost:8585}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
BOT_NAME="${BOT_NAME:-portaljs-bot}"
ENV_FILE=".env"

echo "=============================================="
echo " OpenMetadata Bot Token Initialization"
echo "=============================================="
echo ""

# Check dependencies
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required but not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed."; exit 1; }

# Wait for OpenMetadata to be ready
echo "Checking OpenMetadata server status..."
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s "${OPENMETADATA_URL}/api/v1/system/version" >/dev/null 2>&1; then
        echo "✓ OpenMetadata server is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "  Waiting for OpenMetadata... (${RETRY_COUNT}/${MAX_RETRIES})"
    sleep 5
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Error: OpenMetadata server did not become ready in time."
    exit 1
fi

# Login and get JWT token
echo ""
echo "Authenticating as admin..."
# OpenMetadata 1.9+ requires password in Base64
PASSWORD_B64=$(echo -n "${ADMIN_PASSWORD}" | base64)
LOGIN_RESPONSE=$(curl -s -X POST "${OPENMETADATA_URL}/api/v1/users/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${ADMIN_USER}@open-metadata.org\",\"password\":\"${PASSWORD_B64}\"}")

JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.accessToken // empty')

if [ -z "$JWT_TOKEN" ]; then
    echo "Error: Failed to authenticate. Response:"
    echo "$LOGIN_RESPONSE"
    exit 1
fi
echo "✓ Authentication successful!"

# Check if bot already exists
echo ""
echo "Checking if bot '${BOT_NAME}' exists..."
BOT_RESPONSE=$(curl -s -X GET "${OPENMETADATA_URL}/api/v1/bots/name/${BOT_NAME}" \
    -H "Authorization: Bearer ${JWT_TOKEN}" \
    -H "Content-Type: application/json")

BOT_ID=$(echo "$BOT_RESPONSE" | jq -r '.id // empty')

if [ -n "$BOT_ID" ]; then
    echo "  Bot already exists with ID: ${BOT_ID}"
else
    # Create bot user first
    echo "Creating bot user '${BOT_NAME}'..."
    USER_RESPONSE=$(curl -s -X POST "${OPENMETADATA_URL}/api/v1/users" \
        -H "Authorization: Bearer ${JWT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"${BOT_NAME}\",
            \"email\": \"${BOT_NAME}@openmetadata.org\",
            \"isBot\": true,
            \"authenticationMechanism\": {
                \"authType\": \"JWT\",
                \"config\": {
                    \"JWTTokenExpiry\": \"Unlimited\"
                }
            }
        }")
    
    USER_ID=$(echo "$USER_RESPONSE" | jq -r '.id // empty')
    
    if [ -z "$USER_ID" ]; then
        echo "Error: Failed to create bot user. Response:"
        echo "$USER_RESPONSE"
        exit 1
    fi
    
    echo "✓ Bot user created with ID: ${USER_ID}"
    
    # Create the bot
    echo "Creating bot..."
    BOT_CREATE_RESPONSE=$(curl -s -X POST "${OPENMETADATA_URL}/api/v1/bots" \
        -H "Authorization: Bearer ${JWT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"${BOT_NAME}\",
            \"botUser\": \"${BOT_NAME}\",
            \"description\": \"Bot for PortalJS frontend access\"
        }")
    
    BOT_ID=$(echo "$BOT_CREATE_RESPONSE" | jq -r '.id // empty')
    
    if [ -z "$BOT_ID" ]; then
        echo "Warning: Bot creation returned unexpected response:"
        echo "$BOT_CREATE_RESPONSE"
    else
        echo "✓ Bot created with ID: ${BOT_ID}"
    fi
fi

# Get the bot token
echo ""
echo "Retrieving bot token..."
BOT_USER_RESPONSE=$(curl -s -X GET "${OPENMETADATA_URL}/api/v1/users/name/${BOT_NAME}" \
    -H "Authorization: Bearer ${JWT_TOKEN}" \
    -H "Content-Type: application/json" \
    --data-urlencode "fields=authenticationMechanism")

BOT_TOKEN=$(echo "$BOT_USER_RESPONSE" | jq -r '.authenticationMechanism.config.JWTToken // empty')

if [ -z "$BOT_TOKEN" ]; then
    echo "Error: Could not retrieve bot token. Response:"
    echo "$BOT_USER_RESPONSE"
    exit 1
fi

echo "✓ Bot token retrieved successfully!"

# Update .env file
echo ""
echo "Updating ${ENV_FILE}..."
if [ ! -f "$ENV_FILE" ]; then
    cp .env.example "$ENV_FILE" 2>/dev/null || echo "DMS_TOKEN=" > "$ENV_FILE"
fi

# Update or add DMS_TOKEN
if grep -q "^DMS_TOKEN=" "$ENV_FILE"; then
    sed -i "s|^DMS_TOKEN=.*|DMS_TOKEN=${BOT_TOKEN}|" "$ENV_FILE"
else
    echo "DMS_TOKEN=${BOT_TOKEN}" >> "$ENV_FILE"
fi

echo "✓ Token saved to ${ENV_FILE}"

# Summary
echo ""
echo "=============================================="
echo " Setup Complete!"
echo "=============================================="
echo ""
echo "Bot Name:  ${BOT_NAME}"
echo "Token:     ${BOT_TOKEN:0:50}..."
echo ""
echo "The token has been saved to ${ENV_FILE}"
echo ""
echo "To apply the new token, restart PortalJS:"
echo "  docker-compose up -d --build portaljs"
echo ""

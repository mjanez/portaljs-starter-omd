#!/bin/bash
# =============================================================================
# Setup sample data source in OpenMetadata
# =============================================================================
# Registers the sample PostgreSQL database as a Database Service in OpenMetadata,
# creates and triggers a metadata ingestion pipeline, creates a sample Domain,
# creates Data Products, and creates a Glossary so PortalJS has content to display.
#
# Prerequisites:
#   - OpenMetadata server must be running and healthy (http://localhost:8585)
#   - curl and jq must be installed (available in Git Bash on Windows)
#
# Usage:
#   ./scripts/01_setup-sample-data.sh
# =============================================================================

set -e

OPENMETADATA_URL="${OPENMETADATA_URL:-http://localhost:8585}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
SERVICE_NAME="${SERVICE_NAME:-sample-postgresql}"
PG_HOST="${PG_HOST:-portaljs_sample_postgresql}"
PG_PORT="${PG_PORT:-5432}"
PG_USER="${PG_USER:-openmetadata_user}"
PG_PASSWORD="${PG_PASSWORD:-password}"
PG_DATABASE="${PG_DATABASE:-postgres}"

echo "=============================================="
echo " OpenMetadata Sample Data Setup"
echo "=============================================="
echo ""

# Check dependencies
for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is required but not installed."
        echo "If you are on Windows, try running this from Git Bash."
        exit 1
    fi
done

# Helper function to make API calls
omd_api() {
    local method=$1
    local endpoint=$2
    local body=$3
    
    if [ -n "$body" ]; then
        curl -s -X "$method" "${OPENMETADATA_URL}${endpoint}" \
            -H "${AUTH_HEADER}" \
            -H "Content-Type: application/json" \
            -d "$body"
    else
        curl -s -X "$method" "${OPENMETADATA_URL}${endpoint}" \
            -H "${AUTH_HEADER}" \
            -H "Content-Type: application/json"
    fi
}

# --- 0. Authenticate ---
echo "Authenticating with OpenMetadata..."
# Password must be Base64 encoded for OMD 1.9+
PASSWORD_B64=$(echo -n "${ADMIN_PASSWORD}" | base64)

LOGIN_RESPONSE=$(curl -s -X POST "${OPENMETADATA_URL}/api/v1/users/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${ADMIN_USER}@open-metadata.org\",\"password\":\"${PASSWORD_B64}\"}")

JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.accessToken // empty')

if [ -z "$JWT_TOKEN" ]; then
    echo "Error: Failed to authenticate"
    echo "$LOGIN_RESPONSE"
    exit 1
fi
echo "[OK] Authenticated!"

AUTH_HEADER="Authorization: Bearer ${JWT_TOKEN}"

# --- 1. Create Database Service ---
echo ""
echo "Step 1: Creating Database Service '${SERVICE_NAME}'..."

SERVICE_ID=$(omd_api GET "/api/v1/services/databaseServices/name/${SERVICE_NAME}" | jq -r '.id // empty')

if [ -n "$SERVICE_ID" ]; then
    echo "  Service already exists with ID: ${SERVICE_ID}"
else
    echo "  Service does not exist, creating..."
    SERVICE_BODY=$(jq -n \
                  --arg name "$SERVICE_NAME" \
                  --arg pg_host "$PG_HOST" \
                  --arg pg_port "$PG_PORT" \
                  --arg pg_user "$PG_USER" \
                  --arg pg_pass "$PG_PASSWORD" \
                  --arg pg_db "$PG_DATABASE" \
                  '{
                    name: $name,
                    displayName: "Sample PostgreSQL",
                    description: "Sample PostgreSQL database with demo data for PortalJS",
                    serviceType: "Postgres",
                    connection: {
                        config: {
                            type: "Postgres",
                            hostPort: "\($pg_host):\($pg_port)",
                            username: $pg_user,
                            authType: { password: $pg_pass },
                            database: $pg_db
                        }
                    }
                  }')

    SERVICE_RESPONSE=$(omd_api POST "/api/v1/services/databaseServices" "$SERVICE_BODY")
    SERVICE_ID=$(echo "$SERVICE_RESPONSE" | jq -r '.id // empty')
    
    if [ -z "$SERVICE_ID" ]; then
        echo "Error creating service: $SERVICE_RESPONSE"
        exit 1
    fi
    echo "[OK] Database Service created with ID: ${SERVICE_ID}"
fi

# --- 2. Create Ingestion Pipeline ---
echo ""
echo "Step 2: Creating Ingestion Pipeline..."

PIPELINE_FQN="${SERVICE_NAME}.metadata-ingestion"
PIPELINE_ID=$(omd_api GET "/api/v1/services/ingestionPipelines/name/${PIPELINE_FQN}" | jq -r '.id // empty')

if [ -n "$PIPELINE_ID" ]; then
    echo "  Pipeline already exists with ID: ${PIPELINE_ID}"
else
    echo "  Pipeline does not exist, creating..."
    PIPELINE_BODY=$(jq -n \
                   --arg service_id "$SERVICE_ID" \
                   '{
                    name: "metadata-ingestion",
                    displayName: "Metadata Ingestion",
                    pipelineType: "metadata",
                    service: { id: $service_id, type: "databaseService" },
                    sourceConfig: {
                        config: {
                            type: "DatabaseMetadata",
                            markDeletedTables: true,
                            includeTables: true,
                            includeViews: true
                        }
                    },
                    airflowConfig: { scheduleInterval: null }
                   }')

    PIPELINE_RESPONSE=$(omd_api POST "/api/v1/services/ingestionPipelines" "$PIPELINE_BODY")
    PIPELINE_ID=$(echo "$PIPELINE_RESPONSE" | jq -r '.id // empty')
    
    # --- 3. Deploy & Trigger Pipeline ---
    if [ -n "$PIPELINE_ID" ]; then
        echo "[OK] Ingestion Pipeline created with ID: ${PIPELINE_ID}"
        
        echo "  Deploying pipeline to Airflow..."
        omd_api POST "/api/v1/services/ingestionPipelines/deploy/${PIPELINE_ID}" "{}" > /dev/null
        echo "  [OK] Deployed"

        echo "  Triggering metadata ingestion..."
        omd_api POST "/api/v1/services/ingestionPipelines/trigger/${PIPELINE_ID}" "{}" > /dev/null
        echo "  [OK] Triggered"
    else
        echo "Error creating pipeline: $PIPELINE_RESPONSE"
    fi
fi

# --- 4. Create Domain ---
echo ""
echo "Step 4: Creating sample Domain..."

DOMAIN_NAME="sample-data"
DOMAIN_EXISTS=$(omd_api GET "/api/v1/domains/name/${DOMAIN_NAME}" | jq -r '.id // empty')

if [ -n "$DOMAIN_EXISTS" ]; then
    echo "  Domain '${DOMAIN_NAME}' already exists"
else
    DOMAIN_BODY=$(jq -n --arg name "$DOMAIN_NAME" '{
        name: $name,
        displayName: "Sample Data",
        description: "Sample domain containing demo data products",
        domainType: "Aggregate"
    }')
    
    omd_api POST "/api/v1/domains" "$DOMAIN_BODY" > /dev/null
    echo "[OK] Domain 'Sample Data' created!"
fi

# --- 5. Wait for Ingestion ---
echo ""
echo "Step 5: Checking ingestion status..."
MAX_RETRIES=10
RETRY_COUNT=0
TABLES_FOUND=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    TOTAL_TABLES=$(omd_api GET "/api/v1/tables?limit=0&service=${SERVICE_NAME}" | jq -r '.paging.total // 0')
    
    if [ "$TOTAL_TABLES" -gt 0 ]; then
        echo "[OK] Found ${TOTAL_TABLES} tables."
        TABLES_FOUND=true
        break
    else
        echo "  Waiting for tables to appear... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 5
        RETRY_COUNT=$((RETRY_COUNT+1))
    fi
done

if [ "$TABLES_FOUND" = false ]; then
    echo "Warning: Ingestion might still be running. Data Products creation may fail if tables are missing."
fi

# --- 6. Create Data Products ---
echo ""
echo "Step 6: Creating sample Data Products..."

get_table_id() {
    local FQN=$1
    omd_api GET "/api/v1/tables/name/${FQN}" | jq -r '.id // empty'
}

ACTOR_ID=$(get_table_id "${SERVICE_NAME}.${PG_DATABASE}.public.actor")
FILM_ACTOR_ID=$(get_table_id "${SERVICE_NAME}.${PG_DATABASE}.public.film_actor")
CUSTOMERS_ID=$(get_table_id "${SERVICE_NAME}.${PG_DATABASE}.public.sensitive_customers")

# Data Product 1
DP1_NAME="film-database"
DP1_EXISTS=$(omd_api GET "/api/v1/dataProducts/name/${DP1_NAME}" | jq -r '.id // empty')

if [ -z "$DP1_EXISTS" ]; then
    ASSETS_JSON="[]"
    if [ -n "$ACTOR_ID" ] && [ -n "$FILM_ACTOR_ID" ]; then
       ASSETS_JSON=$(jq -n \
          --arg id1 "$ACTOR_ID" \
          --arg id2 "$FILM_ACTOR_ID" \
          '[{"id": $id1, "type": "table"}, {"id": $id2, "type": "table"}]')
    elif [ -n "$ACTOR_ID" ]; then
       ASSETS_JSON=$(jq -n --arg id1 "$ACTOR_ID" '[{"id": $id1, "type": "table"}]')
    fi

    echo "  Creating '${DP1_NAME}'..."
    DP1_BODY=$(jq -n \
              --arg name "$DP1_NAME" \
              --arg domain "$DOMAIN_NAME" \
              --argjson assets "$ASSETS_JSON" \
              '{
                name: $name,
                displayName: "Film Database",
                description: "Sample film and actor database.",
                domains: [$domain], 
                assets: $assets
              }')
    
    DP1_RESP=$(omd_api POST "/api/v1/dataProducts" "$DP1_BODY")
    
    if echo "$DP1_RESP" | jq -e '.id' > /dev/null; then
        echo "  [OK] Created"
    else
        echo "  Error creating '${DP1_NAME}': $(echo "$DP1_RESP" | jq -r '.message // .')"
        # echo "DEBUG: Payload was: $DP1_BODY"
    fi
else
    echo "  Data Product '${DP1_NAME}' already exists"
fi

# Data Product 2
DP2_NAME="customer-records"
DP2_EXISTS=$(omd_api GET "/api/v1/dataProducts/name/${DP2_NAME}" | jq -r '.id // empty')

if [ -z "$DP2_EXISTS" ]; then
    ASSETS_JSON="[]"
    if [ -n "$CUSTOMERS_ID" ]; then
       ASSETS_JSON=$(jq -n --arg id1 "$CUSTOMERS_ID" '[{"id": $id1, "type": "table"}]')
    fi

    echo "  Creating '${DP2_NAME}'..."
    DP2_BODY=$(jq -n \
              --arg name "$DP2_NAME" \
              --arg domain "$DOMAIN_NAME" \
              --argjson assets "$ASSETS_JSON" \
              '{
                name: $name,
                displayName: "Customer Records",
                description: "Customer information database.",
                domains: [$domain], 
                assets: $assets
              }')

    DP2_RESP=$(omd_api POST "/api/v1/dataProducts" "$DP2_BODY")

    if echo "$DP2_RESP" | jq -e '.id' > /dev/null; then
        echo "  [OK] Created"
    else
        echo "  Error creating '${DP2_NAME}': $(echo "$DP2_RESP" | jq -r '.message // .')"
    fi
else
    echo "  Data Product '${DP2_NAME}' already exists"
fi


# --- 7. Create Glossary ---
echo ""
echo "Step 7: Creating Glossaries..."

GLOSSARY_NAME="Business_Glossary"
GLOSSARY_EXISTS=$(omd_api GET "/api/v1/glossaries/name/${GLOSSARY_NAME}" | jq -r '.id // empty')

if [ -z "$GLOSSARY_EXISTS" ]; then
    echo "  Creating '${GLOSSARY_NAME}'..."
    GLOSSARY_BODY=$(jq -n --arg name "$GLOSSARY_NAME" '{
        name: $name,
        displayName: "Business Glossary",
        description: "Standard business terminology.",
        reviewers: [],
        tags: []
    }')

    GLOSSARY_RESP=$(omd_api POST "/api/v1/glossaries" "$GLOSSARY_BODY")
    
    if echo "$GLOSSARY_RESP" | jq -e '.id' > /dev/null; then
        echo "  [OK] Created"
        
        # Add Term
        echo "  Adding term 'Customer'..."
        TERM_BODY=$(jq -n --arg glos "$GLOSSARY_NAME" '{
            glossary: $glos,
            name: "Customer",
            displayName: "Customer",
            description: "An individual who purchases goods or services.",
            synonyms: ["Client", "Buyer"]
        }')
        
        omd_api POST "/api/v1/glossaryTerms" "$TERM_BODY" > /dev/null
        echo "  [OK] Term Added"
    else
        echo "  Error creating glossary: $(echo "$GLOSSARY_RESP" | jq -r '.message // .')"
    fi
else
    echo "  Glossary '${GLOSSARY_NAME}' already exists"
fi

echo ""
echo "=============================================="
echo " Setup Complete!"
echo "=============================================="
echo "Data should now be visible in PortalJS:"
echo " - Organizations: Should show 'Sample Data' domain"
echo " - Search: Should show 'Film Database' and 'Customer Records'"
echo " - Glossaries: Should show 'Business Glossary'"
echo ""

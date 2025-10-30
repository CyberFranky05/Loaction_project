#!/bin/bash

# Script to generate nginx.conf from template with environment variables
# Usage: ./generate-nginx-conf.sh

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set defaults if not provided
DOMAIN=${DOMAIN:-"yourdomain.com"}
DOMAIN_WWW=${DOMAIN_WWW:-"www.yourdomain.com"}
FRONTEND_PORT=${FRONTEND_PORT:-3000}
BACKEND_PORT=${BACKEND_PORT:-3000}
KEYCLOAK_PORT=${KEYCLOAK_PORT:-8080}

# Generate nginx.conf from template
envsubst '${DOMAIN} ${DOMAIN_WWW} ${FRONTEND_PORT} ${BACKEND_PORT} ${KEYCLOAK_PORT}' \
    < nginx/nginx.conf.template \
    > nginx/nginx.conf

echo "✅ Generated nginx/nginx.conf with:"
echo "   DOMAIN: $DOMAIN"
echo "   DOMAIN_WWW: $DOMAIN_WWW"
echo "   FRONTEND_PORT: $FRONTEND_PORT"
echo "   BACKEND_PORT: $BACKEND_PORT"
echo "   KEYCLOAK_PORT: $KEYCLOAK_PORT"

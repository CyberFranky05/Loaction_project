# Domain and Port Configuration - Centralized Environment Variables

## Overview
All hardcoded domain names and ports have been replaced with environment variables for easy configuration and portability.

## Changes Made

### 1. Updated `.env.example` and `.env`
Added centralized configuration variables:
- `DOMAIN` - Primary domain (e.g., mrelectron.xyz)
- `DOMAIN_WWW` - WWW subdomain (e.g., www.mrelectron.xyz)
- `BACKEND_PORT` - Backend API port (default: 3000)
- `FRONTEND_PORT` - Frontend port (default: 3000)
- `KEYCLOAK_PORT` - Keycloak port (default: 8080)
- `POSTGRES_PORT` - PostgreSQL port (default: 5432)
- `NGINX_HTTP_PORT` - Nginx HTTP port (default: 80)
- `NGINX_HTTPS_PORT` - Nginx HTTPS port (default: 443)

### 2. Updated `docker-compose.prod.yml`
- Keycloak: Uses `${DOMAIN}` for KC_HOSTNAME
- Backend: Uses `${KEYCLOAK_PORT}`, `${BACKEND_PORT}`, `${CORS_ORIGIN}`
- Nginx: Uses `${NGINX_HTTP_PORT}` and `${NGINX_HTTPS_PORT}` for port mapping
- Certbot: Uses `${DOMAIN}` and `${DOMAIN_WWW}` for certificate generation

### 3. Created `nginx/nginx.conf.template`
Template file with placeholders for:
- `${DOMAIN}` - Primary domain
- `${DOMAIN_WWW}` - WWW subdomain
- `${FRONTEND_PORT}` - Frontend proxy port
- `${BACKEND_PORT}` - Backend proxy port
- `${KEYCLOAK_PORT}` - Keycloak proxy port

### 4. Created `scripts/generate-nginx-conf.sh`
Bash script to generate `nginx/nginx.conf` from the template using environment variables.

### 5. Updated `nginx/start-nginx.sh`
Now reads `${DOMAIN}` from environment to locate SSL certificates dynamically.

### 6. Updated `README.md`
- Updated configuration instructions
- Added section for generating nginx config from template
- Updated environment variables reference table

## Usage

### Quick Start
1. Edit `.env` and set your domain:
   ```bash
   DOMAIN=yourdomain.com
   DOMAIN_WWW=www.yourdomain.com
   ```

2. (Optional) Generate nginx config from template:
   ```bash
   bash scripts/generate-nginx-conf.sh
   ```

3. Deploy:
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

### Changing Domain
To change your domain in the future:
1. Update `DOMAIN` and `DOMAIN_WWW` in `.env`
2. Update `CORS_ORIGIN` to match (e.g., `https://newdomain.com`)
3. Regenerate nginx config (if using template)
4. Obtain new SSL certificates
5. Restart services

### Changing Ports
To use different ports:
1. Update port variables in `.env` (e.g., `NGINX_HTTP_PORT=8080`)
2. Regenerate nginx config (if using template)
3. Restart services

## Files Modified
- `.env.example` - Added domain and port variables
- `.env` - Updated with current configuration
- `docker-compose.prod.yml` - Replaced hardcoded values with env vars
- `nginx/start-nginx.sh` - Uses `${DOMAIN}` for SSL cert path
- `README.md` - Updated documentation

## Files Created
- `nginx/nginx.conf.template` - Template for nginx configuration
- `scripts/generate-nginx-conf.sh` - Script to generate nginx.conf from template

## Benefits
✅ Single source of truth for all configuration
✅ Easy domain migration
✅ Flexible port configuration
✅ No need to edit multiple files
✅ Environment-specific configurations (dev/staging/prod)
✅ Reduced human error when deploying to new domains

## Notes
- The existing `nginx/nginx.conf` still works with hardcoded values
- Use the template approach for maximum flexibility
- Docker Compose automatically loads `.env` file
- SSL certificates are domain-specific - obtain new certs when changing domains

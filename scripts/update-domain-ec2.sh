#!/bin/bash

# Script to update domain and get SSL certificates on EC2
# Usage: bash scripts/update-domain-ec2.sh

set -e

echo "🔧 Updating domain to electron.wolfonyxmedia.com"

# Stop all services
echo "⏸️  Stopping services..."
docker-compose -f docker-compose.prod.yml down

# Remove old SSL certificates (if any)
echo "🗑️  Cleaning old certificates..."
docker volume rm location_project_certbot_conf 2>/dev/null || true

# Update nginx.conf with new domain (if using template)
if [ -f "scripts/generate-nginx-conf.sh" ]; then
    echo "📝 Generating nginx config..."
    bash scripts/generate-nginx-conf.sh
fi

# Start services with HTTP only first
echo "🚀 Starting services (HTTP only)..."
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
echo "✅ Checking service status..."
docker-compose -f docker-compose.prod.yml ps

# Get SSL certificates
echo "🔐 Getting SSL certificates from Let's Encrypt..."
docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email chaudharymahendra@gmail.com \
  --agree-tos \
  --no-eff-email \
  -d electron.wolfonyxmedia.com \
  -d www.electron.wolfonyxmedia.com

# Check if certificates were obtained
if [ -d "/var/lib/docker/volumes/location_project_certbot_conf/_data/live/electron.wolfonyxmedia.com" ]; then
    echo "✅ SSL certificates obtained successfully!"
else
    echo "❌ Failed to obtain SSL certificates"
    echo "Check if:"
    echo "  1. DNS is pointing to this server"
    echo "  2. Ports 80 and 443 are open"
    echo "  3. No other service is using port 80"
    exit 1
fi

# Restart nginx to load the certificates
echo "🔄 Restarting nginx with HTTPS..."
docker-compose -f docker-compose.prod.yml restart nginx

# Wait for nginx to restart
sleep 5

# Test the connection
echo "🧪 Testing HTTPS connection..."
if curl -sI https://electron.wolfonyxmedia.com | grep -q "HTTP/2 200"; then
    echo "✅ HTTPS is working!"
else
    echo "⚠️  HTTPS test failed, but certificates are installed"
    echo "You may need to wait for DNS propagation"
fi

echo ""
echo "🎉 Domain update complete!"
echo ""
echo "Your services are now available at:"
echo "  - Frontend: https://electron.wolfonyxmedia.com"
echo "  - Backend API: https://electron.wolfonyxmedia.com/api/v1"
echo "  - Keycloak: https://electron.wolfonyxmedia.com/auth"
echo ""
echo "⚠️  IMPORTANT: Update Cloudflare SSL/TLS settings:"
echo "  1. Go to Cloudflare dashboard"
echo "  2. SSL/TLS → Overview"
echo "  3. Set to 'Full' (not 'Full (strict)')"
echo ""

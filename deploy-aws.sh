#!/bin/bash

# AWS EC2 Deployment Script for Location-Based Auth System
# Run this script on your EC2 instance after cloning the repository

set -e

echo "================================================"
echo "AWS EC2 Deployment - Location Auth System"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "❌ Please do not run this script as root"
    exit 1
fi

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo "❌ .env.production file not found!"
    echo "Please copy .env.production.example to .env.production and fill in the values."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Prerequisites checked"
echo ""

# Prompt for deployment type
echo "Select deployment type:"
echo "1) First-time deployment (with SSL certificate generation)"
echo "2) Update existing deployment"
read -p "Enter choice (1 or 2): " DEPLOY_TYPE

if [ "$DEPLOY_TYPE" = "1" ]; then
    echo ""
    echo "================================================"
    echo "First-Time Deployment"
    echo "================================================"
    echo ""
    
    # Verify DNS configuration
    echo "⚠️  Before continuing, ensure DNS records are configured:"
    echo "   - mrelectron.xyz → 13.200.149.67 (Your EC2 IP)"
    echo "   - www.mrelectron.xyz → 13.200.149.67"
    echo ""
    read -p "Are DNS records configured? (yes/no): " DNS_READY
    
    if [ "$DNS_READY" != "yes" ]; then
        echo "Please configure DNS records first and wait for propagation (5-10 minutes)"
        exit 1
    fi
    
    echo ""
    echo "Step 1: Creating SSL directory..."
    mkdir -p nginx/ssl
    
    echo "Step 2: Starting Nginx and Certbot for SSL certificate..."
    docker-compose -f docker-compose.prod.yml up -d nginx certbot
    
    echo "Waiting for certificate generation (this may take a minute)..."
    sleep 30
    
    echo ""
    echo "Checking certbot logs..."
    docker-compose -f docker-compose.prod.yml logs certbot
    
    echo ""
    read -p "Did certificate generation succeed? (yes/no): " CERT_SUCCESS
    
    if [ "$CERT_SUCCESS" != "yes" ]; then
        echo "❌ Certificate generation failed. Please check the logs and DNS configuration."
        echo "You can manually run: docker-compose -f docker-compose.prod.yml logs certbot"
        exit 1
    fi
    
    echo ""
    echo "Step 3: Restarting Nginx with SSL certificates..."
    docker-compose -f docker-compose.prod.yml restart nginx
    
    echo ""
    echo "Step 4: Starting all services..."
    docker-compose -f docker-compose.prod.yml up -d
    
    echo ""
    echo "Step 5: Waiting for services to be healthy..."
    sleep 30
    
    echo ""
    echo "================================================"
    echo "⚠️  IMPORTANT: Manual Keycloak Configuration Required"
    echo "================================================"
    echo ""
    echo "Please follow these steps to configure Keycloak:"
    echo ""
    echo "1. Access Keycloak Admin Console:"
    echo "   URL: https://mrelectron.xyz/auth"
    echo "   Username: admin"
    echo "   Password: (from .env.production KEYCLOAK_ADMIN_PASSWORD)"
    echo ""
    echo "2. Create Realm: location-auth-realm"
    echo "3. Create Backend Client: location-auth-backend (confidential)"
    echo "4. Create Frontend Client: location-auth-frontend (public)"
    echo "5. Configure redirect URIs and service account roles"
    echo ""
    echo "See AWS_EC2_DEPLOYMENT.md for detailed instructions."
    echo ""
    read -p "Press Enter after completing Keycloak configuration..."
    
    echo ""
    echo "Restarting backend with Keycloak configuration..."
    docker-compose -f docker-compose.prod.yml restart backend
    
elif [ "$DEPLOY_TYPE" = "2" ]; then
    echo ""
    echo "================================================"
    echo "Update Existing Deployment"
    echo "================================================"
    echo ""
    
    echo "Step 1: Pulling latest code..."
    git pull origin aws-ec2-deployment
    
    echo ""
    echo "Step 2: Stopping services..."
    docker-compose -f docker-compose.prod.yml down
    
    echo ""
    echo "Step 3: Rebuilding images..."
    docker-compose -f docker-compose.prod.yml build --no-cache
    
    echo ""
    echo "Step 4: Starting services..."
    docker-compose -f docker-compose.prod.yml up -d
    
else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo ""
echo "================================================"
echo "Deployment Status"
echo "================================================"
echo ""
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "================================================"
echo "✅ Deployment Complete!"
echo "================================================"
echo ""
echo "Access your application:"
echo "  - Frontend: https://mrelectron.xyz"
echo "  - API: https://mrelectron.xyz/api/v1/health"
echo "  - Keycloak: https://mrelectron.xyz/auth"
echo ""
echo "View logs:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "Monitor services:"
echo "  docker-compose -f docker-compose.prod.yml ps"
echo ""
echo "See AWS_EC2_DEPLOYMENT.md for more information."
echo ""

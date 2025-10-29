# Vercel + EC2 Deployment Guide

This guide explains how to deploy the Location Authentication System with:
- **Frontend**: Hosted on Vercel (SvelteKit)
- **Backend + Keycloak + PostgreSQL**: Hosted on EC2 via Docker

## Architecture Overview

```
┌─────────────────┐
│  Vercel         │
│  (Frontend)     │ ──────┐
└─────────────────┘       │
                          │ HTTPS
                          ▼
                  ┌───────────────────┐
                  │   AWS EC2         │
                  │  ┌─────────────┐  │
                  │  │   Nginx     │  │
                  │  │   (Proxy)   │  │
                  │  └──────┬──────┘  │
                  │         │         │
                  │    ┌────┴────┐    │
                  │    │         │    │
                  │  ┌─▼──┐   ┌──▼─┐  │
                  │  │API │   │Auth│  │
                  │  │    │   │    │  │
                  │  └────┘   └─┬──┘  │
                  │             │     │
                  │         ┌───▼──┐  │
                  │         │ PG   │  │
                  │         └──────┘  │
                  └───────────────────┘
```

## Prerequisites

1. **Vercel Account**: Sign up at https://vercel.com
2. **AWS EC2 Instance**: Ubuntu server with Docker installed
3. **Domain**: Two subdomains configured:
   - `your-app.vercel.app` (or custom domain on Vercel)
   - `api.yourdomain.com` (pointing to EC2 IP)
4. **GitHub Repository**: Code pushed to GitHub

## Part 1: Backend Deployment (EC2)

### Step 1: Prepare EC2 Instance

```bash
# SSH into your EC2 instance
ssh ubuntu@your-ec2-ip

# Clone the repository
git clone https://github.com/YOUR_USERNAME/Loaction_project.git
cd Loaction_project

# Checkout the vercel-deployment branch
git checkout vercel-deployment
```

### Step 2: Configure Environment Variables

```bash
# Copy the backend environment template
cp .env.backend.example .env

# Edit the environment file
nano .env
```

Update these critical values:
```bash
# Your backend API subdomain
BACKEND_DOMAIN=api.yourdomain.com

# Your Vercel frontend URL (add after deploying to Vercel)
VERCEL_FRONTEND_URL=https://your-app.vercel.app

# Update all passwords and secrets
POSTGRES_PASSWORD=<strong-password>
KEYCLOAK_ADMIN_PASSWORD=<strong-password>
JWT_SECRET=<random-secret>
KEYCLOAK_CLIENT_SECRET=<your-keycloak-secret>

# Add your Supabase credentials
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<your-key>
SUPABASE_ANON_KEY=<your-key>

# SSL email for Let's Encrypt
SSL_EMAIL=your@email.com
```

### Step 3: Generate Nginx Configuration

```bash
# Create a script to generate nginx config from template
cat > scripts/generate-nginx-backend.sh << 'EOF'
#!/bin/bash
set -a
source .env
set +a
envsubst '${BACKEND_DOMAIN} ${BACKEND_PORT} ${KEYCLOAK_PORT} ${VERCEL_FRONTEND_URL}' \
  < nginx/nginx.backend.conf.template \
  > nginx/nginx.backend.conf
EOF

chmod +x scripts/generate-nginx-backend.sh

# Generate the nginx configuration
./scripts/generate-nginx-backend.sh
```

### Step 4: Configure DNS

In your DNS provider (e.g., Cloudflare):
1. Add an A record: `api.yourdomain.com` → `your-ec2-public-ip`
2. Set to **DNS only** (gray cloud) initially for SSL certificate generation

### Step 5: Deploy Backend Services

```bash
# Stop containers (if running)
docker-compose -f docker-compose.backend.yml down

# Get SSL certificate
docker-compose -f docker-compose.backend.yml run --rm certbot certonly \
  --standalone \
  --preferred-challenges http \
  --email your@email.com \
  --agree-tos \
  --no-eff-email \
  -d api.yourdomain.com

# Start all services
docker-compose -f docker-compose.backend.yml up -d

# Check status
docker ps
```

### Step 6: Verify Backend

```bash
# Test health endpoint
curl https://api.yourdomain.com/health

# Test API endpoint
curl https://api.yourdomain.com/api/health

# Test Keycloak
curl https://api.yourdomain.com/auth/realms/location-auth-realm
```

### Step 7: Update Keycloak Configuration

1. Open Keycloak admin console: `https://api.yourdomain.com/auth/admin`
2. Login with credentials from `.env` (KEYCLOAK_ADMIN_PASSWORD)
3. Navigate to: **Clients** → **location-auth-frontend**
4. Update **Valid Redirect URIs**:
   ```
   https://your-app.vercel.app/*
   https://*.vercel.app/*
   ```
5. Update **Web Origins**:
   ```
   https://your-app.vercel.app
   https://*.vercel.app
   ```
6. Click **Save**

## Part 2: Frontend Deployment (Vercel)

### Step 1: Push Code to GitHub

```bash
# Make sure you're on vercel-deployment branch
git checkout vercel-deployment

# Add and commit all files
git add .
git commit -m "Setup Vercel + EC2 deployment configuration"

# Push to GitHub
git push origin vercel-deployment
```

### Step 2: Connect to Vercel

1. Go to https://vercel.com/dashboard
2. Click **Add New** → **Project**
3. Import your GitHub repository
4. Select the **vercel-deployment** branch
5. Configure project:
   - **Framework Preset**: SvelteKit
   - **Root Directory**: `frontend`
   - **Build Command**: `npm run build`
   - **Output Directory**: `build`

### Step 3: Configure Environment Variables in Vercel

In Vercel dashboard → Settings → Environment Variables, add:

```bash
PUBLIC_API_URL=https://api.yourdomain.com
PUBLIC_KEYCLOAK_URL=https://api.yourdomain.com/auth
PUBLIC_KEYCLOAK_REALM=location-auth-realm
PUBLIC_KEYCLOAK_CLIENT_ID=location-auth-frontend
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
```

### Step 4: Deploy

1. Click **Deploy**
2. Wait for build to complete
3. Vercel will provide a URL: `https://your-app.vercel.app`

### Step 5: Update Backend CORS

Go back to EC2 and update the `.env` file:

```bash
# SSH to EC2
ssh ubuntu@your-ec2-ip
cd Loaction_project

# Edit .env
nano .env
```

Update:
```bash
VERCEL_FRONTEND_URL=https://your-app.vercel.app
```

Restart services:
```bash
./scripts/generate-nginx-backend.sh
docker-compose -f docker-compose.backend.yml restart nginx
```

### Step 6: Test the Application

1. Open `https://your-app.vercel.app`
2. Try signing up / signing in
3. Test location features
4. Check browser console for any CORS errors

## Part 3: Custom Domain (Optional)

### For Vercel Frontend

1. In Vercel dashboard → Settings → Domains
2. Add your custom domain (e.g., `app.yourdomain.com`)
3. Follow Vercel's DNS instructions
4. Update Keycloak redirect URIs with new domain

### For EC2 Backend

Already configured via `BACKEND_DOMAIN` in `.env`

## Monitoring & Logs

### Backend Logs (EC2)

```bash
# All services
docker-compose -f docker-compose.backend.yml logs -f

# Specific service
docker logs -f location-auth-backend
docker logs -f location-auth-keycloak
docker logs -f location-auth-nginx
```

### Frontend Logs (Vercel)

1. Vercel Dashboard → Your Project → Deployments
2. Click on a deployment → View Function Logs

## Troubleshooting

### CORS Errors

**Symptom**: Browser console shows CORS errors

**Solution**:
1. Verify `VERCEL_FRONTEND_URL` in EC2 `.env` matches your Vercel URL exactly
2. Regenerate nginx config: `./scripts/generate-nginx-backend.sh`
3. Restart nginx: `docker-compose -f docker-compose.backend.yml restart nginx`
4. Check Keycloak redirect URIs include Vercel domain

### Keycloak Redirect Issues

**Symptom**: "Invalid redirect URI" error

**Solution**:
1. Login to Keycloak admin console
2. Update **Valid Redirect URIs** for `location-auth-frontend` client
3. Make sure to include both:
   - `https://your-app.vercel.app/*`
   - `https://*.vercel.app/*` (for preview deployments)

### SSL Certificate Issues

**Symptom**: "ERR_CERT_AUTHORITY_INVALID" or similar

**Solution**:
```bash
# On EC2, renew certificate
docker-compose -f docker-compose.backend.yml run --rm certbot renew
docker-compose -f docker-compose.backend.yml restart nginx
```

### Backend Not Responding

**Symptom**: API requests timeout or fail

**Solution**:
```bash
# Check all containers are running
docker ps

# Check nginx config is valid
docker exec location-auth-nginx nginx -t

# Check backend logs
docker logs location-auth-backend --tail 50

# Restart services
docker-compose -f docker-compose.backend.yml restart
```

## Updating the Application

### Update Backend

```bash
# SSH to EC2
ssh ubuntu@your-ec2-ip
cd Loaction_project

# Pull latest changes
git pull origin vercel-deployment

# Rebuild and restart services
docker-compose -f docker-compose.backend.yml pull
docker-compose -f docker-compose.backend.yml up -d --force-recreate
```

### Update Frontend

Vercel automatically deploys when you push to the branch:

```bash
# Local machine
git add .
git commit -m "Update frontend"
git push origin vercel-deployment
```

Vercel will automatically build and deploy the new version.

## Cost Estimates

- **Vercel**: Free tier (100GB bandwidth, unlimited deployments)
- **AWS EC2**: ~$10-30/month (t3.small or t3.medium)
- **Domain**: ~$10-15/year
- **Total**: ~$10-30/month + domain

## Security Checklist

- [ ] SSL certificates configured for both frontend and backend
- [ ] Strong passwords for PostgreSQL and Keycloak
- [ ] JWT secret is random and secure
- [ ] Keycloak admin console not publicly accessible (only via EC2)
- [ ] Environment variables not committed to Git
- [ ] CORS properly configured (not allowing *)
- [ ] Security headers enabled in nginx
- [ ] Rate limiting configured in nginx
- [ ] EC2 security groups properly configured (only 80, 443, 22)

## Support

For issues or questions:
1. Check logs on both Vercel and EC2
2. Review this documentation
3. Check GitHub issues
4. Contact: piyushsingh5629@gmail.com

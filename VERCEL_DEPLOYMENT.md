# Vercel + EC2 Deployment Guide

This guide explains how to deploy the Location Authentication System with:
- **Frontend**: Hosted on Vercel (SvelteKit)
- **Backend + Keycloak + PostgreSQL**: Hosted on EC2 via Docker (HTTP only, using EC2 public IP)

## Architecture Overview

```
┌─────────────────┐
│  Vercel         │
│  (Frontend)     │ ──────┐
│  HTTPS          │       │
└─────────────────┘       │ HTTP
                          ▼
                  ┌───────────────────┐
                  │   AWS EC2         │
                  │  (Public IP)      │
                  │  ┌─────────────┐  │
                  │  │   Nginx     │  │
                  │  │   (Port 80) │  │
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

**Note**: This setup uses HTTP (not HTTPS) for the backend since SSL certificates require a domain name. The frontend on Vercel will use HTTPS.

## Prerequisites

1. **Vercel Account**: Sign up at https://vercel.com
2. **AWS EC2 Instance**: Ubuntu server with Docker installed
3. **EC2 Security Group**: Allow inbound traffic on port 80 (HTTP)
4. **GitHub Repository**: Code pushed to GitHub

**Important**: This setup uses HTTP on the backend (no SSL). For production with sensitive data, consider:
- Using a custom domain with SSL certificate
- Setting up a VPN or private network
- Using AWS Certificate Manager with Application Load Balancer

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
# Your EC2 public IP address
EC2_PUBLIC_IP=3.XXX.XXX.XXX

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
```

**Note**: No SSL_EMAIL needed since we're using HTTP without SSL certificates.

### Step 3: Generate Nginx Configuration

```bash
# Create a script to generate nginx config from template
cat > scripts/generate-nginx-backend.sh << 'EOF'
#!/bin/bash
set -a
source .env
set +a
envsubst '${BACKEND_PORT} ${KEYCLOAK_PORT} ${VERCEL_FRONTEND_URL}' \
  < nginx/nginx.backend.http.conf.template \
  > nginx/nginx.backend.conf
EOF

chmod +x scripts/generate-nginx-backend.sh

# Generate the nginx configuration
./scripts/generate-nginx-backend.sh
```

### Step 4: Configure EC2 Security Group

In AWS Console → EC2 → Security Groups:
1. Select your EC2 instance's security group
2. Add inbound rule:
   - **Type**: HTTP
   - **Port**: 80
   - **Source**: 0.0.0.0/0 (anywhere)
3. Make sure SSH (port 22) is also allowed for your IP

### Step 5: Deploy Backend Services

```bash
# Start all services (no SSL certificate needed)
docker-compose -f docker-compose.backend.yml up -d

# Check status
docker ps
```

### Step 6: Verify Backend

```bash
# Get your EC2 public IP
curl ifconfig.me

# Test health endpoint (replace with your IP)
curl http://YOUR-EC2-IP/health

# Test API endpoint
curl http://YOUR-EC2-IP/api/health

# Test Keycloak
curl http://YOUR-EC2-IP/auth/realms/location-auth-realm
```

### Step 7: Update Keycloak Configuration

1. Open Keycloak admin console: `http://YOUR-EC2-IP/auth/admin`
2. Login with credentials from `.env` (KEYCLOAK_ADMIN_PASSWORD)
3. Navigate to: **Clients** → **location-auth-frontend**
4. Update **Valid Redirect URIs**:
   ```
   https://your-app.vercel.app/*
   https://*.vercel.app/*
   http://localhost:*
   ```
5. Update **Web Origins**:
   ```
   https://your-app.vercel.app
   https://*.vercel.app
   http://localhost:5173
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
PUBLIC_API_URL=http://YOUR-EC2-PUBLIC-IP
PUBLIC_KEYCLOAK_URL=http://YOUR-EC2-PUBLIC-IP/auth
PUBLIC_KEYCLOAK_REALM=location-auth-realm
PUBLIC_KEYCLOAK_CLIENT_ID=location-auth-frontend
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
```

**Replace `YOUR-EC2-PUBLIC-IP`** with your actual EC2 public IP address (e.g., `3.XXX.XXX.XXX`).

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

## Part 3: Testing & Verification

### Mixed Content Warning

Modern browsers may show warnings when HTTPS frontend (Vercel) calls HTTP backend (EC2). To handle this:

1. **Development**: Browsers will allow it
2. **Production**: Consider one of these options:
   - Get a domain and SSL certificate (recommended)
   - Use Cloudflare Tunnel or ngrok for HTTPS
   - Deploy backend on a platform with free SSL (Render, Railway, etc.)

### Test the Application

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

### Mixed Content Errors

**Symptom**: Browser blocks HTTP requests from HTTPS site, "Mixed Content" error

**Solution**:
1. **Short-term**: Test with browser security relaxed (not recommended for production)
2. **Long-term**: Get a domain and SSL certificate for backend:
   - Register a cheap domain ($10-15/year)
   - Point subdomain to EC2 IP
   - Use Let's Encrypt for free SSL
   - Update all configs to use HTTPS

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
- **AWS EC2**: ~$10-30/month (t3.small or t3.medium recommended)
- **Total**: ~$10-30/month

**Optional add-ons**:
- Domain name: ~$10-15/year
- SSL certificate: Free (Let's Encrypt) with domain

## Upgrading to HTTPS (Recommended for Production)

If you want to add SSL to your backend later:

1. **Get a domain**: Register at Namecheap, GoDaddy, or Cloudflare
2. **Point to EC2**: Add A record `api.yourdomain.com` → EC2 IP
3. **Update configs**: 
   - Change `EC2_PUBLIC_IP` to `BACKEND_DOMAIN` in `.env`
   - Use `nginx.backend.conf.template` (HTTPS version)
   - Run certbot to get SSL certificate
4. **Update Vercel**: Change `PUBLIC_API_URL` from `http://` to `https://`

## Security Checklist

- [ ] EC2 security group allows only necessary ports (80, 22)
- [ ] Strong passwords for PostgreSQL and Keycloak
- [ ] JWT secret is random and secure
- [ ] Environment variables not committed to Git
- [ ] CORS properly configured (not allowing *)
- [ ] Security headers enabled in nginx
- [ ] Rate limiting configured in nginx
- [ ] Consider adding HTTPS with domain + SSL certificate for production

## Support

For issues or questions:
1. Check logs on both Vercel and EC2
2. Review this documentation
3. Check GitHub issues
4. Contact: piyushsingh5629@gmail.com

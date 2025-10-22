# AWS EC2 Production Deployment Guide

This guide will help you deploy the Location-Based Authentication System to AWS EC2 with SSL on your domain **mrelectron.xyz**.

## Architecture Overview

The production setup uses:
- **mrelectron.xyz** or **app.mrelectron.xyz** - Frontend (SvelteKit)
- **api.mrelectron.xyz** - Backend API (NestJS)
- **auth.mrelectron.xyz** - Keycloak Authentication Server
- Nginx as reverse proxy with SSL termination
- PostgreSQL for Keycloak database
- Docker Compose for container orchestration

## Prerequisites

1. **AWS EC2 Instance**
   - Ubuntu 22.04 LTS or similar
   - Minimum: t3.medium (2 vCPU, 4GB RAM)
   - Recommended: t3.large (2 vCPU, 8GB RAM)
   - Security Group with ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)

2. **Domain Configuration**
   - Domain: mrelectron.xyz
   - DNS A records pointing to your EC2 public IP:
     - mrelectron.xyz → EC2_PUBLIC_IP
     - app.mrelectron.xyz → EC2_PUBLIC_IP
     - api.mrelectron.xyz → EC2_PUBLIC_IP
     - auth.mrelectron.xyz → EC2_PUBLIC_IP

3. **Required Information**
   - EC2 public IP address
   - SSH key pair for EC2 access
   - Supabase credentials (URL, service role key, anon key)
   - Email for SSL certificate notifications

## Step 1: DNS Configuration

Configure your domain's DNS records:

```
Type    Name    Value               TTL
A       @       YOUR_EC2_PUBLIC_IP  300
A       app     YOUR_EC2_PUBLIC_IP  300
A       api     YOUR_EC2_PUBLIC_IP  300
A       auth    YOUR_EC2_PUBLIC_IP  300
```

Wait 5-10 minutes for DNS propagation. Verify with:
```bash
nslookup mrelectron.xyz
nslookup app.mrelectron.xyz
nslookup api.mrelectron.xyz
nslookup auth.mrelectron.xyz
```

## Step 2: Connect to EC2 Instance

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

## Step 3: Install Docker and Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# Logout and login again for group changes
exit
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

## Step 4: Install Git and Clone Repository

```bash
# Install Git
sudo apt install git -y

# Clone your repository (replace with your repo URL)
git clone https://github.com/yourusername/location_project.git
cd location_project

# Switch to AWS EC2 branch
git checkout aws-ec2-deployment
```

## Step 5: Configure Environment Variables

```bash
# Copy environment template
cp .env.production.example .env.production

# Edit environment file
nano .env.production
```

Fill in the following values:

```env
# PostgreSQL (use a strong password)
POSTGRES_PASSWORD=your_secure_postgres_password_here

# Keycloak Admin (use a strong password)
KEYCLOAK_ADMIN_PASSWORD=your_secure_keycloak_admin_password_here
KEYCLOAK_CLIENT_SECRET=generate_random_secret_here

# JWT Secret (generate random string)
JWT_SECRET=generate_random_jwt_secret_here

# SSL Email
SSL_EMAIL=your_email@example.com

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Generate secure secrets:**
```bash
# Generate random secrets (run each separately)
openssl rand -base64 32
openssl rand -base64 32
openssl rand -base64 32
```

Save and exit (Ctrl+X, Y, Enter).

## Step 6: Initial SSL Certificate Setup

Before starting all services, we need to obtain SSL certificates:

```bash
# Create nginx directory for SSL
mkdir -p nginx/ssl

# Start nginx and certbot for initial certificate
docker-compose -f docker-compose.prod.yml up -d nginx certbot

# Wait for certificate generation (check logs)
docker-compose -f docker-compose.prod.yml logs certbot

# If successful, restart nginx
docker-compose -f docker-compose.prod.yml restart nginx
```

If certificate generation fails:
- Ensure DNS records are properly configured
- Check that ports 80 and 443 are open in EC2 security group
- Verify domain ownership

## Step 7: Start All Services

```bash
# Build and start all services
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

## Step 8: Configure Keycloak Realm (First Time)

After Keycloak starts, you need to manually configure the realm:

1. Access Keycloak Admin Console:
   - URL: https://auth.mrelectron.xyz
   - Username: admin
   - Password: (KEYCLOAK_ADMIN_PASSWORD from .env.production)

2. Create Realm:
   - Click "Create Realm"
   - Name: `location-auth-realm`
   - Enabled: Yes
   - Click "Create"

3. Create Backend Client:
   - Go to Clients → Create Client
   - Client ID: `location-auth-backend`
   - Client Protocol: openid-connect
   - Click "Next"
   - Client authentication: ON
   - Authorization: OFF
   - Authentication flow: Standard flow, Direct access grants
   - Click "Save"
   - Go to "Credentials" tab
   - Copy the "Client Secret" and update KEYCLOAK_CLIENT_SECRET in .env.production
   - Go to "Service account roles" tab
   - Click "Assign role"
   - Filter by clients: realm-management
   - Select: manage-users, view-users, view-clients
   - Click "Assign"

4. Create Frontend Client:
   - Go to Clients → Create Client
   - Client ID: `location-auth-frontend`
   - Client Protocol: openid-connect
   - Click "Next"
   - Client authentication: OFF (public client)
   - Authorization: OFF
   - Authentication flow: Standard flow, Direct access grants
   - Valid redirect URIs:
     - https://mrelectron.xyz/*
     - https://app.mrelectron.xyz/*
   - Web origins:
     - https://mrelectron.xyz
     - https://app.mrelectron.xyz
   - Click "Save"

5. Configure Realm Settings:
   - Go to Realm Settings → General
   - Frontend URL: https://auth.mrelectron.xyz
   - Require SSL: all requests
   - Click "Save"

After configuration, restart the backend:
```bash
docker-compose -f docker-compose.prod.yml restart backend
```

## Step 9: Verify Deployment

Test each service:

1. **Keycloak**: https://auth.mrelectron.xyz
   - Should show Keycloak welcome page

2. **Frontend**: https://mrelectron.xyz
   - Should load the application

3. **Backend API**: https://api.mrelectron.xyz/api/v1/health
   - Should return health status

4. **Test Signup**:
   - Go to https://mrelectron.xyz/signup
   - Create a test account
   - Check Keycloak and Supabase for user creation

5. **Test Signin**:
   - Go to https://mrelectron.xyz/signin
   - Sign in with test account
   - Should redirect to dashboard

## Step 10: SSL Certificate Auto-Renewal

Let's Encrypt certificates expire after 90 days. Set up auto-renewal:

```bash
# Create renewal script
cat > ~/renew-certs.sh << 'EOF'
#!/bin/bash
cd ~/location_project
docker-compose -f docker-compose.prod.yml run --rm certbot renew
docker-compose -f docker-compose.prod.yml restart nginx
EOF

chmod +x ~/renew-certs.sh

# Add to crontab (runs daily at 3 AM)
(crontab -l 2>/dev/null; echo "0 3 * * * ~/renew-certs.sh >> ~/certbot-renewal.log 2>&1") | crontab -
```

## Maintenance Commands

### View Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
docker-compose -f docker-compose.prod.yml logs -f keycloak
```

### Restart Services
```bash
# All services
docker-compose -f docker-compose.prod.yml restart

# Specific service
docker-compose -f docker-compose.prod.yml restart backend
```

### Update Application
```bash
# Pull latest changes
git pull origin aws-ec2-deployment

# Rebuild and restart
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

### Backup Keycloak Database
```bash
# Create backup
docker exec location-auth-postgres pg_dump -U keycloak keycloak > keycloak-backup-$(date +%Y%m%d).sql

# Restore backup
cat keycloak-backup-YYYYMMDD.sql | docker exec -i location-auth-postgres psql -U keycloak keycloak
```

## Monitoring

### Check Container Health
```bash
docker-compose -f docker-compose.prod.yml ps
```

### Check Resource Usage
```bash
docker stats
```

### Check Disk Space
```bash
df -h
docker system df
```

### Clean Up Old Images/Containers
```bash
docker system prune -a
```

## Troubleshooting

### Keycloak Not Starting
- Check logs: `docker-compose -f docker-compose.prod.yml logs keycloak`
- Verify PostgreSQL is healthy: `docker-compose -f docker-compose.prod.yml ps postgres`
- Check database connection in .env.production

### Backend API Errors
- Check logs: `docker-compose -f docker-compose.prod.yml logs backend`
- Verify Keycloak is accessible from backend container
- Check CORS_ORIGIN includes your frontend domains

### Frontend Not Loading
- Check logs: `docker-compose -f docker-compose.prod.yml logs frontend`
- Verify PUBLIC_API_URL is correct
- Check nginx configuration

### SSL Certificate Issues
- Verify DNS records point to correct IP
- Check ports 80 and 443 are open
- View certbot logs: `docker-compose -f docker-compose.prod.yml logs certbot`
- Manually renew: `docker-compose -f docker-compose.prod.yml run --rm certbot renew`

### CORS Errors
- Update CORS_ORIGIN in .env.production
- Restart backend: `docker-compose -f docker-compose.prod.yml restart backend`
- Check Keycloak client Web Origins settings

## Security Recommendations

1. **Firewall Configuration**
   ```bash
   sudo ufw enable
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

2. **Regular Updates**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Monitor Logs**
   - Set up log rotation
   - Monitor for suspicious activity
   - Use AWS CloudWatch for advanced monitoring

4. **Backup Strategy**
   - Regular database backups
   - Store backups in S3
   - Test restore procedures

5. **Secrets Management**
   - Never commit .env.production to git
   - Use strong, unique passwords
   - Rotate secrets regularly

## Support

If you encounter issues:
1. Check logs for specific error messages
2. Verify all environment variables are set correctly
3. Ensure DNS records are properly configured
4. Check EC2 security group rules
5. Review Keycloak client configuration

## Next Steps

After successful deployment:
- Set up monitoring and alerting
- Configure backup automation
- Implement CI/CD pipeline
- Add custom domain email (if needed)
- Configure rate limiting (already in nginx)
- Set up log aggregation

---

**Production URL**: https://mrelectron.xyz
**API URL**: https://api.mrelectron.xyz
**Auth URL**: https://auth.mrelectron.xyz

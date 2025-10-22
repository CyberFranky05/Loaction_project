# Quick Deployment Guide - mrelectron.xyz

## Your Configuration

- **Domain**: mrelectron.xyz
- **EC2 Public IP**: 13.200.149.67
- **SSL Certificate**: Will be generated automatically via Let's Encrypt (FREE!)

## Architecture

All services run on a single domain with path-based routing:
- **https://mrelectron.xyz** → Frontend (SvelteKit)
- **https://mrelectron.xyz/api/** → Backend API (NestJS)
- **https://mrelectron.xyz/auth/** → Keycloak Authentication

## Step 1: DNS Configuration (IMPORTANT!)

Point your domain to your EC2 IP:

```
Type    Name    Value           TTL
A       @       13.200.149.67   300
A       www     13.200.149.67   300
```

**Verify DNS is working:**
```bash
nslookup mrelectron.xyz
# Should return: 13.200.149.67
```

⚠️ **Wait 5-10 minutes after DNS changes before proceeding!**

## Step 2: Connect to EC2

```bash
ssh -i your-key.pem ubuntu@13.200.149.67
```

## Step 3: Install Docker & Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again
exit
ssh -i your-key.pem ubuntu@13.200.149.67
```

## Step 4: Clone Repository

```bash
git clone <your-repo-url>
cd location_project
git checkout aws-ec2-deployment
```

## Step 5: Configure Environment

```bash
cp .env.production.example .env.production
nano .env.production
```

**Fill in these values:**

```env
# PostgreSQL Password (generate strong password)
POSTGRES_PASSWORD=your_secure_postgres_password_here

# Keycloak Admin Password (generate strong password)
KEYCLOAK_ADMIN_PASSWORD=your_secure_admin_password_here

# Keycloak Client Secret (generate random string)
KEYCLOAK_CLIENT_SECRET=generate_random_secret_here

# JWT Secret (generate random string)
JWT_SECRET=generate_random_jwt_secret_here

# Your email for SSL certificate notifications
SSL_EMAIL=your_email@example.com

# Your Supabase credentials
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Generate secure secrets:**
```bash
openssl rand -base64 32  # For POSTGRES_PASSWORD
openssl rand -base64 32  # For KEYCLOAK_ADMIN_PASSWORD
openssl rand -base64 32  # For KEYCLOAK_CLIENT_SECRET
openssl rand -base64 32  # For JWT_SECRET
```

Save with `Ctrl+X`, `Y`, `Enter`

## Step 6: Deploy!

```bash
chmod +x deploy-aws.sh
./deploy-aws.sh
```

Choose option **1** for first-time deployment.

The script will:
1. ✅ Generate FREE SSL certificate from Let's Encrypt
2. ✅ Start all services (Keycloak, Backend, Frontend, PostgreSQL, Nginx)
3. ✅ Configure everything automatically

## Step 7: Configure Keycloak

After deployment, access Keycloak admin:
- URL: **https://mrelectron.xyz/auth**
- Username: **admin**
- Password: (your KEYCLOAK_ADMIN_PASSWORD)

### Create Realm:
1. Click "Create Realm"
2. Name: `location-auth-realm`
3. Click "Create"

### Create Backend Client:
1. Go to **Clients** → **Create Client**
2. Client ID: `location-auth-backend`
3. Click "Next"
4. **Client authentication**: ON
5. **Authentication flow**: ✅ Standard flow, ✅ Direct access grants
6. Click "Save"
7. Go to **Credentials** tab → Copy the **Client Secret**
8. Update `.env.production` with this secret:
   ```bash
   nano .env.production
   # Update KEYCLOAK_CLIENT_SECRET with the copied value
   ```
9. Go to **Service account roles** tab
10. Click "Assign role" → Filter by: `realm-management`
11. Select: `manage-users`, `view-users`, `view-clients`
12. Click "Assign"

### Create Frontend Client:
1. Go to **Clients** → **Create Client**
2. Client ID: `location-auth-frontend`
3. Click "Next"
4. **Client authentication**: OFF (public client)
5. **Authentication flow**: ✅ Standard flow, ✅ Direct access grants
6. **Valid redirect URIs**: `https://mrelectron.xyz/*`
7. **Web origins**: `https://mrelectron.xyz`
8. Click "Save"

### Restart Backend:
```bash
docker-compose -f docker-compose.prod.yml restart backend
```

## Step 8: Test Your Application!

1. **Frontend**: https://mrelectron.xyz
2. **API Health**: https://mrelectron.xyz/api/v1/health
3. **Keycloak**: https://mrelectron.xyz/auth

### Test Signup:
- Go to: https://mrelectron.xyz/signup
- Create an account
- Check it works!

### Test Signin:
- Go to: https://mrelectron.xyz/signin
- Login with your account
- Should see dashboard

## Useful Commands

### View Logs:
```bash
docker-compose -f docker-compose.prod.yml logs -f
docker-compose -f docker-compose.prod.yml logs -f backend
```

### Check Status:
```bash
docker-compose -f docker-compose.prod.yml ps
```

### Restart Service:
```bash
docker-compose -f docker-compose.prod.yml restart backend
docker-compose -f docker-compose.prod.yml restart frontend
```

### Update Application:
```bash
git pull origin aws-ec2-deployment
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

## SSL Certificate Auto-Renewal

Certificates auto-renew! Set up cron job:

```bash
cat > ~/renew-certs.sh << 'EOF'
#!/bin/bash
cd ~/location_project
docker-compose -f docker-compose.prod.yml run --rm certbot renew
docker-compose -f docker-compose.prod.yml restart nginx
EOF

chmod +x ~/renew-certs.sh
(crontab -l 2>/dev/null; echo "0 3 * * * ~/renew-certs.sh >> ~/certbot-renewal.log 2>&1") | crontab -
```

## Troubleshooting

### SSL Certificate Failed:
- Check DNS points to 13.200.149.67
- Verify ports 80 and 443 are open in EC2 Security Group
- Wait 10 minutes and try again

### Services Not Starting:
```bash
docker-compose -f docker-compose.prod.yml logs <service-name>
```

### Can't Access Website:
- Check EC2 Security Group allows ports 80 and 443
- Verify DNS propagation with `nslookup mrelectron.xyz`

## Security Checklist

```bash
# Enable firewall
sudo ufw enable
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
```

## Backup Database

```bash
docker exec location-auth-postgres pg_dump -U keycloak keycloak > backup-$(date +%Y%m%d).sql
```

---

**Your Site**: https://mrelectron.xyz  
**Your EC2**: 13.200.149.67  
**Support**: See AWS_EC2_DEPLOYMENT.md for detailed info

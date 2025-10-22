# Location-Based Authentication System - AWS EC2 Production

This branch is configured for production deployment on AWS EC2 with SSL certificates for **mrelectron.xyz**.

## 🚀 Quick Start

### Prerequisites
- AWS EC2 instance (Ubuntu 22.04, t3.medium or larger)
- Docker and Docker Compose installed
- DNS records configured for your domain
- Supabase account with database setup

### Deployment Steps

1. **Clone the repository on your EC2 instance:**
   ```bash
   git clone <your-repo-url>
   cd location_project
   git checkout aws-ec2-deployment
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.production.example .env.production
   nano .env.production
   ```
   Fill in all required values (see `.env.production.example` for details).

3. **Run deployment script:**
   ```bash
   chmod +x deploy-aws.sh
   ./deploy-aws.sh
   ```

4. **Follow the prompts** and configure Keycloak manually when instructed.

## 📚 Documentation

- **[AWS_EC2_DEPLOYMENT.md](./AWS_EC2_DEPLOYMENT.md)** - Complete deployment guide with detailed steps
- **[docker-compose.prod.yml](./docker-compose.prod.yml)** - Production Docker Compose configuration
- **[nginx/nginx.conf](./nginx/nginx.conf)** - Nginx reverse proxy with SSL configuration

## 🌐 Domain Structure

- **https://mrelectron.xyz** - Frontend application
- **https://api.mrelectron.xyz** - Backend API
- **https://auth.mrelectron.xyz** - Keycloak authentication server

## 🔧 Services

- **Frontend**: SvelteKit application (Port 3000)
- **Backend**: NestJS API (Port 3000 internal)
- **Keycloak**: Authentication server (Port 8080 internal)
- **PostgreSQL**: Keycloak database
- **Nginx**: Reverse proxy with SSL termination (Ports 80, 443)
- **Certbot**: Automatic SSL certificate management

## 🔐 Security Features

- SSL/TLS encryption for all domains
- Rate limiting on API endpoints
- Security headers (XSS, Frame options, etc.)
- Gzip compression
- HTTP to HTTPS redirect
- Let's Encrypt SSL certificates with auto-renewal

## 📊 Monitoring

### Check service status
```bash
docker-compose -f docker-compose.prod.yml ps
```

### View logs
```bash
docker-compose -f docker-compose.prod.yml logs -f
```

### Check resource usage
```bash
docker stats
```

## 🔄 Update Deployment

```bash
git pull origin aws-ec2-deployment
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

Or use the deployment script:
```bash
./deploy-aws.sh
# Select option 2 for update
```

## 🛠️ Maintenance

### SSL Certificate Renewal
Certificates auto-renew via cron job. Manual renewal:
```bash
docker-compose -f docker-compose.prod.yml run --rm certbot renew
docker-compose -f docker-compose.prod.yml restart nginx
```

### Backup Keycloak Database
```bash
docker exec location-auth-postgres pg_dump -U keycloak keycloak > backup-$(date +%Y%m%d).sql
```

### Clean Docker Resources
```bash
docker system prune -a
```

## 🐛 Troubleshooting

### Services not starting
```bash
docker-compose -f docker-compose.prod.yml logs <service-name>
```

### SSL certificate issues
- Verify DNS records point to your EC2 IP
- Ensure ports 80 and 443 are open in security group
- Check certbot logs: `docker-compose -f docker-compose.prod.yml logs certbot`

### CORS errors
- Update `CORS_ORIGIN` in `.env.production`
- Restart backend: `docker-compose -f docker-compose.prod.yml restart backend`

## 📝 Environment Variables

Required variables in `.env.production`:

```env
# Database
POSTGRES_PASSWORD=<secure-password>

# Keycloak
KEYCLOAK_ADMIN_PASSWORD=<admin-password>
KEYCLOAK_CLIENT_SECRET=<client-secret>

# Backend
JWT_SECRET=<jwt-secret>

# SSL
SSL_EMAIL=<your-email>

# Supabase
SUPABASE_URL=<supabase-url>
SUPABASE_SERVICE_ROLE_KEY=<service-key>
SUPABASE_ANON_KEY=<anon-key>
```

## 🎯 Architecture

```
Internet
    ↓
EC2 Security Group (80, 443)
    ↓
Nginx (SSL Termination)
    ├── mrelectron.xyz → Frontend (SvelteKit)
    ├── api.mrelectron.xyz → Backend (NestJS)
    └── auth.mrelectron.xyz → Keycloak
         ↓
    PostgreSQL (Keycloak DB)
         ↓
    Supabase (User Data)
```

## 📞 Support

For detailed instructions, see [AWS_EC2_DEPLOYMENT.md](./AWS_EC2_DEPLOYMENT.md).

---

**Branch**: `aws-ec2-deployment`  
**Domain**: mrelectron.xyz  
**Environment**: Production

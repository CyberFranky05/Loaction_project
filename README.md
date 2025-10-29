# Location-Based Authentication System - Production Deployment

This is a complete location-based authentication system with sign-in attempt tracking.

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose installed
- A domain name (for SSL/HTTPS)
- Port 80 and 443 open

### 1. Clone the Repository

```bash
git clone https://github.com/CyberFranky05/Loaction_project.git
cd Loaction_project
git checkout production
```

### 2. Configure Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and fill in your values:

```bash
# Domain Configuration
DOMAIN=yourdomain.com
DOMAIN_WWW=www.yourdomain.com

# Port Configuration (defaults shown, change if needed)
BACKEND_PORT=3000
FRONTEND_PORT=3000
KEYCLOAK_PORT=8080
POSTGRES_PORT=5432
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

# SSL Configuration
SSL_EMAIL=your@email.com

# PostgreSQL (for Keycloak)
POSTGRES_PASSWORD=your_strong_postgres_password

# Keycloak Admin
KEYCLOAK_ADMIN_PASSWORD=your_admin_password

# Backend Secrets
KEYCLOAK_CLIENT_SECRET=secret123
JWT_SECRET=your_jwt_secret

# CORS Origin (should match your domain with https://)
CORS_ORIGIN=https://yourdomain.com

# Supabase (Create free account at https://supabase.com)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
SUPABASE_ANON_KEY=your_anon_key
```

**Note:** All domain references and ports are now centralized in the `.env` file. This makes it easy to change domains or ports without editing multiple configuration files.

### 3. Setup Supabase Database

1. Create a free account at [supabase.com](https://supabase.com)
2. Create a new project
3. Run this SQL in Supabase SQL Editor:

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  keycloak_id TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create signin_attempts table
CREATE TABLE IF NOT EXISTS signin_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  ip_address TEXT,
  country TEXT,
  city TEXT,
  region TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  timezone TEXT,
  isp TEXT,
  user_agent TEXT,
  browser TEXT,
  device TEXT,
  os TEXT,
  success BOOLEAN NOT NULL,
  failure_reason TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_signin_attempts_user_id ON signin_attempts(user_id);
CREATE INDEX idx_signin_attempts_email ON signin_attempts(email);
CREATE INDEX idx_signin_attempts_timestamp ON signin_attempts(timestamp DESC);
```

4. Get your credentials from Settings → API

### 4. Configure Domain DNS

Point your domain to your server's IP:

```
A Record: yourdomain.com → YOUR_SERVER_IP
A Record: www.yourdomain.com → YOUR_SERVER_IP
```

### 5. Generate Nginx Configuration (Optional)

If you want to use the template approach for nginx configuration:

```bash
# Generate nginx.conf from template with your domain
bash scripts/generate-nginx-conf.sh
```

This will create `nginx/nginx.conf` using your `.env` variables. Otherwise, the existing `nginx.conf` will be used as-is.

### 6. Start the Application

```bash
# Start all services
docker-compose -f docker-compose.prod.yml up -d

# Check if all services are running
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### 7. Setup SSL Certificates

Once your domain DNS is configured:

```bash
# Stop nginx temporarily
docker-compose -f docker-compose.prod.yml stop nginx

# Get SSL certificate (uses DOMAIN and DOMAIN_WWW from .env)
docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
  --standalone \
  --email your@email.com \
  --agree-tos \
  --no-eff-email
```

# Start nginx again
docker-compose -f docker-compose.prod.yml start nginx
```

### 7. Verify Keycloak Realm Import

The Keycloak realm (`location-auth-realm`) is **automatically imported** on first startup with:
- ✅ Pre-configured clients: `location-auth-backend` and `location-auth-frontend`
- ✅ Default roles: `user` and `admin`
- ✅ Client secret: `secret123` (can be changed later)

Access Keycloak admin console at: `https://yourdomain.com/auth/admin`
- Username: `admin`
- Password: (from your .env `KEYCLOAK_ADMIN_PASSWORD`)

**No manual realm configuration needed!** The realm is imported automatically from `keycloak/realm-import.json`.

## 📦 What's Included

- **Frontend**: SvelteKit application (port 3000)
- **Backend**: NestJS API (port 3000)
- **Keycloak**: Authentication server (port 8080)
- **PostgreSQL**: Database for Keycloak (port 5432)
- **Nginx**: Reverse proxy with SSL (ports 80, 443)
- **Certbot**: SSL certificate management

## 🔧 Service URLs

After deployment, your services will be available at:

- **Frontend**: https://yourdomain.com
- **Backend API**: https://yourdomain.com/api/v1
- **Keycloak**: https://yourdomain.com/auth

## 🛠️ Maintenance

### View Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f frontend
```

### Restart Services
```bash
# Restart all
docker-compose -f docker-compose.prod.yml restart

# Restart specific service
docker-compose -f docker-compose.prod.yml restart backend
```

### Update Application
```bash
# Pull latest changes
git pull origin production

# Rebuild and restart
docker-compose -f docker-compose.prod.yml up -d --build
```

### Renew SSL Certificate
```bash
docker-compose -f docker-compose.prod.yml run --rm certbot renew
docker-compose -f docker-compose.prod.yml restart nginx
```

## 🔒 Security Notes

1. **Change all default passwords** in `.env`
2. **Keep secrets safe** - never commit `.env` to git
3. **Regular backups** of PostgreSQL and Supabase
4. **Monitor logs** for suspicious activity
5. **Update regularly** - keep Docker images updated

## 🐛 Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs

# Restart all services
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

### SSL Certificate issues
```bash
# Make sure port 80 is accessible
# Check domain DNS is pointing to your server
# Try standalone mode for certbot
```

### Can't access Keycloak admin
```bash
# Check Keycloak is running
docker-compose -f docker-compose.prod.yml logs keycloak

# Verify realm import
docker exec location-auth-keycloak ls /opt/keycloak/data/import/
```

## 📝 Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `DOMAIN` | Your primary domain name | `myapp.com` |
| `DOMAIN_WWW` | WWW subdomain | `www.myapp.com` |
| `BACKEND_PORT` | Backend service port | `3000` |
| `FRONTEND_PORT` | Frontend service port | `3000` |
| `KEYCLOAK_PORT` | Keycloak service port | `8080` |
| `POSTGRES_PORT` | PostgreSQL port | `5432` |
| `NGINX_HTTP_PORT` | Nginx HTTP port | `80` |
| `NGINX_HTTPS_PORT` | Nginx HTTPS port | `443` |
| `SSL_EMAIL` | Email for SSL certificates | `admin@myapp.com` |
| `CORS_ORIGIN` | CORS allowed origin | `https://myapp.com` |
| `POSTGRES_PASSWORD` | PostgreSQL password | `strongpassword123` |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password | `admin123` |
| `KEYCLOAK_CLIENT_SECRET` | Backend client secret | `secret123` |
| `JWT_SECRET` | JWT signing secret | `jwt_secret_key` |
| `SUPABASE_URL` | Supabase project URL | `https://xxx.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key | `eyJhbG...` |
| `SUPABASE_ANON_KEY` | Anonymous key | `eyJhbG...` |

## 📞 Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/CyberFranky05/Loaction_project/issues)
- Email: chaudharymahendra@gmail.com

## 📄 License

MIT License - feel free to use for your projects!

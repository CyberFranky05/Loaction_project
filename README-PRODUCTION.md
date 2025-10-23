# 🚀 Location-Based Authentication System - Production Branch

This branch contains a **ready-to-deploy** production package with pre-configured Keycloak realm and comprehensive documentation.

## ✨ What's Included

- **Pre-configured Keycloak Realm** - Auto-imports on first startup
- **Production Docker Compose** - All services configured for production
- **Comprehensive Documentation** - Step-by-step deployment guide
- **SSL/HTTPS Setup** - Let's Encrypt certificates included
- **Environment Templates** - Easy configuration with `.env.example`

## 🎯 Quick Deploy (5 Minutes)

```bash
# 1. Clone and checkout
git clone https://github.com/CyberFranky05/Loaction_project.git
cd Loaction_project
git checkout production

# 2. Configure environment
cp .env.example .env
# Edit .env with your values

# 3. Setup Supabase (free tier)
# - Create account at https://supabase.com
# - Create new project
# - Run the SQL from DEPLOYMENT.md
# - Copy credentials to .env

# 4. Deploy
docker-compose -f docker-compose.prod.yml up -d

# 5. Setup SSL (after DNS propagation)
docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
  --standalone -d yourdomain.com -d www.yourdomain.com
```

## 📚 Full Documentation

See **[DEPLOYMENT.md](./DEPLOYMENT.md)** for complete deployment guide including:

- Prerequisites and system requirements
- Detailed environment configuration
- Supabase setup with SQL schema
- DNS configuration
- SSL certificate setup
- Keycloak admin access
- Troubleshooting guide
- Maintenance commands

## 🏗️ Architecture

```
┌─────────────┐
│   Nginx     │ ← SSL/HTTPS, Reverse Proxy
│   :80/443   │
└──────┬──────┘
       │
       ├─────────────┐
       │             │
┌──────▼──────┐ ┌───▼───────┐
│  Frontend   │ │  Backend  │
│ (SvelteKit) │ │ (NestJS)  │
└──────┬──────┘ └───┬───────┘
       │            │
       │       ┌────▼────────┐
       │       │  Keycloak   │
       │       │  (Auth)     │
       │       └────┬────────┘
       │            │
       │       ┌────▼────────┐
       │       │ PostgreSQL  │
       │       │ (Keycloak)  │
       │       └─────────────┘
       │
  ┌────▼─────────┐
  │   Supabase   │
  │  (User Data) │
  └──────────────┘
```

## 🔑 Key Features

### Location-Based Sign-In Tracking
- Tracks user sign-in attempts with IP geolocation
- Records timestamp, location, and device info
- Supabase backend for secure data storage

### Pre-Configured Authentication
- Keycloak realm auto-imports on startup
- Two clients ready: backend (confidential) and frontend (public)
- Default roles configured
- No manual Keycloak setup required

### Production-Ready
- Docker Compose orchestration
- Health checks for all services
- SSL/HTTPS support
- Proper restart policies
- Volume persistence

## 🛠️ Tech Stack

- **Frontend**: SvelteKit + TypeScript
- **Backend**: NestJS + TypeScript
- **Authentication**: Keycloak 23.0.7
- **Database**: PostgreSQL 16 (Keycloak) + Supabase (App Data)
- **Proxy**: Nginx
- **SSL**: Let's Encrypt (Certbot)

## 📋 Environment Variables

Required variables (see `.env.example`):

| Variable | Description | Default/Example |
|----------|-------------|-----------------|
| `POSTGRES_PASSWORD` | PostgreSQL password for Keycloak | (generate strong) |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin console password | (generate strong) |
| `KEYCLOAK_CLIENT_SECRET` | Backend client secret | `secret123` (pre-configured) |
| `JWT_SECRET` | JWT signing secret | (generate strong) |
| `DOMAIN` | Your domain name | `yourdomain.com` |
| `SSL_EMAIL` | Email for Let's Encrypt | `you@email.com` |
| `SUPABASE_URL` | Supabase project URL | From Supabase dashboard |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service key | From Supabase dashboard |
| `SUPABASE_ANON_KEY` | Supabase anon key | From Supabase dashboard |

## 🔒 Security Notes

1. **Change Default Secrets**: Update `KEYCLOAK_CLIENT_SECRET` in Keycloak admin console after first deployment
2. **Strong Passwords**: Use strong, unique passwords for all services
3. **SSL Required**: Always use HTTPS in production
4. **Supabase RLS**: Enable Row Level Security policies in Supabase
5. **Firewall**: Only expose ports 80 and 443 to the internet

## 🐛 Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs -f

# Check service status
docker-compose -f docker-compose.prod.yml ps
```

### Keycloak realm not imported
```bash
# Check Keycloak logs
docker logs location-auth-keycloak

# Verify realm file is mounted
docker exec location-auth-keycloak ls -la /opt/keycloak/data/import/
```

### SSL certificate issues
```bash
# Ensure DNS is pointing to your server
nslookup yourdomain.com

# Check nginx config
docker exec location-auth-nginx nginx -t
```

See **[DEPLOYMENT.md](./DEPLOYMENT.md)** for complete troubleshooting guide.

## 📖 Additional Resources

- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Full deployment guide
- **[backend/API_GUIDE.md](./backend/API_GUIDE.md)** - API documentation
- **[.env.example](./.env.example)** - Environment variable template

## 🤝 Contributing

This is the production deployment branch. For development:

```bash
git checkout main  # or aws-ec2-deployment for current live deployment
```

## 📝 License

[Your License]

## 💬 Support

For issues or questions:
1. Check [DEPLOYMENT.md](./DEPLOYMENT.md) troubleshooting section
2. Review logs: `docker-compose -f docker-compose.prod.yml logs`
3. Open an issue on GitHub

---

**Happy Deploying! 🎉**

# Branch Comparison: Local vs AWS EC2

## Overview

This project has two main branches for different deployment environments:

### 1. `main` Branch - Local Development
For running the application on your local machine with Docker.

### 2. `aws-ec2-deployment` Branch - AWS Production
For deploying to AWS EC2 with SSL certificates on mrelectron.xyz.

## Key Differences

| Feature | Local Development (main) | AWS Production (aws-ec2-deployment) |
|---------|-------------------------|-----------------------------------|
| **Docker Compose File** | `docker-compose.yml` | `docker-compose.prod.yml` |
| **Keycloak Setup** | Dev mode with auto-config | Production with PostgreSQL |
| **SSL/HTTPS** | ❌ HTTP only | ✅ Let's Encrypt SSL |
| **Domains** | localhost | mrelectron.xyz subdomains |
| **Reverse Proxy** | ❌ Direct access | ✅ Nginx |
| **Database** | Embedded H2 (Keycloak) | PostgreSQL (Keycloak) |
| **Environment File** | `.env` | `.env.production` |
| **Auto-restart** | ❌ No | ✅ unless-stopped |

## File Structure Comparison

### Main Branch (Local Development)
```
├── docker-compose.yml                    # Local development compose
├── .env                                  # Local environment variables
├── LOCAL_DEVELOPMENT.md                  # Local setup guide
├── keycloak/
│   ├── Dockerfile.dev                    # Dev Keycloak with auto-config
│   └── configure-keycloak.sh            # Auto-configuration script
├── backend/
│   └── Dockerfile.dev                    # Dev backend
└── frontend/
    └── Dockerfile.dev                    # Dev frontend
```

### AWS EC2 Branch (Production)
```
├── docker-compose.prod.yml               # Production compose
├── .env.production.example               # Production env template
├── AWS_EC2_DEPLOYMENT.md                # AWS deployment guide
├── README-AWS.md                        # AWS branch README
├── deploy-aws.sh                        # Deployment automation script
├── nginx/
│   └── nginx.conf                       # Reverse proxy config
├── keycloak/
│   ├── Dockerfile                       # Production Keycloak
│   └── configure-keycloak.sh           # Manual config reference
├── backend/
│   └── Dockerfile                       # Production backend
└── frontend/
    └── Dockerfile                       # Production frontend
```

## Environment Variables

### Local Development (.env)
```env
# Supabase
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
SUPABASE_ANON_KEY=...

# Keycloak
KEYCLOAK_CLIENT_SECRET=...

# CORS (local ports)
CORS_ORIGIN=http://localhost:3000,http://localhost:5173,http://localhost:5174
```

### AWS Production (.env.production)
```env
# All local vars PLUS:
POSTGRES_PASSWORD=...                    # Keycloak DB
KEYCLOAK_ADMIN_PASSWORD=...             # Admin password
JWT_SECRET=...                           # Backend JWT
SSL_EMAIL=...                            # Let's Encrypt

# CORS (production domains)
CORS_ORIGIN=https://mrelectron.xyz,https://app.mrelectron.xyz
```

## Access URLs

### Local Development
- Frontend: http://localhost:3000
- Backend API: http://localhost:3001/api/v1
- Keycloak: http://localhost:8080

### AWS Production
- Frontend: https://mrelectron.xyz or https://app.mrelectron.xyz
- Backend API: https://api.mrelectron.xyz/api/v1
- Keycloak: https://auth.mrelectron.xyz

## Deployment Commands

### Local Development
```bash
# Switch to main branch
git checkout main

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### AWS Production
```bash
# Switch to AWS branch
git checkout aws-ec2-deployment

# Deploy (first time or update)
./deploy-aws.sh

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop services
docker-compose -f docker-compose.prod.yml down
```

## When to Use Each Branch

### Use `main` branch when:
- Developing locally on your machine
- Testing new features
- Debugging issues
- Learning how the system works
- Quick iteration and testing

### Use `aws-ec2-deployment` branch when:
- Deploying to production
- Hosting on AWS EC2
- Need SSL/HTTPS
- Serving real users
- Production-ready deployment

## Switching Between Branches

### From Local to AWS
```bash
# Commit any local changes
git add .
git commit -m "Your changes"

# Switch to AWS branch
git checkout aws-ec2-deployment

# If you need local changes in AWS branch
git merge main
```

### From AWS to Local
```bash
# Commit any changes
git add .
git commit -m "Your changes"

# Switch to main branch
git checkout main

# If you need AWS changes in main branch
git merge aws-ec2-deployment
```

## Important Notes

⚠️ **Never commit sensitive files:**
- `.env`
- `.env.production`
- SSL certificates
- Private keys

✅ **Safe to commit:**
- `.env.example`
- `.env.production.example`
- Configuration templates
- Documentation

## Quick Reference

| Task | Main Branch | AWS Branch |
|------|------------|------------|
| Start | `docker-compose up -d` | `./deploy-aws.sh` or `docker-compose -f docker-compose.prod.yml up -d` |
| Stop | `docker-compose down` | `docker-compose -f docker-compose.prod.yml down` |
| Logs | `docker-compose logs -f` | `docker-compose -f docker-compose.prod.yml logs -f` |
| Rebuild | `docker-compose build` | `docker-compose -f docker-compose.prod.yml build` |
| Status | `docker-compose ps` | `docker-compose -f docker-compose.prod.yml ps` |

---

**Current Branch**: Run `git branch` to see which branch you're on  
**Switch Branch**: `git checkout <branch-name>`

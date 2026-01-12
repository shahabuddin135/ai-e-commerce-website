# Railway Backend Setup Instructions

## Quick Deploy to Railway

### 1. Link Railway Project

```bash
# In the root directory
railway link

# Select your project: ai-e-commerce-website
```

### 2. Set Root Directory

Railway needs to know the backend is in a subdirectory:

```bash
# Set the root directory to backend
railway up --service backend

# Or in Railway dashboard:
# Settings → Root Directory → backend
```

### 3. Add Environment Variables

Run this command to set all required variables at once:

```bash
# Database URL (get from Neon after setup)
railway variables set DATABASE_URL="postgresql://..."

# Security secrets (generate strong random strings)
railway variables set JWT_SECRET_KEY="$(openssl rand -base64 32)"
railway variables set SESSION_SECRET="$(openssl rand -base64 32)"
railway variables set CSRF_SECRET="$(openssl rand -base64 32)"

# Application config
railway variables set PYTHON_ENV="staging"
railway variables set DEBUG="false"
railway variables set WORKERS="2"

# API config
railway variables set API_PREFIX="/api/v1"
railway variables set BACKEND_HOST="0.0.0.0"

# CORS (update with your Vercel URL after frontend setup)
railway variables set CORS_ORIGINS="https://staging.yourdomain.com,https://*.vercel.app"

# Rate limiting
railway variables set RATE_LIMIT_ENABLED="true"
```

### 4. Add Redis (Railway Add-on)

```bash
# Add Redis to your project
railway add

# Select: Redis
# Railway will auto-create REDIS_URL variable
```

### 5. Deploy

```bash
# Deploy the backend
railway up

# Or push via git (auto-deploys)
git push origin develop
```

### 6. Check Deployment

```bash
# View logs
railway logs

# Get deployment URL
railway status

# Test health endpoint
curl https://your-backend.railway.app/health
```

## Environment Variables Reference

Required variables for staging:

- `DATABASE_URL` - Neon Postgres connection (pooled)
- `REDIS_URL` - Auto-set by Railway Redis add-on
- `JWT_SECRET_KEY` - Strong random string (32+ chars)
- `SESSION_SECRET` - Strong random string (32+ chars)
- `CSRF_SECRET` - Strong random string (32+ chars)
- `PYTHON_ENV` - "staging"
- `DEBUG` - "false"
- `WORKERS` - "2"
- `API_PREFIX` - "/api/v1"
- `CORS_ORIGINS` - Your frontend URLs (comma-separated)

Optional but recommended:

- `SENTRY_DSN` - Backend error tracking
- `SENTRY_ENVIRONMENT` - "staging"
- `LOG_LEVEL` - "INFO"
- `LOG_FORMAT` - "json"

## Post-Deployment

1. **Run Migrations**:
```bash
# Connect to Railway and run migrations
railway run alembic upgrade head
```

2. **Verify Health**:
```bash
curl https://your-backend.railway.app/health
curl https://your-backend.railway.app/health/ready
```

3. **Check API Docs**:
```
https://your-backend.railway.app/docs
```

## Troubleshooting

**Build fails:**
- Check Railway logs: `railway logs`
- Verify UV installation in build command
- Ensure pyproject.toml is correct

**App won't start:**
- Check if PORT is correctly used
- Verify all required env vars are set
- Check logs for missing dependencies

**Health check fails:**
- Ensure /health endpoint exists
- Check database connection
- Verify Redis connection

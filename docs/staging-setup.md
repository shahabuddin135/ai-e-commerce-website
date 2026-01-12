# Staging Environment Setup Guide

> **Purpose**: Complete guide for setting up and managing the staging environment for the AI E-Commerce Platform.

**Last Updated**: January 12, 2026  
**Environment**: Staging  
**Audience**: DevOps, Backend & Frontend Developers

---

## 🎯 Overview

The staging environment serves as a production-like environment for testing before deployment to production. It mirrors production configurations while using separate resources and test data.

### Staging Environment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    STAGING ENVIRONMENT                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Frontend (Vercel)          Backend (Railway)               │
│  ├─ Next.js App            ├─ FastAPI App                   │
│  ├─ Preview URLs           ├─ Auto-deploy from develop      │
│  └─ staging.yourdomain.com └─ api-staging.yourdomain.com    │
│                                                              │
│  Database (Neon)           Cache (Redis)                    │
│  ├─ Staging Branch         ├─ Upstash/Railway               │
│  ├─ Connection Pooling     └─ Separate instance             │
│  └─ Point-in-time Recovery                                  │
│                                                              │
│  CMS (Sanity)              Payments (Lemon Squeezy)         │
│  ├─ Staging Dataset        ├─ Test Mode                     │
│  └─ staging-studio         └─ Test Products                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Platform Setup

### 1. Railway Backend Setup

#### Step 1: Create Railway Account
1. Go to [Railway](https://railway.app/)
2. Sign up with GitHub account
3. Verify email address

#### Step 2: Create New Project
```bash
# Using Railway CLI (optional)
npm install -g @railway/cli
railway login
railway init
```

Or via Web Dashboard:
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose your repository
4. Select `backend` directory as root

#### Step 3: Configure Build Settings
```yaml
# railway.json (create in backend directory)
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "uv pip install -e ."
  },
  "deploy": {
    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 100,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

#### Step 4: Environment Configuration

**Railway Environment Variables (Staging):**
```bash
# Application
PYTHON_ENV=staging
DEBUG=false
WORKERS=2

# API
API_PREFIX=/api/v1
BACKEND_HOST=0.0.0.0
BACKEND_PORT=$PORT  # Railway provides this

# Database (from Neon staging instance)
DATABASE_URL=${{Neon.DATABASE_URL}}  # Use Railway variable reference
DATABASE_POOL_SIZE=15
DATABASE_MAX_OVERFLOW=25

# Redis (from Railway add-on or Upstash)
REDIS_URL=${{Redis.REDIS_URL}}

# Security
JWT_SECRET_KEY=<generate-strong-staging-secret-32chars+>
SESSION_SECRET=<generate-strong-staging-secret-32chars+>
CSRF_SECRET=<generate-strong-staging-secret-32chars+>
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS (Vercel staging URL)
CORS_ORIGINS=https://staging.yourdomain.com,https://*.vercel.app

# Lemon Squeezy (TEST MODE)
LEMON_SQUEEZY_TEST_MODE=true
LEMON_SQUEEZY_API_KEY=<test-api-key>
LEMON_SQUEEZY_STORE_ID=<test-store-id>
LEMON_SQUEEZY_WEBHOOK_SECRET=<staging-webhook-secret>

# Sanity CMS
NEXT_PUBLIC_SANITY_PROJECT_ID=<your-project-id>
NEXT_PUBLIC_SANITY_DATASET=staging
SANITY_API_TOKEN=<staging-token>

# Email (SendGrid/SMTP)
EMAIL_FROM_ADDRESS=staging@yourdomain.com
SENDGRID_API_KEY=<staging-api-key>

# Sentry
SENTRY_DSN=<backend-sentry-dsn>
SENTRY_ENVIRONMENT=staging
SENTRY_TRACES_SAMPLE_RATE=1.0

# PostHog
POSTHOG_PERSONAL_API_KEY=<staging-key>

# Rate Limiting
RATE_LIMIT_ENABLED=true
```

#### Step 5: Add Database (Neon)
1. In Railway dashboard, click "New" → "Database" → "Add PostgreSQL"
2. Or connect external Neon instance:
   - Get connection string from Neon dashboard
   - Add as `DATABASE_URL` environment variable

#### Step 6: Add Redis
1. Click "New" → "Redis"
2. Railway will auto-generate `REDIS_URL`
3. Reference in app: `${{Redis.REDIS_URL}}`

#### Step 7: Deploy
```bash
# Railway auto-deploys on git push to develop branch
git push origin develop

# Or manual deploy via CLI
railway up
```

#### Step 8: Get Railway URLs
```bash
# Backend will be available at:
https://your-backend-staging.railway.app

# Add custom domain (optional):
# Railway Dashboard → Settings → Domains → Add Domain
# Example: api-staging.yourdomain.com
```

---

### 2. Vercel Frontend Setup

#### Step 1: Create Vercel Account
1. Go to [Vercel](https://vercel.com/)
2. Sign up with GitHub account

#### Step 2: Import Project
1. Click "Add New..." → "Project"
2. Import your GitHub repository
3. Select `frontend` directory as root
4. Framework Preset: **Next.js** (auto-detected)

#### Step 3: Configure Build Settings
```json
// vercel.json (optional, create in frontend directory)
{
  "buildCommand": "bun run build",
  "devCommand": "bun run dev",
  "installCommand": "bun install",
  "framework": "nextjs",
  "regions": ["iad1"],
  "functions": {
    "app/**": {
      "memory": 1024,
      "maxDuration": 10
    }
  }
}
```

#### Step 4: Environment Variables (Staging)

**Vercel Environment Variables (Select "Preview" environment):**
```bash
# Application
NODE_ENV=production  # Yes, production for preview builds
NEXT_PUBLIC_APP_NAME="AI E-Commerce Platform (Staging)"
NEXT_PUBLIC_APP_URL=https://staging.yourdomain.com

# Backend API
NEXT_PUBLIC_API_URL=https://your-backend-staging.railway.app
NEXT_PUBLIC_API_VERSION=v1

# NextAuth
NEXTAUTH_URL=https://staging.yourdomain.com
NEXTAUTH_SECRET=<generate-strong-staging-secret-32chars+>

# Sanity CMS
NEXT_PUBLIC_SANITY_PROJECT_ID=<your-project-id>
NEXT_PUBLIC_SANITY_DATASET=staging
NEXT_PUBLIC_SANITY_API_VERSION=2024-01-01
SANITY_API_TOKEN=<staging-read-token>
SANITY_PREVIEW_SECRET=<staging-preview-secret>

# Lemon Squeezy
NEXT_PUBLIC_LEMON_SQUEEZY_STORE_ID=<test-store-id>

# Analytics
NEXT_PUBLIC_POSTHOG_KEY=<staging-posthog-key>
NEXT_PUBLIC_POSTHOG_HOST=https://app.posthog.com

# Error Tracking
NEXT_PUBLIC_SENTRY_DSN=<frontend-sentry-dsn>
SENTRY_ENVIRONMENT=staging
SENTRY_AUTH_TOKEN=<sentry-auth-token>

# Feature Flags
FEATURE_OAUTH_LOGIN=true
FEATURE_EMAIL_VERIFICATION=true
FEATURE_ANALYTICS_ENABLED=true
FEATURE_MAINTENANCE_MODE=false
```

#### Step 5: Deploy Settings
1. **Production Branch**: `main` (leave as is)
2. **Preview Branch**: Configure `develop` for staging
   - Settings → Git → Deploy Hooks
   - Add deploy hook for `develop` branch

#### Step 6: Custom Domain (Optional)
1. Go to Settings → Domains
2. Add custom domain: `staging.yourdomain.com`
3. Configure DNS:
   ```
   Type: CNAME
   Name: staging
   Value: cname.vercel-dns.com
   ```
4. Wait for SSL certificate (automatic)

#### Step 7: Deploy
```bash
# Auto-deploys on git push to develop
git push origin develop

# Get preview URL from Vercel dashboard or GitHub PR comments
```

---

### 3. Neon Postgres Staging Setup

#### Step 1: Create Neon Account
1. Go to [Neon](https://neon.tech/)
2. Sign up with GitHub account

#### Step 2: Create Staging Branch/Database
```bash
# Option 1: Create separate project for staging
1. Click "New Project"
2. Name: "ai-ecommerce-staging"
3. Region: Choose closest to Railway region
4. Postgres Version: 15 or latest

# Option 2: Create branch from dev (recommended)
1. Go to existing project
2. Click "Branches"
3. Create branch from "main" → name it "staging"
```

#### Step 3: Configure Connection Pooling
```
✅ Enable connection pooling (PgBouncer)
   - Pooled connection for applications
   - Direct connection for migrations

Connection strings:
- Direct: postgresql://user:pass@host/db
- Pooled: postgresql://user:pass@host/db?pgbouncer=true
```

#### Step 4: Get Connection Strings
```bash
# From Neon Dashboard → Connection Details

# Direct connection (for Alembic migrations)
postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb

# Pooled connection (for application)
postgresql://user:password@ep-xxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require
```

#### Step 5: Configure Database Settings
- **Compute size**: 0.25 vCPU, 1 GB RAM (auto-scale to 1 vCPU)
- **Auto-suspend**: After 5 minutes of inactivity
- **Autoscaling**: Enabled
- **Backups**: Enabled (7-day retention)

#### Step 6: Add to Railway
1. Copy pooled connection string
2. In Railway → Backend Service → Variables
3. Add `DATABASE_URL` with pooled connection

---

### 4. Redis Staging Setup

#### Option 1: Railway Redis (Recommended)
```bash
# In Railway project
1. Click "New" → "Redis"
2. Railway auto-configures
3. Reference: ${{Redis.REDIS_URL}}
```

#### Option 2: Upstash Redis
```bash
1. Go to https://upstash.com/
2. Create account
3. Create Redis database
   - Name: ai-ecommerce-staging
   - Region: Choose closest to backend
   - Type: Regional (cheaper)
4. Copy connection string (Redis URL)
5. Add to Railway env vars
```

**Configuration:**
- **Max Memory**: 100 MB (sufficient for staging)
- **Eviction Policy**: allkeys-lru
- **TLS**: Enabled

---

### 5. Sanity CMS Staging Setup

#### Step 1: Create Staging Dataset
```bash
# In Sanity project directory
cd sanity-studio  # or wherever your studio is

# Create staging dataset
npx sanity dataset create staging

# Or via Sanity CLI
sanity dataset create staging --visibility public
```

#### Step 2: Configure Studio for Staging
```typescript
// sanity.config.ts
import {defineConfig} from 'sanity'

export default defineConfig({
  projectId: '<your-project-id>',
  dataset: process.env.SANITY_STUDIO_DATASET || 'staging',
  // ... rest of config
})
```

#### Step 3: Deploy Staging Studio
```bash
# Deploy with staging dataset
SANITY_STUDIO_DATASET=staging npx sanity deploy

# Access at: https://your-project.sanity.studio
# Or custom: https://staging-studio.yourdomain.com
```

#### Step 4: API Tokens
1. Go to Sanity dashboard → API → Tokens
2. Create token: "Staging Read Token" (Viewer role)
3. Add to Vercel & Railway env vars

---

### 6. Lemon Squeezy Staging Setup

#### Step 1: Enable Test Mode
1. Go to Lemon Squeezy Dashboard
2. Toggle "Test Mode" (top right)
3. All test mode data is separate from production

#### Step 2: Create Test Products
1. Products → New Product
2. Create staging versions of all products:
   - Basic Plan (Test) - $0.01/month
   - Pro Plan (Test) - $0.02/month
   - Enterprise Plan (Test) - $0.03/month

#### Step 3: Configure Webhooks
```
Webhook URL: https://your-backend-staging.railway.app/api/v1/webhooks/lemon-squeezy

Events to subscribe:
✅ order_created
✅ subscription_created
✅ subscription_updated
✅ subscription_cancelled
✅ subscription_payment_success
✅ subscription_payment_failed

Signing Secret: Copy and add to Railway env vars
```

#### Step 4: Get Test API Keys
1. Settings → API
2. Copy Test API Key
3. Add to Railway & Vercel env vars

#### Step 5: Test Cards
```
Test Card Numbers (Lemon Squeezy):
- Success: 4242 4242 4242 4242
- Decline: 4000 0000 0000 0002
- Exp: Any future date
- CVV: Any 3 digits
```

---

## 🔧 Deployment Process

### Initial Deployment

```bash
# 1. Prepare database
cd backend
source .venv/bin/activate  # or .venv\Scripts\activate on Windows

# 2. Update DATABASE_URL to staging
export DATABASE_URL="<neon-staging-connection>"

# 3. Run migrations
alembic upgrade head

# 4. Seed staging data (optional)
python scripts/seed_staging.py

# 5. Push to develop branch
git checkout develop
git add .
git commit -m "feat: initial staging setup"
git push origin develop

# 6. Railway and Vercel auto-deploy
# Check deployment status in dashboards
```

### Continuous Deployment

```bash
# Any push to develop triggers auto-deployment

# 1. Create feature branch
git checkout -b feature/new-feature develop

# 2. Make changes and test locally
bun dev  # frontend
uv run uvicorn app.main:app --reload  # backend

# 3. Commit and push
git add .
git commit -m "feat: new feature"
git push origin feature/new-feature

# 4. Create PR to develop
# GitHub → Pull Request → develop ← feature/new-feature

# 5. After PR merge, auto-deploys to staging
# Vercel: Creates preview deployment
# Railway: Deploys on merge to develop
```

---

## 🔍 Verification & Testing

### Health Checks

```bash
# Backend health check
curl https://your-backend-staging.railway.app/health
# Expected: {"status":"ok"}

# Detailed health check
curl https://your-backend-staging.railway.app/health/ready
# Expected: {"status":"healthy","database":"connected","redis":"connected"}

# Frontend
curl https://staging.yourdomain.com
# Expected: HTML response
```

### Database Connection Test

```bash
# From Railway backend logs
railway logs

# Look for successful connection:
INFO:     Database connected successfully
INFO:     Redis connected successfully
```

### API Endpoint Test

```bash
# Test API
curl https://your-backend-staging.railway.app/api/v1/docs

# Test auth endpoint
curl -X POST https://your-backend-staging.railway.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}'
```

---

## 📊 Monitoring Staging

### Railway Monitoring
- **Metrics**: CPU, Memory, Network usage
- **Logs**: Real-time application logs
- **Alerts**: Set up for deployment failures

### Vercel Monitoring
- **Analytics**: Page views, performance
- **Logs**: Function logs and errors
- **Alerts**: Build failures, high error rates

### Sentry (Error Tracking)
```bash
# Staging environment in Sentry
- Separate project or use environment filter
- Alert rules for critical errors
- Performance monitoring enabled
```

### PostHog (Analytics)
```bash
# Staging feature flags
- Test new features before production
- A/B test experiments
- User behavior tracking
```

---

## 🔐 Security Considerations

### Secrets Management
```bash
✅ Different secrets for staging vs production
✅ No production secrets in staging
✅ Railway/Vercel encrypted environment variables
✅ Rotate staging secrets monthly (vs 90 days in prod)
✅ Limit access to staging env vars (team only)
```

### Access Control
```bash
✅ Staging protected by basic auth (optional)
✅ Separate OAuth apps for staging
✅ Test mode for payment provider
✅ Limited database access (no production data)
✅ Staging data can be wiped/reset
```

### Data Protection
```bash
✅ NEVER use production data in staging
✅ Use synthetic/test data only
✅ Anonymize any copied data
✅ Regular staging database resets
✅ No real payment processing (test mode only)
```

---

## 📝 Staging URLs Reference

### Platform URLs
```
Frontend (Vercel):
- Auto: https://ai-ecommerce-git-develop.vercel.app
- Custom: https://staging.yourdomain.com

Backend (Railway):
- Auto: https://your-backend-staging.railway.app
- Custom: https://api-staging.yourdomain.com

Sanity Studio:
- https://your-project.sanity.studio?dataset=staging
- Custom: https://staging-studio.yourdomain.com

Database (Neon):
- Pooled: postgresql://...pooler.neon.tech/...
- Direct: postgresql://...neon.tech/...

Redis:
- Railway: redis://default:password@...railway.app:6379
- Upstash: redis://default:password@...upstash.io:6379
```

### Documentation
```
API Docs: https://your-backend-staging.railway.app/docs
Health Check: https://your-backend-staging.railway.app/health
Frontend: https://staging.yourdomain.com
```

---

## 🐛 Troubleshooting

### Common Issues

**Build Fails on Railway:**
```bash
# Check build logs
railway logs --deployment <deployment-id>

# Common fixes:
1. Verify python version in railway.json
2. Check uv installation
3. Verify requirements in pyproject.toml
4. Check environment variables
```

**Database Connection Fails:**
```bash
# Verify connection string
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL

# Check SSL mode (should be require)
# Verify IP not blocked by Neon
```

**CORS Errors:**
```bash
# Update CORS_ORIGINS in Railway
CORS_ORIGINS=https://staging.yourdomain.com,https://*.vercel.app

# Verify in logs
railway logs | grep CORS
```

**Environment Variables Not Loading:**
```bash
# Railway: Check variable reference syntax
${{Service.VARIABLE_NAME}}

# Vercel: Check environment selection (Preview vs Production)
# Redeploy after env var changes
```

---

## ✅ Staging Environment Checklist

### Pre-Deployment
- [ ] Railway project created and connected to GitHub
- [ ] Vercel project created and connected to GitHub
- [ ] Neon staging database created
- [ ] Redis instance provisioned
- [ ] Sanity staging dataset created
- [ ] Lemon Squeezy test mode configured
- [ ] All environment variables set
- [ ] Secrets generated and stored
- [ ] DNS records configured (if using custom domains)

### Post-Deployment
- [ ] Backend health check passing
- [ ] Frontend accessible
- [ ] Database migrations applied
- [ ] Redis connection working
- [ ] API documentation accessible
- [ ] Authentication flow working
- [ ] Payment webhooks configured
- [ ] Sanity content accessible
- [ ] Sentry receiving errors
- [ ] PostHog tracking events
- [ ] Email sending working (test mode)

### Ongoing Maintenance
- [ ] Monitor deployment success rate
- [ ] Review error logs weekly
- [ ] Update dependencies monthly
- [ ] Rotate secrets quarterly
- [ ] Reset staging data monthly
- [ ] Test disaster recovery quarterly

---

## 📞 Support & Escalation

### Platform Support
- **Railway**: https://railway.app/help
- **Vercel**: https://vercel.com/support
- **Neon**: https://neon.tech/docs/introduction
- **Upstash**: https://upstash.com/docs

### Internal Contacts
- DevOps Lead: [email]
- Backend Lead: [email]
- Frontend Lead: [email]
- On-Call: [escalation path]

---

**Last Review**: January 12, 2026  
**Next Review**: March 12, 2026  
**Owner**: DevOps Team

**Note**: Update this document when staging configuration changes.

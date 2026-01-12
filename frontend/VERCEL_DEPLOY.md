# Vercel Frontend Setup Instructions

## Quick Deploy to Vercel

### 1. Install Vercel CLI (Optional)

```bash
# Install Vercel CLI globally
npm install -g vercel

# Or use with npx
npx vercel
```

### 2. Link Vercel Project

```bash
# From project root
cd frontend

# Login to Vercel
vercel login

# Link project (or create new)
vercel link

# Follow prompts:
# - Set up and deploy? Yes
# - Which scope? Your account/team
# - Link to existing project? No (create new)
# - Project name? ai-ecommerce-frontend
# - Directory? ./
```

### 3. Configure Project Settings

**Via Vercel Dashboard (Recommended):**

1. Go to [vercel.com](https://vercel.com)
2. Select your project
3. Settings → General:
   - **Framework Preset**: Next.js
   - **Root Directory**: `frontend`
   - **Build Command**: `bun run build`
   - **Install Command**: `bun install`
   - **Output Directory**: `.next`
   - **Node Version**: 20.x

### 4. Add Environment Variables

**Via Dashboard:**

Go to Settings → Environment Variables → Add

**For Preview/Staging Environment:**

```bash
# Application
NODE_ENV=production
NEXT_PUBLIC_APP_NAME="AI E-Commerce (Staging)"
NEXT_PUBLIC_APP_URL=https://staging.yourdomain.com

# Backend API (update after Railway deployment)
NEXT_PUBLIC_API_URL=https://your-backend.railway.app
NEXT_PUBLIC_API_VERSION=v1

# NextAuth
NEXTAUTH_URL=https://staging.yourdomain.com
NEXTAUTH_SECRET=<generate-strong-secret-32chars>

# Feature Flags
FEATURE_OAUTH_LOGIN=true
FEATURE_EMAIL_VERIFICATION=true
FEATURE_ANALYTICS_ENABLED=true
FEATURE_MAINTENANCE_MODE=false
```

**Via CLI:**

```bash
# Set environment variables for preview
vercel env add NEXT_PUBLIC_APP_URL preview
# Enter: https://staging.yourdomain.com

vercel env add NEXT_PUBLIC_API_URL preview
# Enter: https://your-backend.railway.app

vercel env add NEXTAUTH_SECRET preview
# Enter: <generate strong secret>

# Add more variables as needed...
```

### 5. Configure Git Integration

**Dashboard Method:**

1. Settings → Git
2. Connect your GitHub repository
3. Set **Production Branch**: `main`
4. Set **Preview Branch**: `develop` (for staging)
5. Enable **Automatic Deployments**

**Branch Settings:**

```
✅ main → Production
✅ develop → Preview (Staging)
✅ feature/* → Preview (Feature branches)
```

### 6. Configure Custom Domain (Optional)

**For Staging:**

1. Settings → Domains
2. Add Domain: `staging.yourdomain.com`
3. Configure DNS:
   ```
   Type: CNAME
   Name: staging
   Value: cname.vercel-dns.com
   TTL: 3600
   ```
4. Wait for SSL (automatic)

### 7. Deploy

**Method 1: Git Push (Recommended)**

```bash
# Commit and push to develop
git add .
git commit -m "feat: configure vercel deployment"
git push origin develop

# Vercel auto-deploys
```

**Method 2: Manual Deploy**

```bash
# Deploy to preview
vercel

# Deploy to production
vercel --prod
```

### 8. Verify Deployment

```bash
# Check deployment status
vercel ls

# View logs
vercel logs <deployment-url>

# Open in browser
vercel open
```

## Environment Variables - Complete List

### Required for Staging

```bash
# App Configuration
NODE_ENV=production
NEXT_PUBLIC_APP_NAME="AI E-Commerce (Staging)"
NEXT_PUBLIC_APP_URL=https://staging.yourdomain.com

# API Configuration
NEXT_PUBLIC_API_URL=https://your-backend.railway.app
NEXT_PUBLIC_API_VERSION=v1

# Authentication
NEXTAUTH_URL=https://staging.yourdomain.com
NEXTAUTH_SECRET=<strong-random-32chars>

# Feature Flags
FEATURE_OAUTH_LOGIN=true
FEATURE_EMAIL_VERIFICATION=true
FEATURE_ANALYTICS_ENABLED=true
FEATURE_MAINTENANCE_MODE=false
```

### Optional but Recommended

```bash
# Sanity CMS (when ready)
NEXT_PUBLIC_SANITY_PROJECT_ID=<project-id>
NEXT_PUBLIC_SANITY_DATASET=staging
NEXT_PUBLIC_SANITY_API_VERSION=2024-01-01
SANITY_API_TOKEN=<read-token>

# Analytics (when ready)
NEXT_PUBLIC_POSTHOG_KEY=<staging-key>
NEXT_PUBLIC_POSTHOG_HOST=https://app.posthog.com

# Error Tracking (when ready)
NEXT_PUBLIC_SENTRY_DSN=<frontend-dsn>
SENTRY_ENVIRONMENT=staging
SENTRY_AUTH_TOKEN=<auth-token>

# Payment (when ready)
NEXT_PUBLIC_LEMON_SQUEEZY_STORE_ID=<test-store-id>
```

## Post-Deployment Checklist

- [ ] Frontend accessible at Vercel URL
- [ ] Custom domain configured (if applicable)
- [ ] All environment variables set
- [ ] API calls working to Railway backend
- [ ] No console errors in browser
- [ ] Pages loading correctly
- [ ] Images optimized and loading
- [ ] SEO meta tags present
- [ ] SSL certificate active

## Update Backend CORS

After frontend is deployed, update Railway backend CORS:

```bash
# Get your Vercel URL (e.g., https://ai-ecommerce-git-develop.vercel.app)
# Add to Railway environment variables

railway variables set CORS_ORIGINS="https://your-vercel-url.vercel.app,https://staging.yourdomain.com"
```

## Troubleshooting

**Build Fails:**
- Check build logs in Vercel dashboard
- Verify bun.lockb is committed
- Check for TypeScript errors: `bun run build` locally

**Environment Variables Not Working:**
- Ensure NEXT_PUBLIC_ prefix for client-side vars
- Redeploy after adding env vars
- Check correct environment (Preview vs Production)

**API Calls Failing:**
- Verify NEXT_PUBLIC_API_URL is correct
- Check CORS settings in Railway backend
- Verify backend is running: `curl <backend-url>/health`

**Custom Domain Issues:**
- Wait up to 48 hours for DNS propagation
- Verify CNAME record is correct
- Check Vercel domain settings

## Monitoring

**Vercel Analytics:**
- Dashboard → Analytics
- View page performance, visitor data

**Deployment Logs:**
- Dashboard → Deployments → Select deployment → Logs

**Function Logs:**
- Runtime Logs tab for server-side errors

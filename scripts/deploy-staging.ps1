# AI E-Commerce Platform - Staging Deployment Script (Windows)
# This script helps deploy the complete staging environment on Windows

Write-Host "🚀 AI E-Commerce Platform - Staging Deployment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Railway CLI is installed
try {
    railway --version | Out-Null
    Write-Host "✅ Railway CLI found" -ForegroundColor Green
} catch {
    Write-Host "❌ Railway CLI not found" -ForegroundColor Red
    Write-Host "Install it with: npm install -g @railway/cli"
    exit 1
}

# Check if Vercel CLI is installed (optional)
try {
    vercel --version | Out-Null
    Write-Host "✅ Vercel CLI found" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Vercel CLI not found (optional)" -ForegroundColor Yellow
    Write-Host "You can install it with: npm install -g vercel"
}

Write-Host ""

# Step 1: Neon Setup
Write-Host "📊 Step 1: Neon Postgres Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Go to https://neon.tech and create account"
Write-Host "2. Create new project: 'ai-ecommerce-staging'"
Write-Host "3. Region: Choose closest to your Railway region"
Write-Host "4. Get BOTH connection strings:"
Write-Host "   - Pooled (for Railway app)"
Write-Host "   - Direct (for migrations)"
Write-Host ""
$neon_ready = Read-Host "Have you completed Neon setup? (y/n)"

if ($neon_ready -ne "y") {
    Write-Host "📖 Please follow: docs/neon-setup-guide.md" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
$DATABASE_URL_POOLED = Read-Host "Enter your Neon POOLED connection string"
Write-Host ""
$DATABASE_URL_DIRECT = Read-Host "Enter your Neon DIRECT connection string"

# Step 2: Railway Backend Setup
Write-Host ""
Write-Host "🚂 Step 2: Railway Backend Deployment" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if railway project is linked
try {
    railway status | Out-Null
} catch {
    Write-Host "Railway project not linked. Linking now..."
    railway link
}

Write-Host "Setting Railway environment variables..."

# Generate secrets (using PowerShell equivalent)
$JWT_SECRET = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
$SESSION_SECRET = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
$CSRF_SECRET = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))

# Set environment variables
railway variables set DATABASE_URL=$DATABASE_URL_POOLED
railway variables set JWT_SECRET_KEY=$JWT_SECRET
railway variables set SESSION_SECRET=$SESSION_SECRET
railway variables set CSRF_SECRET=$CSRF_SECRET
railway variables set PYTHON_ENV=staging
railway variables set DEBUG=false
railway variables set WORKERS=2
railway variables set API_PREFIX=/api/v1
railway variables set BACKEND_HOST=0.0.0.0
railway variables set RATE_LIMIT_ENABLED=true

Write-Host "✅ Environment variables set" -ForegroundColor Green

# Add Redis
Write-Host ""
$add_redis = Read-Host "Would you like to add Redis? (y/n)"

if ($add_redis -eq "y") {
    Write-Host "Adding Redis..."
    railway add redis
    Write-Host "✅ Redis added" -ForegroundColor Green
}

# Deploy backend
Write-Host ""
Write-Host "Deploying backend to Railway..."
Set-Location backend
railway up
Set-Location ..

Write-Host "✅ Backend deployed" -ForegroundColor Green

# Get Railway URL
$RAILWAY_URL = (railway status --json | ConvertFrom-Json).url
Write-Host ""
Write-Host "Backend URL: $RAILWAY_URL"

# Step 3: Run Migrations
Write-Host ""
Write-Host "🗄️  Step 3: Database Migrations" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

Set-Location backend

# Check if virtual environment exists
if (-not (Test-Path ".venv")) {
    Write-Host "Creating virtual environment..."
    uv venv
}

# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Set direct connection for migrations
$env:DATABASE_URL = $DATABASE_URL_DIRECT

Write-Host "Generating initial migration..."
alembic revision --autogenerate -m "Initial schema setup"

Write-Host "Applying migrations..."
alembic upgrade head

Write-Host "✅ Migrations applied" -ForegroundColor Green

Set-Location ..

# Step 4: Vercel Frontend Setup
Write-Host ""
Write-Host "▲ Step 4: Vercel Frontend Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

try {
    vercel --version | Out-Null
    
    Write-Host "Login to Vercel..."
    vercel login

    Set-Location frontend

    Write-Host "Linking Vercel project..."
    vercel link

    Write-Host "Deploying to Vercel..."
    vercel

    Set-Location ..

    Write-Host "✅ Frontend deployed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Vercel CLI not installed" -ForegroundColor Yellow
    Write-Host "Please deploy frontend manually:"
    Write-Host "1. Go to https://vercel.com"
    Write-Host "2. Import your GitHub repository"
    Write-Host "3. Set root directory to: frontend"
    Write-Host "4. Add environment variables from: frontend/VERCEL_DEPLOY.md"
    Write-Host "5. Set NEXT_PUBLIC_API_URL=$RAILWAY_URL"
}

# Step 5: Update CORS
Write-Host ""
Write-Host "🔒 Step 5: Update Backend CORS" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""
$VERCEL_URL = Read-Host "Enter your Vercel deployment URL"

railway variables set CORS_ORIGINS="$VERCEL_URL,https://*.vercel.app"

Write-Host "✅ CORS updated" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "🎉 Staging Environment Deployed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend URL: $RAILWAY_URL"
Write-Host "Frontend URL: $VERCEL_URL"
Write-Host ""
Write-Host "Next Steps:"
Write-Host "1. Test backend health: Invoke-WebRequest $RAILWAY_URL/health"
Write-Host "2. Test API docs: $RAILWAY_URL/docs"
Write-Host "3. Test frontend: $VERCEL_URL"
Write-Host "4. Configure custom domains (optional)"
Write-Host "5. Set up monitoring and alerts"
Write-Host ""
Write-Host "Documentation:"
Write-Host "- Backend: backend/RAILWAY_DEPLOY.md"
Write-Host "- Frontend: frontend/VERCEL_DEPLOY.md"
Write-Host "- Database: docs/neon-setup-guide.md"
Write-Host "- Full Guide: docs/staging-setup.md"
Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green

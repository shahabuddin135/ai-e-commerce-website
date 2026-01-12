#!/bin/bash

# AI E-Commerce Platform - Staging Deployment Script
# This script helps deploy the complete staging environment

set -e  # Exit on error

echo "🚀 AI E-Commerce Platform - Staging Deployment"
echo "================================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI not found${NC}"
    echo "Install it with: npm install -g @railway/cli"
    exit 1
fi

# Check if Vercel CLI is installed (optional)
if ! command -v vercel &> /dev/null; then
    echo -e "${YELLOW}⚠️  Vercel CLI not found (optional)${NC}"
    echo "You can install it with: npm install -g vercel"
    echo ""
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Step 1: Neon Setup
echo "📊 Step 1: Neon Postgres Setup"
echo "================================"
echo ""
echo "1. Go to https://neon.tech and create account"
echo "2. Create new project: 'ai-ecommerce-staging'"
echo "3. Region: Choose closest to your Railway region"
echo "4. Get BOTH connection strings:"
echo "   - Pooled (for Railway app)"
echo "   - Direct (for migrations)"
echo ""
echo "Have you completed Neon setup? (y/n)"
read -r neon_ready

if [ "$neon_ready" != "y" ]; then
    echo -e "${YELLOW}📖 Please follow: docs/neon-setup-guide.md${NC}"
    exit 0
fi

echo ""
echo "Enter your Neon POOLED connection string:"
read -r DATABASE_URL_POOLED

echo ""
echo "Enter your Neon DIRECT connection string:"
read -r DATABASE_URL_DIRECT

# Step 2: Railway Backend Setup
echo ""
echo "🚂 Step 2: Railway Backend Deployment"
echo "======================================"
echo ""

# Check if railway project is linked
if ! railway status &> /dev/null; then
    echo "Railway project not linked. Linking now..."
    railway link
fi

echo "Setting Railway environment variables..."

# Generate secrets
JWT_SECRET=$(openssl rand -base64 32)
SESSION_SECRET=$(openssl rand -base64 32)
CSRF_SECRET=$(openssl rand -base64 32)

# Set environment variables
railway variables set \
    DATABASE_URL="$DATABASE_URL_POOLED" \
    JWT_SECRET_KEY="$JWT_SECRET" \
    SESSION_SECRET="$SESSION_SECRET" \
    CSRF_SECRET="$CSRF_SECRET" \
    PYTHON_ENV="staging" \
    DEBUG="false" \
    WORKERS="2" \
    API_PREFIX="/api/v1" \
    BACKEND_HOST="0.0.0.0" \
    RATE_LIMIT_ENABLED="true"

echo -e "${GREEN}✅ Environment variables set${NC}"

# Add Redis
echo ""
echo "Would you like to add Redis? (y/n)"
read -r add_redis

if [ "$add_redis" = "y" ]; then
    echo "Adding Redis..."
    railway add redis
    echo -e "${GREEN}✅ Redis added${NC}"
fi

# Deploy backend
echo ""
echo "Deploying backend to Railway..."
cd backend
railway up
cd ..

echo -e "${GREEN}✅ Backend deployed${NC}"

# Get Railway URL
RAILWAY_URL=$(railway status --json | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
echo ""
echo "Backend URL: $RAILWAY_URL"

# Step 3: Run Migrations
echo ""
echo "🗄️  Step 3: Database Migrations"
echo "==============================="
echo ""

cd backend

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    uv venv
fi

# Activate virtual environment
source .venv/bin/activate

# Set direct connection for migrations
export DATABASE_URL="$DATABASE_URL_DIRECT"

echo "Generating initial migration..."
alembic revision --autogenerate -m "Initial schema setup"

echo "Applying migrations..."
alembic upgrade head

echo -e "${GREEN}✅ Migrations applied${NC}"

cd ..

# Step 4: Vercel Frontend Setup
echo ""
echo "▲ Step 4: Vercel Frontend Deployment"
echo "====================================="
echo ""

if ! command -v vercel &> /dev/null; then
    echo -e "${YELLOW}⚠️  Vercel CLI not installed${NC}"
    echo "Please deploy frontend manually:"
    echo "1. Go to https://vercel.com"
    echo "2. Import your GitHub repository"
    echo "3. Set root directory to: frontend"
    echo "4. Add environment variables from: frontend/VERCEL_DEPLOY.md"
    echo "5. Set NEXT_PUBLIC_API_URL=$RAILWAY_URL"
else
    echo "Login to Vercel..."
    vercel login

    cd frontend

    echo "Linking Vercel project..."
    vercel link

    echo "Setting environment variables..."
    vercel env add NEXT_PUBLIC_API_URL preview
    echo "$RAILWAY_URL"

    echo "Deploying to Vercel..."
    vercel

    cd ..

    echo -e "${GREEN}✅ Frontend deployed${NC}"
fi

# Step 5: Update CORS
echo ""
echo "🔒 Step 5: Update Backend CORS"
echo "==============================="
echo ""
echo "Enter your Vercel deployment URL:"
read -r VERCEL_URL

railway variables set CORS_ORIGINS="$VERCEL_URL,https://*.vercel.app"

echo -e "${GREEN}✅ CORS updated${NC}"

# Summary
echo ""
echo "=========================================="
echo "🎉 Staging Environment Deployed!"
echo "=========================================="
echo ""
echo "Backend URL: $RAILWAY_URL"
echo "Frontend URL: $VERCEL_URL"
echo ""
echo "Next Steps:"
echo "1. Test backend health: curl $RAILWAY_URL/health"
echo "2. Test API docs: $RAILWAY_URL/docs"
echo "3. Test frontend: $VERCEL_URL"
echo "4. Configure custom domains (optional)"
echo "5. Set up monitoring and alerts"
echo ""
echo "Documentation:"
echo "- Backend: backend/RAILWAY_DEPLOY.md"
echo "- Frontend: frontend/VERCEL_DEPLOY.md"
echo "- Database: docs/neon-setup-guide.md"
echo "- Full Guide: docs/staging-setup.md"
echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"

# Neon Postgres Staging Setup

## Quick Setup Guide

### 1. Create Neon Account

1. Go to [neon.tech](https://neon.tech)
2. Sign up with GitHub (recommended for easy integration)
3. Verify email

### 2. Create Staging Database

**Option A: Create New Project (Recommended for staging)**

1. Click **"New Project"**
2. **Project name**: `ai-ecommerce-staging`
3. **Region**: Select closest to your Railway region (check Railway dashboard)
   - US East (Ohio) - `us-east-2`
   - US West (Oregon) - `us-west-2`
   - EU (Frankfurt) - `eu-central-1`
4. **Postgres version**: 16 (latest stable)
5. **Compute size**: 
   - Autoscaling: 0.25 - 1 vCPU
   - Auto-suspend: 5 minutes of inactivity
6. Click **"Create Project"**

**Option B: Create Branch from Existing Project**

```bash
# If you already have a dev database
1. Open existing project
2. Click "Branches"
3. Click "Create Branch"
4. Name: "staging"
5. Branch from: "main"
```

### 3. Get Connection Strings

After project creation, you'll see connection details:

**Important: Use the POOLED connection for Railway!**

1. Click **"Connection Details"**
2. Toggle **"Pooled connection"** (enables PgBouncer)
3. Copy the connection string

```bash
# Pooled connection (USE THIS for Railway)
postgresql://user:password@ep-xxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require

# Direct connection (USE THIS for Alembic migrations)
postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb
```

### 4. Save Both Connection Strings

Create a temporary secure note with:

```bash
# Neon Staging Database Credentials

# Pooled (for Railway app)
DATABASE_URL_POOLED=postgresql://user:password@ep-xxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require

# Direct (for migrations)
DATABASE_URL_DIRECT=postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb

# Project Details
Project: ai-ecommerce-staging
Region: us-east-2
Database: neondb
Role: user
```

### 5. Configure Neon Settings

**Compute Settings:**

1. In Neon dashboard → Project → Settings
2. **Compute**:
   - Autoscaling: ON
   - Min: 0.25 vCPU
   - Max: 1 vCPU (sufficient for staging)
   - Auto-suspend: 5 minutes
3. **Storage**:
   - Default settings (grows as needed)

**Connection Pooling:**

1. Settings → Connection Pooling
2. **Mode**: Transaction (default, best for most apps)
3. **Pool size**: 15 (default)
4. Verify pooled connection string

**Backups:**

1. Settings → Backups
2. **Point-in-time restore**: Enabled (7 days free)
3. **Retention**: 7 days (for staging)

### 6. Test Connection Locally

```bash
# Test with psql
psql "postgresql://user:password@ep-xxx-pooler...?sslmode=require"

# Or with Python
python -c "import psycopg2; conn = psycopg2.connect('postgresql://...'); print('Connected!'); conn.close()"
```

### 7. Add to Railway

```bash
# Set the DATABASE_URL in Railway (use POOLED connection)
railway variables set DATABASE_URL="postgresql://user:password@ep-xxx-pooler...?sslmode=require"

# Also set for local .env
# Add to backend/.env (use DIRECT for migrations)
DATABASE_URL=postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb
```

### 8. Run Initial Migrations

```bash
# From backend directory locally
cd backend

# Activate virtual environment
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Set DATABASE_URL to DIRECT connection
export DATABASE_URL="postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb"

# Generate initial migration
alembic revision --autogenerate -m "Initial schema"

# Apply migrations
alembic upgrade head

# Verify
psql "$DATABASE_URL" -c "\dt"
```

## Connection String Anatomy

```
postgresql://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=require
          ↓      ↓         ↓      ↓      ↓           ↓
       role   password  endpoint port  dbname    SSL required

Pooled endpoint: ep-xxx-pooler.region.aws.neon.tech
Direct endpoint: ep-xxx.region.aws.neon.tech
```

## Important Notes

### ✅ DO:
- Use **pooled connection** for Railway application
- Use **direct connection** for Alembic migrations
- Enable SSL (`?sslmode=require`)
- Use strong password (Neon generates automatically)
- Keep credentials in Railway environment variables
- Test connection before deploying

### ❌ DON'T:
- Commit connection strings to Git
- Use direct connection for high-traffic apps (connection limit)
- Share staging credentials with production
- Disable SSL in production/staging
- Use default database name in production

## Monitoring & Maintenance

### View Database Activity

1. Neon Dashboard → Project → Monitoring
2. Check:
   - Active connections
   - Query performance
   - Storage usage
   - Compute usage

### Query Logs

```sql
-- View recent queries (if enabled)
SELECT * FROM pg_stat_activity 
WHERE datname = 'neondb' 
ORDER BY query_start DESC 
LIMIT 10;
```

### Database Size

```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('neondb'));
```

## Troubleshooting

**"Connection refused":**
- Check if IP is allowed (Neon allows all by default)
- Verify SSL mode is set
- Check credentials are correct

**"Too many connections":**
- Switch to pooled connection
- Reduce connection pool size in app
- Check for connection leaks

**"SSL required":**
- Add `?sslmode=require` to connection string
- Never use `?sslmode=disable` in staging/production

**Slow queries:**
- Check Monitoring tab in Neon dashboard
- Add indexes (via migrations)
- Use EXPLAIN ANALYZE for query plans

## Security Checklist

- [ ] Strong password used (auto-generated)
- [ ] SSL enabled (`sslmode=require`)
- [ ] Credentials stored in Railway env vars only
- [ ] Connection strings never committed to Git
- [ ] Separate credentials for staging vs production
- [ ] Regular backups enabled (7-day retention)
- [ ] Point-in-time recovery verified

## Cost Optimization (Staging)

Neon Free Tier includes:
- 0.5 GB storage
- Unlimited compute hours (with auto-suspend)
- 1 project

For staging:
- Enable auto-suspend (5 minutes)
- Use minimal compute (0.25-1 vCPU autoscaling)
- Clean up old data periodically
- Use branches instead of separate projects when possible

## Next Steps

After Neon setup:

1. ✅ Save both connection strings securely
2. ✅ Add pooled connection to Railway
3. ✅ Run migrations with direct connection
4. ✅ Test database connectivity
5. ✅ Update backend CORS with frontend URL
6. ✅ Deploy Railway backend
7. ✅ Verify health checks pass

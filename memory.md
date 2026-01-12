# Project Memory - AI E-Commerce Platform

> **Purpose**: This document serves as the project's memory, tracking key decisions, technical specifics, context, and important details to maintain consistency throughout development.

**Last Updated**: January 12, 2026

---

## 🎯 Project Overview

**Project Name**: AI E-Commerce Platform  
**Type**: SaaS E-Commerce Platform with Subscription Model  
**Start Date**: January 2026  
**Current Phase**: Phase 1 - Foundation & Infrastructure

### Core Objectives
1. Build a modern, scalable e-commerce platform
2. Implement subscription-based monetization via Lemon Squeezy
3. Provide headless CMS capabilities via Sanity
4. Ensure production-ready security and performance
5. Maintain comprehensive testing and monitoring

---

## 🏗️ Architecture Decisions

### Technology Stack

#### Frontend
- **Framework**: Next.js 15 (App Router, NOT Pages Router)
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS
- **Package Manager**: Bun
- **State Management**: React Query (TanStack Query) + Zustand
- **Form Handling**: React Hook Form + Zod validation
- **Deployment**: Vercel

**Why Next.js 15 with App Router?**
- Server Components for better performance
- Built-in API routes
- Excellent SEO capabilities
- Native image optimization
- Seamless Vercel deployment

#### Backend
- **Framework**: FastAPI
- **Language**: Python 3.11+
- **Package Manager**: UV (astral-sh/uv) - **IMPORTANT: Not pip/poetry**
- **ORM**: SQLAlchemy 2.0
- **Migrations**: Alembic
- **Validation**: Pydantic v2
- **Deployment**: Railway

**Why UV for Python?**
- Extremely fast package installation (10-100x faster than pip)
- Built-in virtual environment management
- Better dependency resolution
- Modern lockfile approach
- Rust-powered performance

**UV Commands to Remember**:
```bash
uv venv                    # Create virtual environment
uv pip install -e ".[dev]" # Install with dev dependencies
uv run python script.py    # Run Python with UV context
uv pip install package     # Add new package
```

#### Database & Infrastructure
- **Database**: Neon Postgres (serverless PostgreSQL)
  - Connection pooling via PgBouncer (built-in)
  - Separate instances for dev/staging/production
- **Cache/Sessions**: Redis (Upstash or Railway add-on)
- **Message Queue**: BullMQ with Redis
- **CMS**: Sanity CMS (NOT custom CMS, NOT Strapi)
- **Payments**: Lemon Squeezy (NOT Stripe)

**Why Neon Postgres?**
- Serverless architecture (pay for what you use)
- Built-in branching for development
- Automatic scaling
- Point-in-time recovery
- Excellent Railway integration

**Why Lemon Squeezy over Stripe?**
- Handles tax compliance automatically
- Simpler merchant of record setup
- Better for digital products/subscriptions
- Fewer compliance requirements
- Per-project decision documented in task.md

---

## 🗄️ Database Schema

### Core Tables (Completed in Task 1.2.1)

1. **users**
   - id (UUID, PK)
   - email (unique, indexed)
   - password_hash
   - email_verified (boolean)
   - role (enum: user, admin, moderator)
   - created_at, updated_at
   - last_login_at

2. **sessions**
   - id (UUID, PK)
   - user_id (FK to users)
   - token (indexed)
   - expires_at
   - ip_address
   - user_agent
   - created_at

3. **payments**
   - id (UUID, PK)
   - user_id (FK to users)
   - amount
   - currency
   - status (enum: pending, completed, failed, refunded)
   - lemon_squeezy_order_id
   - lemon_squeezy_customer_id
   - created_at, updated_at

4. **subscriptions**
   - id (UUID, PK)
   - user_id (FK to users)
   - plan_id
   - status (enum: active, cancelled, paused, expired)
   - current_period_start
   - current_period_end
   - cancel_at_period_end (boolean)
   - lemon_squeezy_subscription_id
   - created_at, updated_at

5. **notifications**
   - id (UUID, PK)
   - user_id (FK to users)
   - type (enum: info, warning, success, error)
   - title
   - content (text)
   - read (boolean, default false)
   - created_at

6. **user_preferences**
   - id (UUID, PK)
   - user_id (FK to users, unique)
   - preferences_json (JSONB)
   - created_at, updated_at

**Content Tables**: None (using Sanity CMS, no local content storage)

---

## 🔐 Authentication & Security

### Authentication Strategy
- **Primary**: JWT-based authentication
  - Access tokens: 30 minutes expiry
  - Refresh tokens: 7 days expiry
  - Stored in httpOnly cookies (NOT localStorage)
- **OAuth**: Google, GitHub (optional Twitter)
- **Sessions**: Redis-backed for quick invalidation

### Security Measures
- Password hashing: bcrypt (NOT plain SHA256)
- Rate limiting on all auth endpoints
- CSRF protection on state-changing operations
- CORS configured per environment
- Security headers (CSP, HSTS, X-Frame-Options, etc.)
- Input validation using Pydantic (backend) and Zod (frontend)

**Key Security Requirements**:
1. Never store JWT secrets in code
2. Always use environment variables
3. Implement token rotation on refresh
4. Log all authentication attempts
5. Use secure session cookies

---

## 💳 Payment Integration

### Lemon Squeezy Integration
- **Test Mode**: Use test mode for development
- **Webhook Events to Handle**:
  - subscription_created
  - subscription_updated
  - subscription_cancelled
  - payment_success
  - payment_failed
  - refund events

### Subscription Plans (To be configured)
- Basic Plan
- Pro Plan
- Enterprise Plan
(IDs to be added after Lemon Squeezy setup)

**Critical**: Always verify webhook signatures to prevent fraud

---

## 📝 Content Management

### Sanity CMS Strategy
- **Content Storage**: ALL content in Sanity (no local database tables)
- **Media Storage**: Sanity DAM (Digital Asset Management)
- **CDN**: Sanity CDN for content delivery
- **No Need For**: S3, Cloudflare R2, custom CDN setup

### Sanity Structure (To be defined in Phase 5)
- Document schemas
- GROQ queries
- Preview mode integration
- Revalidation strategy (ISR or on-demand)

**Why Sanity?**
- Excellent Next.js integration
- Built-in CDN and image optimization
- Real-time collaboration
- Customizable Studio
- No separate storage management needed

---

## 🚀 Deployment Strategy

### Environments
1. **Development**: Local machine
   - Database: Neon dev instance
   - Frontend: localhost:3000
   - Backend: localhost:8000

2. **Staging**: Cloud-hosted preview
   - Database: Neon staging instance
   - Frontend: Vercel preview deployment
   - Backend: Railway staging environment

3. **Production**: Live application
   - Database: Neon production instance (sized appropriately)
   - Frontend: Vercel production
   - Backend: Railway production

### Git Workflow
- **Branching Model**: GitFlow
  - `main`: Production code
  - `develop`: Integration branch
  - `feature/*`: Feature development
  - `hotfix/*`: Production fixes
- **Commit Convention**: Conventional Commits (feat, fix, docs, etc.)

### CI/CD Pipeline
- GitHub Actions for automated testing
- Auto-deploy to staging on merge to develop
- Manual approval for production deploys
- Automated database migrations in pipeline

---

## 📊 Monitoring & Analytics

### Analytics
- **PostHog**: Product analytics and feature flags
- Track: signups, conversions, feature usage, retention

### Error Tracking
- **Sentry**: Frontend and backend error tracking
- Source maps uploaded for better debugging
- User context attached to errors

### Monitoring
- **Health Checks**: /health and /health/ready endpoints
- **Logging**: Structured JSON logs
- **APM**: Application performance monitoring (tool TBD)

---

## ✅ Implementation Progress

### Completed Tasks
- ✅ Task 1.1.1: Development Environment Setup
  - Created project directory structure (frontend/, backend/, docs/, scripts/)
  - Created comprehensive .gitignore for Python, Node.js, and sensitive files
  - Created .env.example with all environment variables
  - Created README.md with UV-specific setup instructions
  - Created this memory.md file

- ✅ Task 1.2.1: Database Schema Design
  - Designed all database tables
  - Documented table relationships
  - ⏳ ER diagram pending

- ✅ Task 1.2.3: Database Migration System (Partial)
  - Alembic initialized in backend
  - Configuration completed
  - ⏳ Initial migrations ready to generate

- ✅ Task 3.1.1: FastAPI Project Structure
  - Backend directory structure created
  - Base models and schemas defined
  - ⏳ Dependencies.py pending

### Current Focus
- Task 1.2.2: Neon Postgres Setup (next)
- Complete database migrations
- Set up Redis for caching

---

## 🎯 Key Decisions & Rationale

### Decision Log

| Date | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| Jan 2026 | Use UV instead of pip/poetry | 10-100x faster, better for developer experience | All backend setup uses UV commands |
| Jan 2026 | Use Sanity CMS instead of custom | Saves development time, built-in DAM, excellent Next.js integration | No need for S3/CDN setup (Task 1.3.3, 1.3.4 marked as NOT NEEDED) |
| Jan 2026 | Use Lemon Squeezy for payments | Automatic tax compliance, simpler than Stripe | All payment integration uses LS |
| Jan 2026 | Next.js App Router (not Pages) | Future-proof, better performance, React Server Components | All frontend uses App Router patterns |
| Jan 2026 | Neon Postgres over traditional | Serverless, auto-scaling, branching, cost-effective | Connection pooling included, easier scaling |

---

## 📌 Important Reminders

### Backend Development
- ✅ **ALWAYS** use UV for package management (NOT pip install)
- ✅ **ALWAYS** activate virtual environment before running commands
- ✅ Use `uv pip install` to add packages
- ✅ Use `uv run` to execute Python scripts
- ✅ Keep pyproject.toml updated with dependencies

### Frontend Development
- ✅ Use Bun for package management (NOT npm/yarn)
- ✅ Follow App Router conventions (NOT Pages Router)
- ✅ Prefix client-side env vars with NEXT_PUBLIC_
- ✅ Use Server Components by default, Client Components when needed

### Database
- ✅ Use Alembic for ALL schema changes (never manual SQL)
- ✅ Test migrations in dev before staging/production
- ✅ Always create backups before major migrations
- ✅ Use UUIDs for primary keys (NOT auto-increment integers)

### Security
- ✅ NEVER commit .env files
- ✅ NEVER hardcode secrets
- ✅ ALWAYS validate user input (Pydantic + Zod)
- ✅ ALWAYS use parameterized queries (SQLAlchemy ORM)
- ✅ Implement rate limiting on all public endpoints

### Content & Media
- ✅ ALL content goes in Sanity (no local storage)
- ✅ ALL media uploaded to Sanity DAM (no S3)
- ✅ Use Sanity CDN for delivery (no separate CDN)

---

## 🔄 Common Workflows

### Adding a New Backend Feature
1. Activate virtual environment
2. Create feature branch: `git checkout -b feature/feature-name`
3. Create Pydantic schemas in `backend/app/schemas/`
4. Create SQLAlchemy models in `backend/app/models/` (if DB changes needed)
5. Generate migration: `alembic revision --autogenerate -m "description"`
6. Create service logic in `backend/app/services/`
7. Create API endpoints in `backend/app/api/`
8. Write tests in `backend/tests/`
9. Update API documentation
10. Create PR to develop branch

### Adding a New Frontend Page
1. Create feature branch
2. Create page in `frontend/app/route-name/page.tsx`
3. Create components in `frontend/components/`
4. Create types in `frontend/types/`
5. Create API service functions in `frontend/services/`
6. Add tests in `frontend/__tests__/`
7. Update navigation/routing
8. Create PR to develop branch

### Database Schema Changes
1. Update SQLAlchemy models in `backend/app/models/`
2. Generate migration: `alembic revision --autogenerate -m "description"`
3. Review generated migration file
4. Test migration: `alembic upgrade head`
5. Test rollback: `alembic downgrade -1`
6. Re-apply: `alembic upgrade head`
7. Commit migration file
8. Document changes in this memory.md if significant

---

## 🐛 Known Issues & Gotchas

### UV-Related
- Virtual environment MUST be activated before running UV commands
- Windows users: Use `.venv\Scripts\activate` (not `source`)
- If UV not found: `pip install uv` first

### Next.js App Router
- Server Components can't use hooks (useState, useEffect)
- 'use client' directive needed for Client Components
- Cookies and headers only work in Server Components/Route Handlers

### Neon Postgres
- Connection pooling URL different from direct URL
- Use pooled URL in production
- Branching creates separate databases (watch connection strings)

### Lemon Squeezy
- Test mode and production mode have different API keys
- Webhooks require HTTPS (use ngrok for local testing)
- Product IDs differ between test and production

---

## 📚 Reference Links

### Documentation
- [UV Documentation](https://docs.astral.sh/uv/)
- [Next.js 15 Docs](https://nextjs.org/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Neon Documentation](https://neon.tech/docs)
- [Sanity Documentation](https://www.sanity.io/docs)
- [Lemon Squeezy API](https://docs.lemonsqueezy.com/)

### Internal Docs
- [Task Tracking](./task.md) - Implementation roadmap
- [README](./README.md) - Setup and usage
- [API Documentation](http://localhost:8000/docs) - Interactive API docs (when running)

---

## 🎓 Team Knowledge

### For New Developers
1. Read this memory.md file completely
2. Review task.md for project roadmap
3. Follow README.md for setup
4. Ask questions before making architectural decisions
5. Update this file when making key decisions

### Code Review Checklist
- [ ] Follows project conventions (UV, App Router, etc.)
- [ ] Environment variables in .env.example
- [ ] Tests written and passing
- [ ] No hardcoded secrets
- [ ] Database migrations included (if applicable)
- [ ] Documentation updated
- [ ] Conventional commit message

---

## 🔮 Future Considerations

### Potential Additions (Not Currently Scoped)
- Multi-language support (i18n)
- Mobile app (React Native)
- Advanced analytics dashboard
- AI-powered recommendations
- WebSocket for real-time features
- Advanced caching strategies (CDN, edge caching)

**Note**: These are NOT in current scope. Update task.md if prioritized.

---

## 📝 Notes Section

### January 12, 2026
- Project initialized with proper directory structure
- UV selected as Python package manager for superior performance
- Sanity CMS chosen to eliminate need for custom storage/CDN solutions
- All base configuration files created (README, .env.example, .gitignore)
- Next steps: Set up Neon Postgres instances and configure database

---

**This document should be updated whenever key decisions are made or important context is discovered. It serves as the single source of truth for project-specific knowledge.**

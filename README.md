# AI E-Commerce Platform

A modern, full-stack e-commerce platform built with Next.js, FastAPI, and powered by cutting-edge technologies.

## 🏗️ Architecture Overview

- **Frontend**: Next.js 15 (App Router) + TypeScript + Tailwind CSS
- **Backend**: FastAPI + Python 3.11+ (with UV package manager)
- **Database**: Neon Postgres (serverless PostgreSQL)
- **CMS**: Sanity CMS for content management
- **Payments**: Lemon Squeezy for subscriptions and payments
- **Auth**: JWT-based authentication with OAuth support
- **Caching**: Redis for sessions and caching
- **Analytics**: PostHog for product analytics
- **Monitoring**: Sentry for error tracking
- **Deployment**: Vercel (frontend) + Railway (backend)

## 📁 Project Structure

```
ai-ecommerce/
├── frontend/                 # Next.js frontend application
│   ├── app/                 # Next.js App Router pages
│   ├── components/          # React components
│   ├── lib/                 # Utilities and configurations
│   ├── hooks/               # Custom React hooks
│   ├── types/               # TypeScript type definitions
│   ├── services/            # API client and services
│   ├── public/              # Static assets
│   └── package.json
├── backend/                 # FastAPI backend application
│   ├── app/                 # Main application code
│   │   ├── api/            # API routes
│   │   ├── core/           # Core configurations
│   │   ├── models/         # SQLAlchemy models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   └── utils/          # Utility functions
│   ├── alembic/            # Database migrations
│   ├── tests/              # Test files
│   ├── pyproject.toml      # UV project configuration
│   └── uv.lock             # UV lock file
├── docs/                    # Project documentation
├── scripts/                 # Utility scripts
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore rules
├── task.md                 # Implementation task tracking
├── memory.md               # Project memory and key decisions
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites

Ensure you have the following installed:

- **Node.js**: v20.x or higher ([Download](https://nodejs.org/))
- **Bun**: Latest version ([Install](https://bun.sh/))
- **Python**: 3.11 or higher ([Download](https://www.python.org/))
- **UV**: Latest version ([Install](https://docs.astral.sh/uv/))
- **Git**: Latest version ([Download](https://git-scm.com/))
- **PostgreSQL Client**: For database management (optional)
- **Redis**: For local development (optional, can use cloud Redis)

### Installation

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd ai-ecommerce
```

#### 2. Frontend Setup (Next.js)

```bash
cd frontend

# Install dependencies using Bun
bun install

# Copy environment variables
cp ../.env.example .env.local

# Update .env.local with your configuration
# At minimum, set:
# - NEXT_PUBLIC_API_URL (backend URL)
# - NEXT_PUBLIC_SANITY_PROJECT_ID
# - Database credentials
```

#### 3. Backend Setup (FastAPI with UV)

```bash
cd ../backend

# Create virtual environment using UV
uv venv

# Activate virtual environment
# On Windows:
.venv\Scripts\activate
# On macOS/Linux:
source .venv/bin/activate

# Install dependencies using UV
uv pip install -e ".[dev]"

# Copy environment variables
cp ../.env.example .env

# Update .env with your configuration
# At minimum, set:
# - DATABASE_URL (Neon Postgres connection string)
# - JWT_SECRET_KEY
# - REDIS_URL
```

#### 4. Database Setup

```bash
# Ensure you're in the backend directory with activated virtual environment

# Run database migrations
alembic upgrade head

# (Optional) Seed database with sample data
python scripts/seed_database.py
```

### Running the Application

#### Start Backend (FastAPI)

```bash
# From backend directory with activated virtual environment
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or using the UV command
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend will be available at: http://localhost:8000

API Documentation: http://localhost:8000/docs

#### Start Frontend (Next.js)

```bash
# From frontend directory
bun dev
```

Frontend will be available at: http://localhost:3000

### Running Tests

#### Backend Tests

```bash
# From backend directory with activated virtual environment
pytest

# With coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_auth.py
```

#### Frontend Tests

```bash
# From frontend directory
bun test

# With coverage
bun test --coverage

# Watch mode
bun test --watch
```

## 🔧 Development Workflow

### Using UV for Backend Development

UV is a fast Python package manager and environment manager. Here are common commands:

```bash
# Create virtual environment
uv venv

# Install dependencies
uv pip install -e ".[dev]"

# Add a new package
uv pip install package-name

# Update dependencies
uv pip install --upgrade package-name

# Run Python scripts with UV
uv run python script.py

# Run Uvicorn with UV
uv run uvicorn app.main:app --reload
```

### Database Migrations

```bash
# Create a new migration
alembic revision --autogenerate -m "Description of changes"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# View migration history
alembic history
```

### Git Workflow

We follow the GitFlow branching model:

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature branches
- `hotfix/*` - Urgent production fixes

```bash
# Create a feature branch
git checkout -b feature/your-feature-name develop

# Commit your changes
git add .
git commit -m "feat: description of your feature"

# Push to remote
git push origin feature/your-feature-name

# Create pull request to develop branch
```

### Commit Message Convention

We use Conventional Commits:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

## 📚 Environment Variables

See [.env.example](.env.example) for a complete list of environment variables.

### Critical Environment Variables

**Backend:**
- `DATABASE_URL` - PostgreSQL connection string (required)
- `JWT_SECRET_KEY` - JWT signing key (required)
- `REDIS_URL` - Redis connection string (required)

**Frontend:**
- `NEXT_PUBLIC_API_URL` - Backend API URL (required)
- `NEXT_PUBLIC_SANITY_PROJECT_ID` - Sanity CMS project ID (required)

## 🚢 Deployment

### Backend Deployment (Railway)

1. Create Railway account and project
2. Connect your GitHub repository
3. Add environment variables from `.env.example`
4. Railway will auto-deploy on push to main branch

### Frontend Deployment (Vercel)

1. Create Vercel account and import project
2. Add environment variables from `.env.example`
3. Vercel will auto-deploy on push to main branch

## 📖 Documentation

- [API Documentation](http://localhost:8000/docs) - Interactive API docs (Swagger)
- [Task Tracking](./task.md) - Implementation tasks and progress
- [Project Memory](./memory.md) - Key decisions and context
- Additional docs in `/docs` directory

## 🧪 Testing Strategy

- **Unit Tests**: Test individual functions and components
- **Integration Tests**: Test API endpoints and database operations
- **E2E Tests**: Test complete user flows with Playwright
- **Coverage Target**: Minimum 70% code coverage

## 🛠️ Tech Stack Details

### Frontend
- **Framework**: Next.js 15 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State Management**: React Query + Zustand
- **Forms**: React Hook Form + Zod
- **HTTP Client**: Axios

### Backend
- **Framework**: FastAPI
- **Language**: Python 3.11+
- **ORM**: SQLAlchemy 2.0
- **Migrations**: Alembic
- **Validation**: Pydantic v2
- **Package Manager**: UV

### Infrastructure
- **Database**: Neon Postgres (serverless)
- **Cache**: Redis (Upstash or Railway)
- **CMS**: Sanity CMS
- **Payments**: Lemon Squeezy
- **Storage**: Sanity DAM
- **CDN**: Vercel CDN + Sanity CDN

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

[Add your license here]

## 👥 Team

[Add team members and contact information]

## 🆘 Support

For issues and questions:
- Create an issue on GitHub
- Contact: [your-email@example.com]
- Documentation: [link to docs]

## 🗺️ Roadmap

See [task.md](./task.md) for the complete implementation roadmap and progress tracking.

## ⚙️ Troubleshooting

### Common Issues

**Backend won't start:**
- Ensure virtual environment is activated
- Verify DATABASE_URL is correct
- Check if port 8000 is available

**Frontend won't start:**
- Clear `.next` directory: `rm -rf .next`
- Reinstall dependencies: `bun install`
- Check if port 3000 is available

**Database connection errors:**
- Verify Neon Postgres credentials
- Check if database is accessible from your network
- Ensure migrations are up to date

**UV package manager issues:**
- Update UV: `pip install --upgrade uv`
- Clear UV cache: `uv cache clean`
- Recreate virtual environment

For more troubleshooting, see `/docs/troubleshooting.md`

---

**Built with ❤️ using modern web technologies**

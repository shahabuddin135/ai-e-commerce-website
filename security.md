# Security Best Practices & Guidelines

> **CRITICAL**: This document MUST be read and followed for ALL code changes. It prevents security vulnerabilities, data leaks, and costly mistakes.

**Last Updated**: January 12, 2026

---

## 🔐 Core Security Principles

### The Golden Rules

1. **NEVER trust user input** - Validate and sanitize everything
2. **NEVER commit secrets** - Use environment variables exclusively
3. **NEVER expose internal errors** - Return generic error messages to users
4. **ALWAYS use HTTPS** - No exceptions in production
5. **ALWAYS hash passwords** - Never store plain text passwords
6. **ALWAYS validate on server** - Client-side validation is NOT security
7. **ALWAYS use parameterized queries** - Prevent SQL injection
8. **ALWAYS implement rate limiting** - Prevent abuse and DoS
9. **ALWAYS log security events** - Track authentication attempts, failures, etc.
10. **ALWAYS keep dependencies updated** - Patch known vulnerabilities

---

## 🚫 NEVER Do This

### ❌ Secrets in Code

**WRONG:**
```python
# ❌ NEVER DO THIS
DATABASE_URL = "postgresql://user:password@host:5432/db"
JWT_SECRET = "my-secret-key-123"
API_KEY = "sk_live_abc123xyz"
```

**CORRECT:**
```python
# ✅ ALWAYS DO THIS
from app.core.config import settings

DATABASE_URL = settings.DATABASE_URL
JWT_SECRET = settings.JWT_SECRET_KEY
API_KEY = settings.API_KEY
```

### ❌ SQL Injection Vulnerabilities

**WRONG:**
```python
# ❌ NEVER DO THIS - SQL Injection risk
query = f"SELECT * FROM users WHERE email = '{email}'"
result = db.execute(query)
```

**CORRECT:**
```python
# ✅ ALWAYS DO THIS - Use ORM or parameterized queries
from sqlalchemy import select
result = db.execute(select(User).where(User.email == email))
```

### ❌ Exposing Sensitive Error Information

**WRONG:**
```python
# ❌ NEVER DO THIS - Exposes internal details
@app.exception_handler(Exception)
async def handler(request, exc):
    return {"error": str(exc), "traceback": traceback.format_exc()}
```

**CORRECT:**
```python
# ✅ ALWAYS DO THIS - Generic error, log details internally
@app.exception_handler(Exception)
async def handler(request, exc):
    logger.error(f"Internal error: {exc}", exc_info=True)
    return {"error": "An internal error occurred", "request_id": request.state.request_id}
```

### ❌ Storing Passwords in Plain Text

**WRONG:**
```python
# ❌ NEVER DO THIS
user.password = password
db.add(user)
```

**CORRECT:**
```python
# ✅ ALWAYS DO THIS - Hash with bcrypt/argon2
from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
user.password_hash = pwd_context.hash(password)
db.add(user)
```

### ❌ Client-Side Validation Only

**WRONG:**
```typescript
// ❌ NEVER DO THIS - Client-side only
function submitForm(data) {
  if (data.email.includes('@')) {
    api.post('/users', data); // No server validation
  }
}
```

**CORRECT:**
```typescript
// ✅ ALWAYS DO THIS - Server validates too
function submitForm(data) {
  // Client validation for UX
  if (!data.email.includes('@')) return;
  
  // Server MUST validate again
  api.post('/users', data); // Backend validates with Pydantic/Zod
}
```

---

## 🔒 Authentication & Authorization

### Password Security

**Requirements:**
- Minimum 8 characters (enforce 12+ for better security)
- Use bcrypt or Argon2 for hashing (NOT MD5, SHA1, or plain SHA256)
- Implement password strength validation
- Salt passwords automatically (bcrypt does this)
- Set password expiry for sensitive accounts (optional)

**Implementation:**
```python
from passlib.context import CryptContext

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=12  # Cost factor (higher = slower but more secure)
)

# Hash password
hashed = pwd_context.hash(plain_password)

# Verify password
is_valid = pwd_context.verify(plain_password, hashed_password)
```

### JWT Token Security

**Best Practices:**
- Use strong secret keys (minimum 32 characters, random)
- Set appropriate expiry times:
  - Access tokens: 15-30 minutes
  - Refresh tokens: 7-30 days
- Store tokens in httpOnly cookies (NOT localStorage)
- Implement token rotation on refresh
- Maintain a token blacklist for logout
- Include minimal claims (user_id, role, exp, iat)
- Use RS256 for multi-service architectures (optional)

**NEVER:**
```typescript
// ❌ NEVER store tokens in localStorage
localStorage.setItem('token', jwt);

// ❌ NEVER accept tokens from query params in production
const token = new URLSearchParams(window.location.search).get('token');
```

**ALWAYS:**
```typescript
// ✅ Use httpOnly cookies
document.cookie = `token=${jwt}; HttpOnly; Secure; SameSite=Strict`;

// ✅ Or use secure cookie libraries
cookies.set('token', jwt, { httpOnly: true, secure: true, sameSite: 'strict' });
```

### Session Management

**Rules:**
- Store sessions in Redis (NOT in-memory for production)
- Implement session expiry
- Regenerate session ID after login
- Implement concurrent session limits per user
- Clear sessions on logout
- Track session metadata (IP, user agent)

### OAuth Security

**Checklist:**
- ✅ Validate OAuth state parameter (CSRF protection)
- ✅ Use PKCE for public clients
- ✅ Validate redirect URIs strictly
- ✅ Store OAuth tokens securely (encrypted in DB)
- ✅ Implement OAuth scope validation
- ✅ Handle OAuth errors gracefully

---

## 🛡️ API Security

### Rate Limiting

**Implementation Required:**
- Global rate limit: 100 requests/minute per IP
- Auth endpoints: 5 login attempts/15 minutes per IP
- Registration: 3 signups/hour per IP
- Password reset: 3 requests/hour per email
- API endpoints: 60 requests/minute per user
- Webhook endpoints: 100 requests/minute per source

**Example:**
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/api/v1/auth/login")
@limiter.limit("5/15minutes")
async def login(request: Request, credentials: LoginSchema):
    # Login logic
    pass
```

### Input Validation

**ALWAYS Validate:**
- ✅ All user inputs (forms, APIs, webhooks)
- ✅ File uploads (type, size, content)
- ✅ Query parameters
- ✅ Headers
- ✅ Cookies
- ✅ JSON payloads

**Use:**
- Backend: Pydantic v2 for request validation
- Frontend: Zod for form validation
- Database: SQLAlchemy constraints

**Example:**
```python
from pydantic import BaseModel, EmailStr, Field, validator

class UserCreate(BaseModel):
    email: EmailStr  # Validates email format
    password: str = Field(min_length=8, max_length=100)
    name: str = Field(min_length=1, max_length=100)
    
    @validator('password')
    def password_strength(cls, v):
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain digit')
        return v
```

### CORS Configuration

**Security Rules:**
- NEVER use `*` for origins in production
- Specify exact allowed origins
- Set `credentials: true` only if needed
- Limit allowed methods to what's necessary
- Set appropriate preflight cache time

**Example:**
```python
from fastapi.middleware.cors import CORSMiddleware

# ✅ PRODUCTION
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://yourdomain.com",
        "https://www.yourdomain.com"
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
    max_age=3600
)

# ❌ NEVER IN PRODUCTION
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Security risk!
    allow_credentials=True  # With *, this won't work anyway
)
```

### CSRF Protection

**When Required:**
- All state-changing operations (POST, PUT, DELETE, PATCH)
- Form submissions
- Cookie-based authentication

**Implementation:**
```python
from starlette_csrf import CSRFMiddleware

app.add_middleware(
    CSRFMiddleware,
    secret=settings.CSRF_SECRET,
    cookie_name="csrftoken",
    header_name="X-CSRF-Token"
)
```

### API Versioning

**Best Practice:**
- Use URL versioning: `/api/v1/`, `/api/v2/`
- Maintain old versions during deprecation period
- Document breaking changes
- Set deprecation headers
- Give users time to migrate (3-6 months)

---

## 🗄️ Database Security

### Query Security

**ALWAYS:**
```python
# ✅ Use ORM (prevents SQL injection)
from sqlalchemy import select
users = db.execute(select(User).where(User.email == email))

# ✅ If raw SQL needed, use parameters
db.execute(
    "SELECT * FROM users WHERE email = :email",
    {"email": email}
)
```

**NEVER:**
```python
# ❌ String formatting = SQL injection
db.execute(f"SELECT * FROM users WHERE email = '{email}'")

# ❌ String concatenation = SQL injection  
db.execute("SELECT * FROM users WHERE email = '" + email + "'")
```

### Connection Security

**Checklist:**
- ✅ Use SSL/TLS for database connections in production
- ✅ Use connection pooling (prevents connection exhaustion)
- ✅ Set appropriate pool size (10-20 for most apps)
- ✅ Configure connection timeouts
- ✅ Use read replicas for read-heavy operations
- ✅ Implement connection retry logic

**Example:**
```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # Verify connections before use
    pool_recycle=3600,   # Recycle connections after 1 hour
    connect_args={
        "sslmode": "require",  # Require SSL in production
        "connect_timeout": 10
    }
)
```

### Data Protection

**Sensitive Data:**
- ✅ Encrypt sensitive columns (SSN, credit cards, etc.)
- ✅ Hash passwords (bcrypt/Argon2)
- ✅ Mask sensitive data in logs
- ✅ Implement soft deletes for user data
- ✅ Regular backups with encryption
- ✅ Test restore procedures

**Example - Data Masking:**
```python
import logging

class SensitiveDataFilter(logging.Filter):
    def filter(self, record):
        # Mask email addresses
        record.msg = re.sub(
            r'([a-zA-Z0-9_.+-]+)@([a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)',
            r'\1***@\2',
            record.msg
        )
        # Mask credit card numbers
        record.msg = re.sub(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b', '****-****-****-****', record.msg)
        return True

logger.addFilter(SensitiveDataFilter())
```

### Migration Security

**Best Practices:**
- ✅ Review all migrations before applying
- ✅ Test migrations in development first
- ✅ Backup before production migrations
- ✅ Have rollback plan ready
- ✅ Use transactions for atomic migrations
- ✅ Never modify migrations after applied

---

## 📝 Logging & Monitoring

### What to Log

**Security Events (ALWAYS):**
- ✅ Authentication attempts (success/failure)
- ✅ Authorization failures
- ✅ Password changes/resets
- ✅ Account lockouts
- ✅ Privilege escalations
- ✅ Data access patterns (for sensitive data)
- ✅ Configuration changes
- ✅ Failed payment attempts

**Application Events:**
- ✅ Errors and exceptions
- ✅ Performance metrics
- ✅ External API calls
- ✅ Database slow queries
- ✅ Cache hit/miss rates

### What NOT to Log

**NEVER Log:**
- ❌ Passwords (plain or hashed)
- ❌ Credit card numbers
- ❌ API keys or tokens
- ❌ Session tokens
- ❌ Private encryption keys
- ❌ Personal identifiable information (PII) without masking
- ❌ Full request bodies with sensitive data

**Example:**
```python
# ❌ WRONG - Logs sensitive data
logger.info(f"User login attempt: {username}, password: {password}")

# ✅ CORRECT - Logs only necessary info
logger.info(f"User login attempt: {username}")

# ❌ WRONG - Logs full API key
logger.info(f"API call with key: {api_key}")

# ✅ CORRECT - Masks sensitive parts
logger.info(f"API call with key: {api_key[:8]}...")
```

### Structured Logging

**Use JSON Format:**
```python
import structlog

logger = structlog.get_logger()

# ✅ Structured logging
logger.info(
    "user_login",
    user_id=user.id,
    email=user.email,
    ip_address=request.client.host,
    user_agent=request.headers.get("user-agent"),
    success=True
)
```

---

## 🔑 Secrets Management

### Environment Variables

**Rules:**
- ✅ ALL secrets in environment variables
- ✅ NEVER commit .env files
- ✅ Keep .env.example updated (without values)
- ✅ Use different secrets for each environment
- ✅ Rotate secrets regularly
- ✅ Use secret management service in production (Railway secrets, Vercel env vars)

**Validation:**
```python
from pydantic_settings import BaseSettings
from pydantic import Field, validator

class Settings(BaseSettings):
    DATABASE_URL: str = Field(..., min_length=10)
    JWT_SECRET_KEY: str = Field(..., min_length=32)
    
    @validator('JWT_SECRET_KEY')
    def validate_jwt_secret(cls, v):
        if v == "changeme" or v == "secret":
            raise ValueError("Use a strong JWT secret")
        return v
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
```

### Secret Rotation

**Schedule:**
- JWT secrets: Every 90 days
- Database passwords: Every 90 days  
- API keys: Every 180 days
- OAuth secrets: Every 180 days

**Process:**
1. Generate new secret
2. Update in secret manager
3. Deploy application with new secret
4. Verify functionality
5. Revoke old secret after grace period

---

## 💰 Cost Security & Optimization

### Prevent Cost Overruns

**Database:**
- ✅ Set connection pool limits
- ✅ Implement query timeouts
- ✅ Use indexes on frequently queried columns
- ✅ Monitor slow queries
- ✅ Avoid N+1 query problems
- ✅ Use database query limits/pagination

**API:**
- ✅ Implement rate limiting (prevent abuse)
- ✅ Cache expensive operations
- ✅ Use CDN for static assets
- ✅ Compress responses
- ✅ Implement request timeouts

**Email:**
- ✅ Rate limit email sends per user
- ✅ Implement email verification before sending
- ✅ Use queue for batch operations
- ✅ Monitor email bounce rates

**External APIs:**
- ✅ Cache responses when possible
- ✅ Implement circuit breakers
- ✅ Set request timeouts
- ✅ Monitor API usage and costs
- ✅ Implement fallbacks

**Example - Prevent Email Spam:**
```python
from datetime import datetime, timedelta

async def send_email(user_id: str, email_type: str):
    # ✅ Check last email sent time
    last_sent = await redis.get(f"email:{user_id}:{email_type}")
    if last_sent:
        time_since = datetime.now() - datetime.fromisoformat(last_sent)
        if time_since < timedelta(minutes=5):
            raise RateLimitError("Email sent too recently")
    
    # Send email
    await email_service.send(...)
    
    # Store timestamp
    await redis.set(
        f"email:{user_id}:{email_type}",
        datetime.now().isoformat(),
        ex=300  # 5 minutes
    )
```

---

## 🚀 Deployment Security

### Pre-Deployment Checklist

**Configuration:**
- [ ] All environment variables set correctly
- [ ] Debug mode disabled (`DEBUG=false`)
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] CORS origins set correctly (no wildcards)
- [ ] Rate limiting enabled
- [ ] Error tracking configured (Sentry)
- [ ] Logging configured properly

**Code:**
- [ ] No hardcoded secrets
- [ ] No debug print statements
- [ ] No commented-out sensitive code
- [ ] Dependencies updated
- [ ] Security vulnerabilities patched
- [ ] Code reviewed by another developer

**Database:**
- [ ] Migrations tested
- [ ] Backups configured
- [ ] Indexes created
- [ ] Connection pooling configured
- [ ] SSL enabled

**Monitoring:**
- [ ] Health checks configured
- [ ] Alerts set up
- [ ] Logging verified
- [ ] Error tracking tested

### Production Environment Variables

**CRITICAL Settings:**
```bash
# ✅ Must be set in production
NODE_ENV=production
PYTHON_ENV=production
DEBUG=false
TESTING=false

# ✅ Must be HTTPS in production
NEXT_PUBLIC_APP_URL=https://yourdomain.com
NEXTAUTH_URL=https://yourdomain.com

# ✅ Strong secrets (minimum 32 chars)
JWT_SECRET_KEY=<strong-random-string-min-32-chars>
SESSION_SECRET=<strong-random-string-min-32-chars>
CSRF_SECRET=<strong-random-string-min-32-chars>

# ✅ Specific CORS origins
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# ✅ Production database with SSL
DATABASE_URL=postgresql://...?sslmode=require

# ✅ Production Lemon Squeezy
LEMON_SQUEEZY_TEST_MODE=false
```

---

## 🐛 Error Handling

### Error Response Format

**External (User-Facing):**
```python
# ✅ Generic, safe error messages
{
    "error": "Authentication failed",
    "message": "Invalid credentials",
    "request_id": "req_abc123"
}
```

**Internal (Logs):**
```python
# ✅ Detailed error information
logger.error(
    "Authentication failed",
    user_email=email,
    ip_address=request.client.host,
    error=str(exc),
    traceback=traceback.format_exc()
)
```

### Exception Handling

**Best Practices:**
```python
from fastapi import HTTPException
import logging

logger = logging.getLogger(__name__)

@app.post("/api/v1/users")
async def create_user(user: UserCreate):
    try:
        # Business logic
        new_user = await user_service.create(user)
        return new_user
    except DuplicateEmailError as e:
        # Expected error - inform user
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    except Exception as e:
        # Unexpected error - log details, generic message
        logger.error(
            "Failed to create user",
            email=user.email,
            error=str(e),
            exc_info=True
        )
        raise HTTPException(
            status_code=500,
            detail="An error occurred while creating user"
        )
```

---

## 📦 Dependency Security

### Dependency Management

**Rules:**
- ✅ Keep dependencies updated
- ✅ Review dependency security advisories
- ✅ Use dependency scanning tools (Dependabot, Snyk)
- ✅ Pin dependency versions in production
- ✅ Audit dependencies before adding
- ✅ Remove unused dependencies

**Commands:**
```bash
# Backend - Check for vulnerabilities
uv pip list --outdated
uv pip install --upgrade package-name

# Frontend - Check for vulnerabilities
bun audit
bun upgrade
```

### Package Verification

**Before Installing:**
1. Check package popularity (downloads, stars)
2. Review last update date (avoid abandoned packages)
3. Check for known vulnerabilities
4. Review package permissions
5. Verify package author/maintainer

---

## 🧪 Testing Security

### Security Test Cases

**Required Tests:**
- [ ] SQL injection attempts
- [ ] XSS attack vectors
- [ ] CSRF protection
- [ ] Authentication bypass attempts
- [ ] Authorization privilege escalation
- [ ] Rate limiting effectiveness
- [ ] Session fixation
- [ ] Password reset token validation
- [ ] File upload restrictions
- [ ] API input validation

**Example:**
```python
def test_sql_injection_protection():
    """Test that SQL injection is prevented"""
    malicious_email = "'; DROP TABLE users; --"
    response = client.post(
        "/api/v1/auth/login",
        json={"email": malicious_email, "password": "test"}
    )
    # Should not crash or expose SQL errors
    assert response.status_code in [400, 401]
    assert "DROP" not in response.text
    assert "SQL" not in response.text

def test_rate_limiting():
    """Test that rate limiting works"""
    for i in range(10):
        response = client.post("/api/v1/auth/login", json={...})
    
    # 11th request should be rate limited
    response = client.post("/api/v1/auth/login", json={...})
    assert response.status_code == 429
```

---

## ✅ Code Review Security Checklist

### For Every Code Change

**Authentication & Authorization:**
- [ ] No hardcoded credentials
- [ ] Proper authentication required
- [ ] Authorization checks implemented
- [ ] Password hashing used
- [ ] Session management secure

**Input Validation:**
- [ ] All inputs validated (server-side)
- [ ] SQL injection prevented (ORM used)
- [ ] XSS prevention implemented
- [ ] File upload restrictions in place
- [ ] Request size limits set

**Data Protection:**
- [ ] Sensitive data encrypted
- [ ] No sensitive data in logs
- [ ] PII handling compliant
- [ ] Proper error messages (no info leakage)

**API Security:**
- [ ] Rate limiting implemented
- [ ] CORS configured correctly
- [ ] CSRF protection enabled
- [ ] HTTPS enforced
- [ ] Security headers set

**Dependencies:**
- [ ] No new vulnerable dependencies
- [ ] Dependencies up to date
- [ ] Unused dependencies removed

**Configuration:**
- [ ] No secrets in code
- [ ] Environment variables used
- [ ] .env not committed
- [ ] .env.example updated

---

## 🎯 Security Priorities by Phase

### Phase 1 (Foundation) - CRITICAL
- ✅ Secrets management (env vars)
- ✅ Database security (SSL, parameterized queries)
- ✅ Git security (.gitignore, no commits of secrets)
- ✅ Dependency security (updated packages)

### Phase 2 (Authentication) - CRITICAL
- ✅ Password hashing (bcrypt)
- ✅ JWT security (strong secrets, expiry)
- ✅ Session management (Redis, secure cookies)
- ✅ Rate limiting (auth endpoints)
- ✅ CORS configuration
- ✅ CSRF protection

### Phase 3+ (Features) - IMPORTANT
- ✅ Input validation (all endpoints)
- ✅ Authorization checks (all protected routes)
- ✅ API rate limiting (all endpoints)
- ✅ Error handling (no info leakage)
- ✅ Logging (security events)
- ✅ Monitoring (Sentry, uptime)

---

## 📚 Security Resources

### Tools
- **OWASP ZAP**: Web application security scanner
- **Snyk**: Dependency vulnerability scanner
- **Dependabot**: Automated dependency updates
- **Bandit**: Python security linter
- **ESLint Security Plugin**: JavaScript security linting

### References
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [NIST Security Guidelines](https://www.nist.gov/)
- [FastAPI Security Best Practices](https://fastapi.tiangolo.com/tutorial/security/)
- [Next.js Security Headers](https://nextjs.org/docs/advanced-features/security-headers)

---

## 🚨 Incident Response

### If Security Breach Detected

1. **Immediate Actions:**
   - Isolate affected systems
   - Revoke compromised credentials
   - Block malicious IPs
   - Enable maintenance mode if needed

2. **Investigation:**
   - Review logs for entry point
   - Identify affected data/users
   - Document timeline of events
   - Preserve evidence

3. **Remediation:**
   - Patch vulnerability
   - Reset affected credentials
   - Notify affected users (if required by law)
   - Update security measures
   - Document lessons learned

4. **Post-Incident:**
   - Conduct security audit
   - Update security procedures
   - Train team on new measures
   - Monitor for repeat attempts

---

## 📝 Security Maintenance

### Regular Tasks

**Weekly:**
- Review error logs for suspicious patterns
- Check rate limiting effectiveness
- Monitor failed authentication attempts

**Monthly:**
- Update dependencies
- Review access logs
- Check for security advisories
- Test backup restoration

**Quarterly:**
- Rotate secrets and keys
- Security audit of code changes
- Review and update security policies
- Penetration testing (if budget allows)

**Annually:**
- Comprehensive security audit
- Review and update incident response plan
- Security training for team
- Review compliance requirements

---

**REMEMBER: Security is not a one-time task. It's an ongoing process that requires constant vigilance and updates.**

**When in doubt, ask: "Could this be exploited?" If yes, fix it before shipping.**

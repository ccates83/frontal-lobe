---
name: python-patterns
description: "Python development patterns, Django/FastAPI conventions, async patterns, type system usage, testing strategies, and package management. Reference material for python-orchestrator, python-architect, python-builder, python-reviewer, and python-tester agents."
---

# Python Patterns — Architecture, Framework & Testing Reference

Quick-reference guide for modern Python development. Used by the Python orchestrator ecosystem.

## When to Apply

Reference these patterns when:
- Designing Python application architecture
- Implementing Django, FastAPI, Flask, or CLI applications
- Reviewing Python code for correctness and performance
- Writing tests with pytest
- Setting up Python project structure and tooling

---

## 1. Project Structure Patterns

### FastAPI Application
```
src/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app creation, middleware, startup
│   ├── config.py             # Pydantic Settings
│   ├── dependencies.py       # Shared Depends()
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── users.py
│   │   └── orders.py
│   ├── models/               # SQLAlchemy/Pydantic models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── order.py
│   ├── schemas/              # Pydantic request/response schemas
│   │   ├── __init__.py
│   │   └── user.py
│   ├── services/             # Business logic
│   │   ├── __init__.py
│   │   └── user_service.py
│   └── db/
│       ├── __init__.py
│       ├── session.py
│       └── migrations/
tests/
├── conftest.py
├── test_users.py
└── test_orders.py
pyproject.toml
```

### Django Application
```
project/
├── manage.py
├── config/                   # Project settings
│   ├── __init__.py
│   ├── settings/
│   │   ├── base.py
│   │   ├── local.py
│   │   └── production.py
│   ├── urls.py
│   └── wsgi.py
├── apps/
│   ├── users/
│   │   ├── __init__.py
│   │   ├── admin.py
│   │   ├── apps.py
│   │   ├── models.py
│   │   ├── serializers.py    # DRF
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── services.py       # Business logic (not in views)
│   │   ├── tests/
│   │   │   ├── test_models.py
│   │   │   └── test_views.py
│   │   └── migrations/
│   └── orders/
pyproject.toml
```

### CLI Tool
```
src/
├── mycli/
│   ├── __init__.py
│   ├── __main__.py           # python -m mycli
│   ├── cli.py                # Typer/Click commands
│   ├── commands/
│   │   ├── __init__.py
│   │   ├── process.py
│   │   └── report.py
│   └── lib/
│       ├── __init__.py
│       └── processor.py
tests/
pyproject.toml
```

---

## 2. FastAPI Patterns

### Dependency Injection
```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        yield session

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    user = await authenticate(token, db)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user

@router.get("/me")
async def get_me(user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse.model_validate(user)
```

### Pydantic Schemas
```python
from pydantic import BaseModel, Field, EmailStr, ConfigDict

class UserBase(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)

class UserCreate(UserBase):
    password: str = Field(min_length=8)

class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    created_at: datetime
```

### Error Handling
```python
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse

class AppError(Exception):
    def __init__(self, message: str, code: str, status: int = 400):
        self.message = message
        self.code = code
        self.status = status

@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status,
        content={"error": {"code": exc.code, "message": exc.message}},
    )
```

---

## 3. Django Patterns

### Service Layer
```python
# apps/users/services.py — business logic lives here, NOT in views
class UserService:
    def __init__(self, user_repo: UserRepository | None = None):
        self.user_repo = user_repo or UserRepository()

    def create_user(self, email: str, name: str) -> User:
        if self.user_repo.exists(email=email):
            raise ValidationError("Email already exists")
        user = self.user_repo.create(email=email, name=name)
        send_welcome_email.delay(user.id)  # Celery task
        return user
```

### QuerySet Optimization
```python
# Bad: N+1 queries
for order in Order.objects.all():
    print(order.user.name)  # Each iteration hits the database

# Good: Eager loading
for order in Order.objects.select_related("user").all():
    print(order.user.name)  # Single query with JOIN

# Prefetch for many-to-many
users = User.objects.prefetch_related("orders__items").all()
```

### Custom Manager
```python
class ActiveManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)

class User(models.Model):
    objects = ActiveManager()
    all_objects = models.Manager()  # Include soft-deleted
```

---

## 4. Async Patterns

### Async Context Manager
```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def get_connection():
    conn = await pool.acquire()
    try:
        yield conn
    finally:
        await pool.release(conn)

async def fetch_user(user_id: str) -> User:
    async with get_connection() as conn:
        return await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
```

### Parallel Async Operations
```python
import asyncio

async def get_dashboard_data(user_id: str) -> DashboardData:
    # Run independent queries in parallel
    user, orders, notifications = await asyncio.gather(
        get_user(user_id),
        get_recent_orders(user_id),
        get_unread_notifications(user_id),
    )
    return DashboardData(user=user, orders=orders, notifications=notifications)
```

### Background Tasks
```python
# FastAPI background tasks
@router.post("/users")
async def create_user(
    request: CreateUserRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    user = await user_service.create(db, request)
    background_tasks.add_task(send_welcome_email, user.email)
    return UserResponse.model_validate(user)
```

---

## 5. Testing Patterns

### Factory Pattern
```python
# conftest.py
import factory
from factory.alchemy import SQLAlchemyModelFactory

class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session_persistence = "commit"

    email = factory.LazyAttribute(lambda o: f"{o.name.lower()}@example.com")
    name = factory.Faker("name")
    role = "user"

# Usage
def test_admin_can_delete_users(db_session, user_factory):
    admin = user_factory(role="admin")
    target = user_factory()
    assert delete_user(admin, target.id) is True
```

### Fixture Composition
```python
@pytest.fixture
def db_session():
    session = TestSession()
    yield session
    session.rollback()

@pytest.fixture
def user(db_session):
    return UserFactory(session=db_session)

@pytest.fixture
def authenticated_client(client, user):
    token = create_token(user)
    client.headers["Authorization"] = f"Bearer {token}"
    return client
```

### Parametrized Validation Tests
```python
@pytest.mark.parametrize("email,expected_status", [
    ("valid@example.com", 201),
    ("", 422),
    ("not-an-email", 422),
    ("a" * 256 + "@example.com", 422),
])
async def test_create_user_email_validation(client, email, expected_status):
    response = await client.post("/users", json={"email": email, "name": "Test"})
    assert response.status_code == expected_status
```

---

## 6. Type System Patterns

### Protocol for Structural Typing
```python
from typing import Protocol

class Repository(Protocol):
    async def get(self, id: str) -> Model | None: ...
    async def create(self, data: dict) -> Model: ...
    async def delete(self, id: str) -> bool: ...

# Any class implementing these methods satisfies Repository
# No explicit inheritance needed
```

### Discriminated Unions
```python
from dataclasses import dataclass
from typing import Literal

@dataclass
class Success:
    type: Literal["success"] = "success"
    data: dict

@dataclass
class Error:
    type: Literal["error"] = "error"
    message: str
    code: str

Result = Success | Error

def handle(result: Result) -> None:
    match result:
        case Success(data=data):
            process(data)
        case Error(message=msg):
            log_error(msg)
```

### Generic Types
```python
from typing import TypeVar, Generic

T = TypeVar("T")

class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    page_size: int

# Usage: PaginatedResponse[UserResponse]
```

---

## 7. Configuration Patterns

### Pydantic Settings
```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    database_url: str
    redis_url: str = "redis://localhost:6379"
    debug: bool = False
    secret_key: str
    allowed_origins: list[str] = ["http://localhost:3000"]

settings = Settings()  # Reads from environment variables / .env
```

### pyproject.toml Configuration
```toml
[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.11"

[tool.ruff]
target-version = "py311"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "A", "C4", "SIM", "TCH"]

[tool.mypy]
strict = true
plugins = ["pydantic.mypy"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

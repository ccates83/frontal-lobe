---
name: backend-patterns
description: "Backend development patterns for Go, Rust, Java/Kotlin, and C#. Covers concurrency, error handling, project structure, testing, and framework-specific conventions. Reference material for backend-orchestrator and its sub-agents."
---

# Backend Patterns — Go, Rust, Java/Kotlin & C# Reference

Quick-reference guide for compiled-language backend development. Used by the backend orchestrator ecosystem.

## When to Apply

Reference these patterns when:
- Designing backend architecture in Go, Rust, Java/Kotlin, or C#
- Implementing HTTP handlers, services, or data access layers
- Reviewing concurrency, error handling, or performance
- Writing tests for backend code

---

## 1. Go Patterns

### Project Structure (Standard Layout)
```
cmd/
├── server/
│   └── main.go           # Entry point
├── worker/
│   └── main.go           # Background worker
internal/
├── handler/              # HTTP handlers
│   ├── user.go
│   └── order.go
├── service/              # Business logic
│   ├── user.go
│   └── order.go
├── repository/           # Data access
│   ├── user.go
│   └── order.go
├── model/                # Domain types
│   └── user.go
├── middleware/            # HTTP middleware
│   ├── auth.go
│   └── logging.go
└── config/
    └── config.go
pkg/                      # Public packages (if any)
```

### Error Handling Pattern
```go
// Custom error types
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s %s not found", e.Resource, e.ID)
}

// Wrapping errors with context
func (s *UserService) GetUser(ctx context.Context, id string) (*User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("getting user %s: %w", id, err)
    }
    if user == nil {
        return nil, &NotFoundError{Resource: "user", ID: id}
    }
    return user, nil
}

// Checking error types
if errors.As(err, &NotFoundError{}) {
    http.Error(w, "not found", http.StatusNotFound)
}
```

### Graceful Shutdown
```go
func main() {
    srv := &http.Server{Addr: ":8080", Handler: router}

    go func() {
        if err := srv.ListenAndServe(); err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    srv.Shutdown(ctx)
}
```

### Concurrency Patterns
```go
// Worker pool
func processItems(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(10) // Max 10 concurrent workers

    for _, item := range items {
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }
    return g.Wait()
}

// Fan-out, fan-in
func fanOut(ctx context.Context, input <-chan Job, workers int) <-chan Result {
    results := make(chan Result)
    var wg sync.WaitGroup

    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range input {
                select {
                case results <- process(job):
                case <-ctx.Done():
                    return
                }
            }
        }()
    }

    go func() { wg.Wait(); close(results) }()
    return results
}
```

---

## 2. Rust Patterns

### Project Structure
```
src/
├── main.rs               # Entry point, server setup
├── lib.rs                # Library root (optional)
├── config.rs             # Configuration
├── routes/
│   ├── mod.rs
│   ├── users.rs
│   └── orders.rs
├── services/
│   ├── mod.rs
│   └── user_service.rs
├── models/
│   ├── mod.rs
│   └── user.rs
├── db/
│   ├── mod.rs
│   └── queries.rs
├── middleware/
│   ├── mod.rs
│   └── auth.rs
└── error.rs              # Error types
```

### Error Handling with thiserror
```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Validation error: {0}")]
    Validation(String),

    #[error("Unauthorized")]
    Unauthorized,

    #[error(transparent)]
    Database(#[from] sqlx::Error),

    #[error(transparent)]
    Internal(#[from] anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, msg.clone()),
            AppError::Validation(msg) => (StatusCode::UNPROCESSABLE_ENTITY, msg.clone()),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, "Unauthorized".into()),
            _ => (StatusCode::INTERNAL_SERVER_ERROR, "Internal error".into()),
        };
        (status, Json(json!({ "error": { "message": message } }))).into_response()
    }
}
```

### Axum Handler Pattern
```rust
async fn create_user(
    State(state): State<Arc<AppState>>,
    Json(req): Json<CreateUserRequest>,
) -> Result<(StatusCode, Json<UserResponse>), AppError> {
    req.validate()?;
    let user = state.user_service.create(req).await?;
    Ok((StatusCode::CREATED, Json(user.into())))
}

// Router setup
let app = Router::new()
    .route("/users", post(create_user).get(list_users))
    .route("/users/:id", get(get_user).put(update_user))
    .layer(middleware::from_fn_with_state(state.clone(), auth_middleware))
    .with_state(state);
```

---

## 3. Java/Kotlin Patterns

### Spring Boot Structure (Kotlin)
```
src/main/kotlin/com/example/app/
├── Application.kt
├── config/
│   ├── SecurityConfig.kt
│   └── WebConfig.kt
├── user/
│   ├── UserController.kt
│   ├── UserService.kt
│   ├── UserRepository.kt
│   ├── User.kt              # Entity
│   ├── UserDto.kt            # DTOs
│   └── UserExceptions.kt
├── order/
│   └── ...
└── common/
    ├── ErrorHandler.kt
    └── PageResponse.kt
```

### Kotlin Coroutines + Spring WebFlux
```kotlin
@RestController
@RequestMapping("/api/users")
class UserController(private val userService: UserService) {

    @GetMapping
    suspend fun list(
        @RequestParam page: Int = 0,
        @RequestParam size: Int = 20,
    ): PageResponse<UserDto> {
        return userService.findAll(page, size)
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    suspend fun create(@Valid @RequestBody request: CreateUserRequest): UserDto {
        return userService.create(request)
    }
}
```

### Global Error Handler
```kotlin
@RestControllerAdvice
class GlobalErrorHandler {
    @ExceptionHandler(NotFoundException::class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    fun handleNotFound(ex: NotFoundException) = ErrorResponse(
        code = "NOT_FOUND",
        message = ex.message ?: "Resource not found",
    )

    @ExceptionHandler(MethodArgumentNotValidException::class)
    @ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
    fun handleValidation(ex: MethodArgumentNotValidException) = ErrorResponse(
        code = "VALIDATION_ERROR",
        message = "Invalid input",
        details = ex.bindingResult.fieldErrors.associate { it.field to (it.defaultMessage ?: "Invalid") },
    )
}
```

---

## 4. C# / .NET Patterns

### Minimal API with DI
```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddDbContext<AppDbContext>(opts =>
    opts.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

var app = builder.Build();

app.MapGet("/users", async (IUserService service, CancellationToken ct) =>
    Results.Ok(await service.GetAllAsync(ct)));

app.MapPost("/users", async (CreateUserRequest req, IUserService service, CancellationToken ct) =>
{
    var user = await service.CreateAsync(req, ct);
    return Results.Created($"/users/{user.Id}", user);
});

app.Run();
```

### Repository Pattern
```csharp
public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken ct);
    Task<IReadOnlyList<User>> GetAllAsync(int page, int size, CancellationToken ct);
    Task<User> CreateAsync(User user, CancellationToken ct);
}

public class UserRepository(AppDbContext db) : IUserRepository
{
    public async Task<User?> GetByIdAsync(Guid id, CancellationToken ct)
        => await db.Users.FindAsync([id], ct);
}
```

---

## 5. Testing Patterns

### Go: Table-Driven Tests
```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name  string
        email string
        valid bool
    }{
        {"valid", "user@example.com", true},
        {"no domain", "user@", false},
        {"empty", "", false},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := ValidateEmail(tt.email)
            assert.Equal(t, tt.valid, got)
        })
    }
}
```

### Rust: Module Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn valid_email_passes() {
        assert!(validate_email("user@example.com").is_ok());
    }

    #[test]
    fn empty_email_fails() {
        assert!(validate_email("").is_err());
    }
}
```

### Kotlin: Spring Boot Integration Test
```kotlin
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
class UserApiTest(@Autowired val client: TestRestTemplate) {
    companion object {
        @Container
        val postgres = PostgreSQLContainer("postgres:16-alpine")
    }

    @Test
    fun `POST users creates a user`() {
        val response = client.postForEntity("/api/users",
            CreateUserRequest(email = "test@test.com"), UserDto::class.java)
        assertThat(response.statusCode).isEqualTo(HttpStatus.CREATED)
    }
}
```

---
name: api-patterns
description: "API design patterns, REST conventions, GraphQL schema design, gRPC service definitions, authentication flows, versioning strategies, and rate limiting. Reference material for api-orchestrator and its sub-agents."
---

# API Patterns — Design, Security & Protocol Reference

Quick-reference guide for API design and implementation. Used by the API orchestrator ecosystem.

## When to Apply

Reference these patterns when:
- Designing REST, GraphQL, or gRPC APIs
- Writing OpenAPI specifications
- Implementing authentication and authorization
- Designing pagination and filtering
- Reviewing API security and consistency

---

## 1. REST Design Patterns

### Resource Naming
```
GET    /users              # List users
POST   /users              # Create user
GET    /users/{id}         # Get user
PUT    /users/{id}         # Replace user
PATCH  /users/{id}         # Update user fields
DELETE /users/{id}         # Delete user

GET    /users/{id}/orders  # List user's orders (nested resource)
POST   /users/{id}/orders  # Create order for user

# Actions that don't map to CRUD
POST   /users/{id}/verify  # Trigger verification
POST   /orders/{id}/cancel # Cancel order
```

### HTTP Status Code Reference
| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH, DELETE |
| 201 | Created | Successful POST that created a resource |
| 204 | No Content | Successful DELETE with no response body |
| 400 | Bad Request | Malformed request (invalid JSON, missing required field) |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Authenticated but insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate resource, state conflict |
| 422 | Unprocessable Entity | Valid JSON but failed business validation |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |

### Pagination Patterns

**Cursor-Based (Recommended)**
```json
GET /users?limit=20&after=eyJpZCI6MTIzfQ

{
  "data": [...],
  "pagination": {
    "hasMore": true,
    "nextCursor": "eyJpZCI6MTQzfQ",
    "prevCursor": "eyJpZCI6MTIzfQ"
  }
}
```

**Offset-Based**
```json
GET /users?page=3&pageSize=20

{
  "data": [...],
  "pagination": {
    "total": 150,
    "page": 3,
    "pageSize": 20,
    "totalPages": 8
  }
}
```

### Filtering & Sorting
```
GET /orders?status=pending&created_after=2024-01-01&sort=-created_at&limit=20
```
- Filter by field: `?field=value`
- Date ranges: `?created_after=...&created_before=...`
- Sort: `?sort=field` (asc), `?sort=-field` (desc)
- Multiple sort: `?sort=-created_at,name`

### Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "email": ["Must be a valid email address"],
      "name": ["Required field", "Must be at least 1 character"]
    },
    "requestId": "req_abc123"
  }
}
```

---

## 2. GraphQL Patterns

### Schema Design
```graphql
type Query {
  user(id: ID!): User
  users(first: Int = 20, after: String, filter: UserFilter): UserConnection!
}

type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
  updateUser(id: ID!, input: UpdateUserInput!): UpdateUserPayload!
}

# Relay-style connection for pagination
type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

# Mutation payloads with errors
type CreateUserPayload {
  user: User
  errors: [UserError!]!
}

type UserError {
  field: String!
  message: String!
}

input UserFilter {
  role: UserRole
  searchTerm: String
}
```

### N+1 Prevention with DataLoader
```typescript
const userLoader = new DataLoader<string, User>(async (ids) => {
  const users = await db.user.findMany({ where: { id: { in: [...ids] } } })
  const userMap = new Map(users.map(u => [u.id, u]))
  return ids.map(id => userMap.get(id) ?? new Error(`User ${id} not found`))
})
```

---

## 3. Authentication Patterns

### JWT Access + Refresh Token Flow
```
1. Login: POST /auth/login → { accessToken (15min), refreshToken (7d) }
2. API calls: Authorization: Bearer {accessToken}
3. Token refresh: POST /auth/refresh { refreshToken } → { newAccessToken, newRefreshToken }
4. Logout: POST /auth/logout → invalidate refresh token

Access token: Short-lived, stateless, in memory (not localStorage)
Refresh token: Long-lived, stored in httpOnly cookie, rotated on use
```

### OAuth 2.0 + PKCE (for SPAs/mobile)
```
1. Generate code_verifier (random string) and code_challenge (SHA256 hash)
2. Redirect to: /authorize?response_type=code&code_challenge={hash}&code_challenge_method=S256
3. User authenticates, redirect back with authorization code
4. Exchange code + code_verifier for tokens: POST /token
```

### API Key Authentication
```
Authorization: Bearer sk_live_abc123def456

// Or in header
X-API-Key: sk_live_abc123def456
```
- Prefix keys with environment: `sk_live_`, `sk_test_`
- Hash keys before storing (bcrypt or SHA256)
- Support key rotation (multiple active keys per account)

---

## 4. Rate Limiting Patterns

### Token Bucket Algorithm
```
Bucket capacity: 100 tokens
Refill rate: 10 tokens/second

Request arrives:
  - Tokens available? → Allow, decrement by 1
  - No tokens? → Reject with 429 + Retry-After header
```

### Rate Limit Headers
```
X-RateLimit-Limit: 100         # Max requests per window
X-RateLimit-Remaining: 87      # Requests remaining
X-RateLimit-Reset: 1640995200  # Window reset (Unix timestamp)
Retry-After: 30                # Seconds to wait (on 429)
```

### Tiered Rate Limits
| Tier | Rate | Burst | Scope |
|------|------|-------|-------|
| Anonymous | 60/hour | 10/minute | Per IP |
| Authenticated | 1000/hour | 100/minute | Per user |
| Premium | 10000/hour | 1000/minute | Per API key |

---

## 5. Versioning Patterns

### URL Versioning (Most Common)
```
/v1/users
/v2/users
```
- Simple, explicit, easy to route
- Use when major breaking changes happen

### Header Versioning
```
Accept: application/vnd.myapi.v2+json
```
- Cleaner URLs, but harder to test/debug

### Sunset Process
```
1. Announce deprecation (Sunset header, changelog, email)
2. Add Deprecation and Sunset headers to old version
3. Provide migration guide
4. Monitor old version usage
5. Remove after sunset date
```

```
Deprecation: true
Sunset: Sat, 01 Mar 2025 00:00:00 GMT
Link: <https://api.example.com/docs/migration>; rel="successor-version"
```

---

## 6. OpenAPI Quick Reference

```yaml
openapi: '3.1.0'
info:
  title: My API
  version: '1.0.0'
  description: API description
servers:
  - url: https://api.example.com/v1

paths:
  /users:
    get:
      summary: List users
      operationId: listUsers
      tags: [Users]
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
      security:
        - bearerAuth: []

components:
  schemas:
    User:
      type: object
      required: [id, email, name]
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
          format: email
        name:
          type: string
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

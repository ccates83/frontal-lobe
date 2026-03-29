---
name: data-patterns
description: "Database design patterns, SQL optimization, migration strategies, caching patterns, and data pipeline conventions. Reference material for data-planner, data-architect, data-builder, and data-reviewer agents."
---

# Data Patterns — Schema Design, Query Optimization & Pipeline Reference

Quick-reference guide for data engineering. Used by the data planner ecosystem.

## When to Apply

Reference these patterns when:
- Designing database schemas and data models
- Writing or reviewing SQL queries and migrations
- Optimizing query performance
- Designing caching strategies
- Building data pipelines

---

## 1. Schema Design Patterns

### Standard Table Template (PostgreSQL)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,  -- soft delete

    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_role_check CHECK (role IN ('user', 'admin', 'moderator'))
);

-- Partial index: only active users
CREATE INDEX idx_users_email_active ON users (email) WHERE deleted_at IS NULL;

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Relationship Patterns
```sql
-- One-to-many: FK on the "many" side
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Always index foreign keys in PostgreSQL
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_orders_user_id ON orders (user_id);

-- Many-to-many: junction table
CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- Polymorphic (prefer this over type+id pattern)
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    body TEXT NOT NULL,
    post_id UUID REFERENCES posts(id),      -- nullable
    article_id UUID REFERENCES articles(id), -- nullable
    CONSTRAINT comments_one_parent CHECK (
        (post_id IS NOT NULL)::int + (article_id IS NOT NULL)::int = 1
    )
);
```

---

## 2. Indexing Strategy

### Index Selection Guide
| Query Pattern | Index Type | Example |
|---|---|---|
| Equality (`WHERE x = ?`) | B-tree (default) | `CREATE INDEX ON users (email)` |
| Range (`WHERE x > ?`) | B-tree | `CREATE INDEX ON orders (created_at)` |
| Full-text search | GIN | `CREATE INDEX ON posts USING GIN (to_tsvector('english', body))` |
| JSONB containment | GIN | `CREATE INDEX ON events USING GIN (metadata)` |
| Array contains | GIN | `CREATE INDEX ON posts USING GIN (tags)` |
| Time-series (large tables) | BRIN | `CREATE INDEX ON logs USING BRIN (timestamp)` |
| Pattern matching | GIN + pg_trgm | `CREATE INDEX ON users USING GIN (name gin_trgm_ops)` |

### Composite Index Rules
```sql
-- Column order matters: match WHERE clause order, most selective first
-- For: WHERE status = 'active' AND created_at > '2024-01-01'
CREATE INDEX idx_orders_status_created ON orders (status, created_at);

-- Covers the query if SELECT only uses indexed columns
-- For: SELECT id, email FROM users WHERE email = ?
CREATE INDEX idx_users_email_covering ON users (email) INCLUDE (id);
```

---

## 3. Migration Safety

### Non-Locking Migrations (PostgreSQL)
```sql
-- Safe: Add nullable column (instant, no lock)
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Safe: Create index concurrently (no lock)
CREATE INDEX CONCURRENTLY idx_users_phone ON users (phone);

-- DANGEROUS: Add column with default (locks table, rewrites all rows in PG < 11)
-- In PG 11+, this is safe for non-volatile defaults
ALTER TABLE users ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active';

-- DANGEROUS: Add NOT NULL to existing column (must scan all rows)
-- Safe alternative: Add check constraint with NOT VALID, then validate separately
ALTER TABLE users ADD CONSTRAINT users_phone_not_null CHECK (phone IS NOT NULL) NOT VALID;
ALTER TABLE users VALIDATE CONSTRAINT users_phone_not_null;
```

### Multi-Step Column Migration
```
Step 1: Add new column (nullable)
Step 2: Deploy code that writes to both old and new columns
Step 3: Backfill new column from old column
Step 4: Deploy code that reads from new column
Step 5: Add NOT NULL constraint on new column
Step 6: Deploy code that stops writing to old column
Step 7: Drop old column
```

---

## 4. Query Optimization

### EXPLAIN ANALYZE Reading
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.name, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id;
```

Key things to look for:
- **Seq Scan** on large tables → needs an index
- **Nested Loop** with high row counts → consider Hash Join (add index or restructure)
- **Sort** with high cost → add index matching ORDER BY
- **Buffers: shared hit** vs **shared read** → cache hit ratio

### Common Query Optimizations
```sql
-- Bad: SELECT * (fetches unnecessary columns)
SELECT * FROM users WHERE id = $1;
-- Good: Select only needed columns
SELECT id, email, name FROM users WHERE id = $1;

-- Bad: N+1 in application code
-- for user in users: query orders where user_id = user.id
-- Good: Single query with JOIN
SELECT u.id, u.name, COUNT(o.id)
FROM users u LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id;

-- Bad: OFFSET pagination on large tables (scans skipped rows)
SELECT * FROM orders ORDER BY created_at DESC LIMIT 20 OFFSET 10000;
-- Good: Cursor/keyset pagination
SELECT * FROM orders
WHERE created_at < $cursor_timestamp
ORDER BY created_at DESC LIMIT 20;
```

---

## 5. Caching Patterns

### Cache-Aside (Lazy Loading)
```
Read: App → Cache → hit? return : DB → populate cache → return
Write: App → DB → invalidate cache
```

### Key Naming Convention
```
{app}:{entity}:{id}:{field}
myapp:user:123:profile
myapp:user:123:orders:page:1
myapp:feed:global:latest
```

### Redis Data Structure Selection
| Use Case | Data Structure | Example |
|---|---|---|
| Simple KV cache | String | `SET user:123:name "Alice"` |
| Object cache | Hash | `HSET user:123 name "Alice" email "a@b.com"` |
| Unique membership | Set | `SADD user:123:roles "admin" "editor"` |
| Leaderboard/ranking | Sorted Set | `ZADD leaderboard 1500 "user:123"` |
| Recent items (bounded) | List + LTRIM | `LPUSH recent:user:123 item_id` |
| Rate limiting | String + TTL | `INCR ratelimit:ip:1.2.3.4` + `EXPIRE` |
| Distributed lock | String + NX | `SET lock:resource NX EX 30` |

---

## 6. Data Pipeline Patterns (dbt)

### Model Layers
```
sources → staging → intermediate → marts
```

- **Staging**: 1:1 with source tables, rename columns, cast types, no joins
- **Intermediate**: Business logic transformations, joins, aggregations
- **Marts**: Final tables for consumption (dashboards, APIs, exports)

### dbt Model Example
```sql
-- models/staging/stg_orders.sql
WITH source AS (
    SELECT * FROM {{ source('raw', 'orders') }}
)
SELECT
    id AS order_id,
    user_id,
    CAST(total_cents AS DECIMAL) / 100 AS total_amount,
    status,
    created_at::timestamptz AS ordered_at
FROM source
WHERE _deleted = false
```

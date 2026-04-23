---
name: web-patterns
description: "Modern web development patterns, component architecture, performance optimization, accessibility standards, and security best practices. Reference material for web-planner, web-architect, web-builder, web-reviewer, and web-tester agents."
compatibility: cursor
---
# Web Patterns — Architecture, Performance & Accessibility Reference

Quick-reference guide for modern web development. Used by the web planner ecosystem to produce consistent, high-quality web applications.

## When to Apply

Reference these patterns when:
- Designing web application architecture
- Implementing components, pages, or API routes
- Reviewing code for performance, accessibility, or security
- Choosing between SSR/SSG/CSR rendering strategies
- Setting up a new web project or feature

---

## 1. Component Architecture Patterns

### Composition Pattern (React)
```tsx
// Prefer composition over configuration props
// Bad: <Card variant="image" title="..." image="..." description="..." />
// Good:
<Card>
  <Card.Image src="..." alt="..." />
  <Card.Title>...</Card.Title>
  <Card.Description>...</Card.Description>
</Card>
```

### Container/Presentational Split
```
Container (data fetching, state management, side effects)
└── Presentational (pure UI, receives props, no side effects)
```
- In Next.js App Router: Server Components are natural containers, Client Components are presentational
- In SPAs: Custom hooks are containers, components are presentational

### Render Props / Children as Function
```tsx
<DataLoader url="/api/users">
  {({ data, loading, error }) => (
    loading ? <Spinner /> : <UserList users={data} />
  )}
</DataLoader>
```
Use sparingly — hooks are usually a better abstraction in modern React.

### Compound Components
```tsx
// Parent manages shared state, children consume via context
<Tabs defaultValue="tab1">
  <Tabs.List>
    <Tabs.Trigger value="tab1">Tab 1</Tabs.Trigger>
    <Tabs.Trigger value="tab2">Tab 2</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Content value="tab1">Content 1</Tabs.Content>
  <Tabs.Content value="tab2">Content 2</Tabs.Content>
</Tabs>
```

### Custom Hook Patterns
```tsx
// Encapsulate related state + logic
function usePagination({ totalItems, pageSize = 10 }) {
  const [page, setPage] = useState(1)
  const totalPages = Math.ceil(totalItems / pageSize)
  const offset = (page - 1) * pageSize

  return {
    page,
    totalPages,
    offset,
    pageSize,
    nextPage: () => setPage(p => Math.min(p + 1, totalPages)),
    prevPage: () => setPage(p => Math.max(p - 1, 1)),
    goToPage: setPage,
  }
}
```

---

## 2. Data Fetching Patterns

### Server Component Fetching (Next.js)
```tsx
// app/users/page.tsx — Server Component, no client JS
async function UsersPage() {
  const users = await db.user.findMany()
  return <UserList users={users} />
}
```

### Parallel Data Fetching
```tsx
// Fetch in parallel, not sequentially
async function Dashboard() {
  const [users, orders, stats] = await Promise.all([
    getUsers(),
    getOrders(),
    getStats(),
  ])
  return <DashboardView users={users} orders={orders} stats={stats} />
}
```

### Streaming with Suspense
```tsx
// Stream slow data without blocking the page
export default function Page() {
  return (
    <main>
      <h1>Dashboard</h1>
      <Suspense fallback={<ChartSkeleton />}>
        <SlowChart />
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <SlowTable />
      </Suspense>
    </main>
  )
}
```

### Client-Side with TanStack Query
```tsx
function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}
```

### Optimistic Updates
```tsx
// Show the result immediately, reconcile with server response
const mutation = useMutation({
  mutationFn: updateTodo,
  onMutate: async (newTodo) => {
    await queryClient.cancelQueries({ queryKey: ['todos'] })
    const previous = queryClient.getQueryData(['todos'])
    queryClient.setQueryData(['todos'], old => [...old, newTodo])
    return { previous }
  },
  onError: (err, newTodo, context) => {
    queryClient.setQueryData(['todos'], context.previous)
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['todos'] })
  },
})
```

---

## 3. Routing & Navigation Patterns

### Next.js App Router File Conventions
```
app/
├── layout.tsx            # Root layout (wraps all routes)
├── page.tsx              # Home page (/)
├── loading.tsx           # Loading UI (Suspense boundary)
├── error.tsx             # Error boundary
├── not-found.tsx         # 404 page
├── (marketing)/          # Route group (no URL impact)
│   ├── layout.tsx        # Marketing layout
│   ├── about/page.tsx    # /about
│   └── pricing/page.tsx  # /pricing
├── (app)/                # Route group for authenticated area
│   ├── layout.tsx        # App layout with sidebar
│   └── dashboard/
│       ├── page.tsx      # /dashboard
│       └── @analytics/   # Parallel route (named slot)
│           └── page.tsx
├── api/
│   └── users/
│       └── route.ts      # GET/POST /api/users
└── [...slug]/
    └── page.tsx          # Catch-all route
```

### Dynamic Routes with Type Safety
```tsx
// app/users/[id]/page.tsx
type Props = { params: Promise<{ id: string }> }

export default async function UserPage({ params }: Props) {
  const { id } = await params
  const user = await getUser(id)
  if (!user) notFound()
  return <UserProfile user={user} />
}
```

---

## 4. Form Patterns

### Server Actions (Next.js)
```tsx
// actions.ts
'use server'

import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
})

export async function createUser(formData: FormData) {
  const result = schema.safeParse(Object.fromEntries(formData))
  if (!result.success) {
    return { error: result.error.flatten().fieldErrors }
  }
  await db.user.create({ data: result.data })
  revalidatePath('/users')
}
```

### Progressive Enhancement Pattern
```tsx
// Works without JavaScript, enhanced with JavaScript
function ContactForm() {
  const [state, formAction] = useActionState(submitContact, null)

  return (
    <form action={formAction}>
      <input name="email" type="email" required />
      {state?.error && <p role="alert">{state.error}</p>}
      <SubmitButton />
    </form>
  )
}

function SubmitButton() {
  const { pending } = useFormStatus()
  return <button disabled={pending}>{pending ? 'Sending...' : 'Send'}</button>
}
```

---

## 5. Performance Patterns

### Image Optimization
```tsx
// Next.js
import Image from 'next/image'

// Hero image — above the fold
<Image src="/hero.jpg" alt="..." width={1200} height={600} priority sizes="100vw" />

// Thumbnail — lazy loaded
<Image src="/thumb.jpg" alt="..." width={300} height={200} sizes="(max-width: 768px) 100vw, 300px" />
```

### Code Splitting
```tsx
// Route-level (automatic in Next.js/SvelteKit)
// Component-level (manual)
const HeavyChart = lazy(() => import('./HeavyChart'))

function Dashboard() {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart />
    </Suspense>
  )
}
```

### Virtualization for Long Lists
```tsx
// Use @tanstack/react-virtual for lists > 100 items
import { useVirtualizer } from '@tanstack/react-virtual'

function VirtualList({ items }) {
  const parentRef = useRef(null)
  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
  })
  // ... render only visible items
}
```

### Debouncing User Input
```tsx
// Debounce search input to avoid excessive API calls
function SearchInput() {
  const [query, setQuery] = useState('')
  const debouncedQuery = useDebouncedValue(query, 300)

  useEffect(() => {
    if (debouncedQuery) searchAPI(debouncedQuery)
  }, [debouncedQuery])

  return <input value={query} onChange={e => setQuery(e.target.value)} />
}
```

---

## 6. Accessibility Patterns

### Semantic HTML Mapping
| UI Element | Correct HTML | NOT This |
|------------|-------------|----------|
| Clickable action | `<button>` | `<div onClick>` |
| Navigation link | `<a href>` | `<span onClick>` |
| Page navigation | `<nav>` | `<div class="nav">` |
| Main content | `<main>` | `<div class="main">` |
| Section with heading | `<section>` | `<div>` |
| Sidebar | `<aside>` | `<div class="sidebar">` |
| List of items | `<ul>/<ol>` | `<div>` with styled items |
| Data comparison | `<table>` | CSS grid divs |
| Form group | `<fieldset>` + `<legend>` | `<div>` |

### Modal / Dialog Pattern
```tsx
function Modal({ isOpen, onClose, title, children }) {
  const dialogRef = useRef(null)

  useEffect(() => {
    if (isOpen) dialogRef.current?.showModal()
    else dialogRef.current?.close()
  }, [isOpen])

  return (
    <dialog ref={dialogRef} onClose={onClose} aria-labelledby="modal-title">
      <h2 id="modal-title">{title}</h2>
      {children}
      <button onClick={onClose}>Close</button>
    </dialog>
  )
}
```

### Skip Navigation
```tsx
// First focusable element on the page
<a href="#main-content" className="sr-only focus:not-sr-only focus:absolute ...">
  Skip to main content
</a>
// ... navigation ...
<main id="main-content" tabIndex={-1}>
```

### Announce Dynamic Content
```tsx
// Screen reader announcements for async updates
<div aria-live="polite" aria-atomic="true" className="sr-only">
  {loading ? 'Loading results...' : `${results.length} results found`}
</div>
```

---

## 7. Error Handling Patterns

### Error Boundary (React)
```tsx
// app/dashboard/error.tsx (Next.js)
'use client'

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div role="alert">
      <h2>Something went wrong</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  )
}
```

### API Error Handling
```typescript
// Consistent error shape
type ApiResponse<T> = { data: T; error: null } | { data: null; error: ApiError }

type ApiError = {
  message: string
  code: string
  status: number
  details?: Record<string, string[]> // field-level validation errors
}

// Throw typed errors
class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public status: number,
    public details?: Record<string, string[]>
  ) {
    super(message)
  }
}
```

---

## 8. Security Patterns

### Input Validation at Boundaries
```typescript
// API route — validate everything from the outside world
import { z } from 'zod'

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin']),
})

export async function POST(req: Request) {
  const body = CreateUserSchema.safeParse(await req.json())
  if (!body.success) {
    return Response.json({ error: body.error.flatten() }, { status: 422 })
  }
  // body.data is now typed and validated
}
```

### Authentication Middleware Pattern
```typescript
// Reusable auth check for API routes
function withAuth(handler: AuthenticatedHandler) {
  return async (req: Request) => {
    const session = await getSession(req)
    if (!session) {
      return Response.json({ error: { message: 'Unauthorized', code: 'UNAUTHORIZED' } }, { status: 401 })
    }
    return handler(req, session)
  }
}
```

### Environment Variable Safety
```typescript
// Validate env at startup, not at usage
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  // NEXT_PUBLIC_* are safe to expose
  NEXT_PUBLIC_APP_URL: z.string().url(),
})

export const env = envSchema.parse(process.env)
```

---

## 9. Testing Patterns

### Component Test Pattern
```tsx
it('shows validation error when email is invalid', async () => {
  const user = userEvent.setup()
  render(<SignUpForm />)

  await user.type(screen.getByLabelText('Email'), 'not-an-email')
  await user.click(screen.getByRole('button', { name: 'Sign up' }))

  expect(screen.getByRole('alert')).toHaveTextContent('Invalid email')
})
```

### API Route Test Pattern
```typescript
it('returns 422 for invalid input', async () => {
  const req = new Request('http://localhost/api/users', {
    method: 'POST',
    body: JSON.stringify({ email: 'invalid' }),
  })

  const res = await POST(req)
  expect(res.status).toBe(422)

  const body = await res.json()
  expect(body.error.fieldErrors.email).toBeDefined()
})
```

### MSW for API Mocking
```typescript
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'

const server = setupServer(
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: '1', name: 'Alice' },
      { id: '2', name: 'Bob' },
    ])
  })
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

---

## 10. Project Structure Patterns

### Feature-Based (Recommended)
```
src/
├── app/                    # Routes (Next.js App Router)
│   ├── (marketing)/
│   │   ├── page.tsx
│   │   └── layout.tsx
│   └── (app)/
│       ├── dashboard/
│       │   ├── page.tsx
│       │   ├── loading.tsx
│       │   └── _components/  # Route-specific components
│       └── settings/
├── components/             # Shared UI components
│   ├── ui/                 # Primitives (Button, Input, Card)
│   └── layout/             # Layout components (Header, Footer, Sidebar)
├── lib/                    # Shared utilities
│   ├── db.ts               # Database client
│   ├── auth.ts             # Auth utilities
│   └── utils.ts            # General utilities
├── hooks/                  # Shared custom hooks
├── types/                  # Shared TypeScript types
└── styles/                 # Global styles, theme
```

### Monorepo (Turborepo/Nx)
```
apps/
├── web/                    # Next.js frontend
├── api/                    # Express/Fastify API
└── admin/                  # Admin dashboard
packages/
├── ui/                     # Shared component library
├── db/                     # Database schema & client
├── auth/                   # Shared auth utilities
├── config-eslint/          # Shared ESLint config
└── config-typescript/      # Shared tsconfig
```

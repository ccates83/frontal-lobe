---
name: devops-patterns
description: "DevOps and infrastructure patterns: Docker best practices, Kubernetes configurations, Terraform module design, monitoring setup, security hardening, and cloud architecture. Reference material for devops-planner, devops-architect, devops-builder, and devops-reviewer agents."
compatibility: opencode
---
# DevOps Patterns — Infrastructure, Containers & Cloud Reference

Quick-reference guide for infrastructure and operations. Used by the DevOps planner ecosystem.

## When to Apply

Reference these patterns when:
- Designing cloud infrastructure architecture
- Writing Dockerfiles, K8s manifests, or Terraform
- Reviewing infrastructure for security and reliability
- Setting up monitoring, alerting, and observability
- Planning deployments and migrations

---

## 1. Docker Patterns

### Multi-Stage Build (Node.js)
```dockerfile
FROM node:20-slim AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:20-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

### Multi-Stage Build (Go)
```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/server ./cmd/server

FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /server
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### .dockerignore
```
.git
.github
node_modules
*.md
.env*
docker-compose*.yml
Dockerfile*
.dockerignore
tests/
coverage/
```

---

## 2. Kubernetes Patterns

### Production-Ready Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: api
    spec:
      serviceAccountName: api
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: api
          image: myapp/api:1.2.3  # Never :latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: api-secrets
                  key: database-url
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### Network Policy (Deny All + Allow Specific)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes: [Ingress, Egress]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: ingress-nginx
      ports:
        - port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - port: 5432
    - to:  # DNS
        - namespaceSelector: {}
      ports:
        - port: 53
          protocol: UDP
```

---

## 3. Terraform Patterns

### Module Structure
```hcl
# modules/ecs-service/main.tf
resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  tags = var.tags
}

# modules/ecs-service/variables.tf
variable "name" {
  type        = string
  description = "Service name"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
```

### State Management
```hcl
# environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

---

## 4. Monitoring Patterns

### The Four Golden Signals
1. **Latency**: Time to serve a request (p50, p95, p99)
2. **Traffic**: Requests per second
3. **Errors**: Error rate (5xx, 4xx separately)
4. **Saturation**: CPU, memory, disk, connection pool utilization

### Alerting Philosophy
- **Page** (wake someone up): User-facing symptoms — error rate spike, latency > SLO, service down
- **Ticket** (fix during business hours): Causes — disk 80%, certificate expiring in 7 days, dependency deprecated
- **Log** (investigate later): Information — deployment completed, scaling event, config change

### Prometheus Alert Example
```yaml
groups:
  - name: api-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "High error rate ({{ $value | humanizePercentage }})"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 10m
        labels:
          severity: ticket
        annotations:
          summary: "P95 latency above 1s"
```

---

## 5. Security Checklist

### Container Security
- [ ] Non-root user in Dockerfile
- [ ] Minimal base image (distroless, alpine, slim)
- [ ] No secrets in image layers
- [ ] Image scanning in CI (Trivy, Grype)
- [ ] Read-only root filesystem where possible
- [ ] No privileged containers

### Kubernetes Security
- [ ] RBAC with least privilege
- [ ] Network policies (deny-all default)
- [ ] Pod security standards (restricted)
- [ ] Secrets from external secret manager
- [ ] Resource limits on all containers
- [ ] Service mesh for mTLS (if needed)

### Cloud Security
- [ ] No wildcard IAM permissions
- [ ] Encryption at rest (KMS)
- [ ] TLS everywhere
- [ ] VPC with private subnets for data stores
- [ ] Security groups: deny-all default, allow specific
- [ ] Audit logging enabled (CloudTrail)
- [ ] MFA for human access

---

## 6. Deployment Strategies

| Strategy | Risk | Rollback Speed | Use When |
|----------|------|----------------|----------|
| Rolling update | Low | Medium | Default for most services |
| Blue-green | Low | Instant (switch LB) | Need instant rollback |
| Canary | Very low | Fast (route away) | High-risk changes, gradual rollout |
| Recreate | High | Slow | Incompatible versions, database migrations |

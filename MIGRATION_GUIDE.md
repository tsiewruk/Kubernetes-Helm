# Migration Guide to Kubernetes Common Library

This guide will help you migrate existing projects to use the `kubernetes-common-library`.

## Step 1: Project Preparation

### 1.1 Add dependency to Chart.yaml

Edit the `Chart.yaml` file in your project:

```yaml
apiVersion: v2
name: your-existing-project
description: Your project description
type: application
version: 0.1.0
appVersion: "1.0"

# Add this section
dependencies:
- name: kubernetes-common-library
  version: "1.0.0"
  repository: "file://../common"
```

### 1.2 Update dependencies

```bash
cd your-project
helm dependency build
```

## Step 2: Template Migration

### 2.1 Replace existing templates

Instead of copying templates from `common/templates`, replace the content of your files:

**templates/namespace.yaml:**
```yaml
{{ include "common.namespace" . }}
```

**templates/serviceaccount.yaml:**
```yaml
{{ include "common.serviceaccount" . }}
```

**templates/deployment.yaml:**
```yaml
{{ include "common.deployment" . }}
```

**templates/service.yaml:**
```yaml
{{ include "common.service" . }}
```

**templates/ingress.yaml:**
```yaml
{{ include "common.ingress" . }}
```

**templates/hpa.yaml:**
```yaml
{{ include "common.hpa" . }}
```

**templates/networkpolicy.yaml:**
```yaml
{{ include "common.networkpolicy" . }}
```

### 2.2 Remove unnecessary files

Remove copied templates from the `templates/` folder if they exist:

```bash
# Remove only if they are copies from common/templates
rm templates/cronjob.yaml  # if not using
rm templates/job.yaml      # if not using
```

## Step 3: Update values.yaml

### 3.1 Add required sections

Make sure your `values.yaml` contains all required sections:

```yaml
# Basic configuration
namespace: your-namespace

image:
  repository: your-image
  tag: "your-tag"
  pullPolicy: IfNotPresent

containerPort: 8080  # your application port

# Deployment strategy
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%
    maxUnavailable: 25%

# Service
service:
  enabled: true
  type: ClusterIP
  port: 80
  targetPort: 8080

# ServiceAccount
serviceAccount:
  create: true
  name: your-app-sa

# Security Context
securityContext:
  enabled: true
  pod:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  container:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
      - ALL

# Probes
livenessProbe:
  enabled: true
  path: /healthz
  port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  enabled: true
  path: /readyz
  port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

# Resources
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"

# Autoscaling
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  cpu:
    enabled: true
    averageUtilization: 70
  memory:
    enabled: false

# Ingress
ingress:
  enabled: true
  className: "nginx"
  annotations: {}
  hosts:
  - host: your-app.local
    paths:
    - path: /
      pathType: Prefix
  tls: []

# Network Policy
networkPolicy:
  enabled: true
  ingress:
    fromNamespaces:
    - kube-system
    fromCIDRs:
    - 10.0.0.0/8
  egress:
    enabled: false

# Optional sections (set enabled: false if not using)
affinity:
  podAffinity:
    enabled: false
  nodeAffinity:
    enabled: false

volumes:
  enabled: false

initContainers:
  enabled: false

sidecars:
  enabled: false

# Labels
labels:
  environment: production
  team: your-team
```

## Step 4: Testing

### 4.1 Check template generation

```bash
cd your-project
helm template . > test-output.yaml
```

### 4.2 Compare with previous version

```bash
# Generate templates before migration (if you have backup)
helm template . --values old-values.yaml > old-output.yaml

# Compare
diff old-output.yaml test-output.yaml
```

### 4.3 Test in dev environment

```bash
# Using helmfile
helmfile -e dev template

# Or directly with helm
helm install your-app . --namespace your-namespace --dry-run
```

## Step 5: Deployment

### 5.1 Update existing deployment

```bash
# Using helmfile
helmfile -e production apply

# Or directly with helm
helm upgrade your-app . --namespace your-namespace
```

## Migration Examples

### Project with simple web application

**Before:**
```
your-project/
├── templates/
│   ├── deployment.yaml    # 150 lines copied
│   ├── service.yaml       # 30 lines copied
│   ├── ingress.yaml       # 40 lines copied
│   └── ...
├── values.yaml
└── Chart.yaml
```

**After:**
```
your-project/
├── templates/
│   ├── deployment.yaml    # 1 line: {{ include "common.deployment" . }}
│   ├── service.yaml       # 1 line: {{ include "common.service" . }}
│   ├── ingress.yaml       # 1 line: {{ include "common.ingress" . }}
│   └── ...
├── values.yaml            # configuration only
├── Chart.yaml             # with dependency
└── charts/                # automatically generated
```

## Troubleshooting

### Problem: "template: no template associated with template"

**Cause:** Library was not loaded correctly.

**Solution:**
```bash
rm -rf charts Chart.lock
helm dependency build
```

### Problem: "nil pointer evaluating interface"

**Cause:** Missing required values in `values.yaml`.

**Solution:** Add missing sections according to step 3.1.

### Problem: Different values in generated templates

**Cause:** Differences in values.yaml configuration.

**Solution:** Compare and adjust values in `values.yaml`.

## Benefits After Migration

1. **~90% code reduction** - templates are now single lines
2. **Automatic updates** - library changes affect all projects
3. **Standardization** - all projects use the same patterns
4. **Easier maintenance** - single source of truth for templates
5. **Faster new project creation** - only values.yaml configuration needed

## Next Steps

After successful migration:

1. Remove old copied templates from other projects
2. Update team documentation
3. Migrate remaining projects
4. Consider adding new templates to the library (ConfigMap, Secret, etc.)

## Adding New Templates to Library

1. Create a new named template in `common/templates/_helpers.tpl`
2. Use the format:
```yaml
{{/*
Description of template
Usage: {{ include "common.templatename" . }}
*/}}
{{- define "common.templatename" -}}
# Your template content here
{{- end -}}
```
3. Update version in `Chart.yaml`
4. Update documentation 
# Kubernetes Common Library

Helm library containing common Kubernetes templates that can be imported and used in different projects.

## Available Templates

### Basic Components
- `common.namespace` - Namespace
- `common.serviceaccount` - ServiceAccount
- `common.deployment` - Deployment
- `common.service` - Service
- `common.ingress` - Ingress

### Scaling and Management
- `common.hpa` - HorizontalPodAutoscaler
- `common.cronjob` - CronJob
- `common.job` - Job

### Security
- `common.networkpolicy` - NetworkPolicy

## How to Use

### 1. Add dependency to Chart.yaml

```yaml
apiVersion: v2
name: your-app
description: Your application
type: application
version: 0.1.0
appVersion: "1.0"

dependencies:
- name: kubernetes-common-library
  version: "1.0.0"
  repository: "file://../common"  # or path to library
```

### 2. Update dependencies

```bash
helm dependency update
```

### 3. Use templates in your files

Create files in your project's `templates/` folder:

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

### 4. Configure values.yaml

```yaml
# Basic configuration
namespace: my-app

image:
  repository: my-app
  tag: "1.0.0"
  pullPolicy: IfNotPresent

containerPort: 8080

# Service
service:
  enabled: true
  type: ClusterIP
  port: 80
  targetPort: 8080

# Ingress
ingress:
  enabled: true
  className: "nginx"
  hosts:
  - host: my-app.local
    paths:
    - path: /
      pathType: Prefix

# ServiceAccount
serviceAccount:
  create: true
  name: my-app-sa

# Autoscaling
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  cpu:
    enabled: true
    averageUtilization: 70

# Security
securityContext:
  enabled: true
  pod:
    runAsNonRoot: true
    runAsUser: 1000
  container:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true

# Network Policy
networkPolicy:
  enabled: true
  ingress:
    fromNamespaces:
    - kube-system
    fromCIDRs:
    - 10.0.0.0/8
```

## Complete Project Example

See the `example-app/` folder for a complete example of using the library.

## Benefits

1. **No code duplication** - templates are defined once and used multiple times
2. **Easy updates** - library changes automatically affect all projects
3. **Standardization** - all projects use the same patterns
4. **Simplicity** - new projects only require values.yaml configuration
5. **Flexibility** - each project can override default values

## Library Updates

To update the library in an existing project:

```bash
cd your-project
helm dependency update
```

## Adding New Templates

1. Create a new file in `common/templates/`
2. Use named template format:
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
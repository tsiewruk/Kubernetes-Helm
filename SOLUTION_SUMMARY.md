# Solution: Kubernetes Common Templates Library

## Problem
Kubernetes templates from the `shared/common` folder had to be copied to each new project, which caused:
- Code duplication
- Difficulties in updating templates
- Lack of standardization between projects
- Increased risk of errors

## Solution
Transform `shared/common` into a Helm library with `include` mechanism for importing templates.

## Implementation

### 1. Helm Library (`common/templates/`)
```
common/templates/
├── Chart.yaml              # type: library
├── values.yaml             # default values
├── README.md               # documentation
└── templates/
    ├── _helpers.tpl        # all named templates
    ├── deployment.yaml     # {{ define "common.deployment" }}
    ├── service.yaml        # {{ define "common.service" }}
    ├── ingress.yaml        # {{ define "common.ingress" }}
    ├── namespace.yaml      # {{ define "common.namespace" }}
    ├── serviceaccount.yaml # {{ define "common.serviceaccount" }}
    ├── hpa.yaml           # {{ define "common.hpa" }}
    └── networkpolicy.yaml  # {{ define "common.networkpolicy" }}
```

### 2. Usage in Projects
**Chart.yaml:**
```yaml
dependencies:
- name: kubernetes-common-library
  version: "1.0.0"
  repository: "file://../common/templates"
```

**templates/deployment.yaml:**
```yaml
{{ include "common.deployment" . }}
```

### 3. Working Project Example (`example-app/`)
Complete example showing how to use the library.

## Available Templates

| Template | Usage | Description |
|----------|-------|-------------|
| `common.namespace` | `{{ include "common.namespace" . }}` | Namespace |
| `common.serviceaccount` | `{{ include "common.serviceaccount" . }}` | ServiceAccount |
| `common.deployment` | `{{ include "common.deployment" . }}` | Deployment with full configuration |
| `common.service` | `{{ include "common.service" . }}` | Service |
| `common.ingress` | `{{ include "common.ingress" . }}` | Ingress |
| `common.hpa` | `{{ include "common.hpa" . }}` | HorizontalPodAutoscaler |
| `common.networkpolicy` | `{{ include "common.networkpolicy" . }}` | NetworkPolicy |

## Benefits

### Before solution:
```
project/
├── templates/
│   ├── deployment.yaml    # 150 lines copied
│   ├── service.yaml       # 30 lines copied
│   ├── ingress.yaml       # 40 lines copied
│   └── ...                # ~300 lines of duplication
```

### After solution:
```
project/
├── Chart.yaml             # + dependency
├── templates/
│   ├── deployment.yaml    # 1 line: {{ include "common.deployment" . }}
│   ├── service.yaml       # 1 line: {{ include "common.service" . }}
│   ├── ingress.yaml       # 1 line: {{ include "common.ingress" . }}
│   └── ...                # ~7 lines total
└── charts/                # automatically managed
```

### Code reduction: **~95%**

## How to Use

### New project:
1. Copy `example-app/` as template
2. Adjust `values.yaml` to your needs
3. Run `helm dependency build`
4. Ready!

### Migrating existing project:
1. Add dependency to `Chart.yaml`
2. Replace templates with `{{ include "common.xxx" . }}` calls
3. Adjust `values.yaml`
4. Test and deploy

## Testing

```bash
cd example-app
helm dependency build
helm template .
```

Generates 188 lines of correct Kubernetes manifests.

## Solution Files

1. **`common/templates/`** - Helm Library
2. **`example-app/`** - Usage example
3. **`MIGRATION_GUIDE.md`** - Migration guide
4. **`common/README.md`** - Library documentation

## Next Steps

1. Migration of existing projects (rocketchat, n8n, etc.)
2. Adding new templates (ConfigMap, Secret, PVC)
3. Library versioning
4. CI/CD for library

## Technical Details

- **Library type:** Helm Library Chart
- **Mechanism:** Named templates with `{{ define }}` and `{{ include }}`
- **Dependencies:** Local (`file://`) or remote repositories
- **Compatibility:** Helm 3.x
- **Tested:** ✅ Template generation works correctly 
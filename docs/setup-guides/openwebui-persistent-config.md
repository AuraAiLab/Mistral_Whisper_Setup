# OpenWebUI Persistent Configuration Guide

This guide explains how to ensure your OpenWebUI configuration settings (including web search and Mistral model connection) remain persistent and don't get overwritten when making changes in the OpenWebUI interface.

## Overview of the Persistent Configuration Setup

We've implemented multiple layers of persistence and connectivity to ensure your settings remain intact:

1. **ConfigMap Storage**: All environment variables are stored in a ConfigMap instead of hardcoding them in the deployment
2. **Data Volume**: OpenWebUI's database and settings are stored on a volume that persists during pod restarts
3. **UI Settings Protection**: Added settings to prevent the UI from overwriting configuration values
4. **Host Aliases**: Added critical hostname mapping to fix OpenWebUI's fallback connection to Ollama
5. **Deployment Script**: Created a script that applies everything in the correct order

## Components

### 1. ConfigMap (configs/openwebui/openwebui-configmap.yaml)

The ConfigMap stores all environment variables including:
- Connection URLs for Ollama/Mistral
- Web search settings
- Configuration protection settings

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: openwebui-config
  namespace: openwebui
data:
  # Core connection settings
  OLLAMA_API_BASE_URL: "http://ollama-service.ollama.svc.cluster.local:11434"
  HOST_OLLAMA_API_BASE_URL: "http://ollama-service.ollama.svc.cluster.local:11434"
  OPENAI_API_BASE_URL: "http://ollama-service.ollama.svc.cluster.local:11434"
  OLLAMA_BASE_URL_BROWSER: "http://ollama-service.ollama.svc.cluster.local:11434"
  
  # Web UI settings
  HOST: "0.0.0.0"
  PORT: "3000"
  
  # Web search settings
  WEB_SEARCH_ENABLED: "true"
  WEB_SEARCH_DEFAULT: "duckduckgo"
  WEB_SEARCH_RESULT_COUNT: "5"
  
  # Protection from UI overwrites
  RESTORE_ENABLE_SETTINGS: "false"
```

### 2. Host Aliases Configuration (Critical Fix)

The most important fix that makes Mistral models appear in the UI is the `hostAliases` configuration. Even with the correct environment variables, OpenWebUI sometimes falls back to using `host.docker.internal` when searching for models.

```yaml
spec:
  template:
    spec:
      hostAliases:
      - ip: "10.104.100.227"  # Ollama service IP address
        hostnames:
        - "host.docker.internal"
        - "ollama-service.ollama.svc.cluster.local"
```

This maps the Docker internal hostname to the actual Ollama service IP, ensuring that OpenWebUI can find the Mistral model even when falling back to alternative hostnames.

### 3. Data Volume (Using emptyDir)

We use an emptyDir volume to maintain data during pod restarts:

```yaml
volumes:
- name: openwebui-data
  emptyDir: {}
```

This volume persists as long as the pod exists on the node. If you need true persistence across node failures, you would need to setup a proper PersistentVolume with a storage backend.

### 4. Deployment Configuration (configs/openwebui/openwebui-deployment.yaml)

Uses the ConfigMap, host aliases, and volume:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openwebui
  namespace: openwebui
spec:
  # ...
  template:
    # ...
    spec:
      hostAliases:
      - ip: "10.104.100.227"
        hostnames:
        - "host.docker.internal"
        - "ollama-service.ollama.svc.cluster.local"
      volumes:
      - name: openwebui-data
        emptyDir: {}
      containers:
      - name: openwebui
        # ...
        envFrom:
        - configMapRef:
            name: openwebui-config
        volumeMounts:
        - name: openwebui-data
          mountPath: /app/backend/data
```

## How to Deploy

Use the deployment script which ensures everything is applied in the correct order:

```bash
cd /home/ee/Ai-Model-Installv1
./scripts/openwebui/deploy-openwebui.sh
```

## Making Configuration Changes

If you need to change any settings:

1. Edit the ConfigMap file:
   ```bash
   vi configs/openwebui/openwebui-configmap.yaml
   ```

2. Apply the updated ConfigMap:
   ```bash
   kubectl apply -f configs/openwebui/openwebui-configmap.yaml
   ```

3. Restart the OpenWebUI deployment to apply changes:
   ```bash
   kubectl rollout restart deployment openwebui -n openwebui
   ```

## Important Notes About Configuration

1. **Host Alias Requirement**: The host alias configuration is critical - it resolves a known issue in OpenWebUI where it attempts to connect to `host.docker.internal` as a fallback, even when the correct Ollama API URL is set.

2. **Persistence Limitations**: The current setup uses an `emptyDir` volume which persists for the lifecycle of the pod on a node. Your settings will survive pod restarts and redeployments but will NOT survive node failures.

3. **UI Protection**: The `RESTORE_ENABLE_SETTINGS: "false"` setting prevents the OpenWebUI interface from overwriting your environment variable settings.

## Troubleshooting

If Mistral models still don't appear in the UI:

1. Verify the Ollama service IP address:
   ```bash
   kubectl get service -n ollama ollama-service -o jsonpath='{.spec.clusterIP}'
   ```

2. Update the host alias in the deployment to match the Ollama service IP:
   ```bash
   # Edit the deployment file
   vi configs/openwebui/openwebui-deployment.yaml
   
   # Apply the changes
   kubectl apply -f configs/openwebui/openwebui-deployment.yaml
   ```

3. Check the OpenWebUI logs for connection errors:
   ```bash
   kubectl logs -n openwebui -l app=openwebui | grep -i "docker.internal" 
   ```

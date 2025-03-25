# OpenWebUI Persistent Configuration Guide

This guide explains how to ensure your OpenWebUI configuration settings (including web search and Mistral model connection) remain persistent and don't get overwritten when making changes in the OpenWebUI interface.

## Overview of the Persistent Configuration Setup

We've implemented multiple layers of persistence to ensure your settings remain intact:

1. **ConfigMap Storage**: All environment variables are stored in a ConfigMap instead of hardcoding them in the deployment
2. **Persistent Volume**: OpenWebUI's database and settings are stored on a persistent volume
3. **UI Settings Protection**: Added settings to prevent the UI from overwriting configuration values
4. **Deployment Script**: Created a script that applies everything in the correct order

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
  # Ollama connection settings
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

### 2. Persistent Volume Claim (configs/openwebui/openwebui-pvc.yaml)

This ensures all data is stored permanently:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: openwebui-data-pvc
  namespace: openwebui
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### 3. Deployment Configuration (configs/openwebui/openwebui-deployment.yaml)

Uses the ConfigMap and PVC:

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
      volumes:
      - name: openwebui-data
        persistentVolumeClaim:
          claimName: openwebui-data-pvc
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

## Important Note

The `RESTORE_ENABLE_SETTINGS: "false"` setting in the ConfigMap is critical - it prevents the OpenWebUI interface from overwriting your environment variable settings, which is what was causing the connection to Mistral to be lost previously.

## Troubleshooting

If settings are still being reset:

1. Check the OpenWebUI logs:
   ```bash
   kubectl logs -n openwebui -l app=openwebui | grep -i settings
   ```

2. Verify the ConfigMap is correctly mounted:
   ```bash
   kubectl describe pod -n openwebui -l app=openwebui
   ```

3. Make sure the persistent volume is properly mounted:
   ```bash
   kubectl exec -n openwebui -l app=openwebui -- ls -la /app/backend/data
   ```

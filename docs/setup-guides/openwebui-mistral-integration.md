# OpenWebUI Integration with Mistral 7B

This guide explains how to set up OpenWebUI to connect with Mistral 7B running on Ollama.

## Overview

OpenWebUI is a user-friendly web interface for interacting with large language models. By integrating it with Mistral 7B on Ollama, you can access the model through a convenient web interface.

## Prerequisites

- Mistral 7B already running on Ollama (see the Mistral 7B setup guide)
- Kubernetes cluster with kubectl access

## Setup Process

1. Create the OpenWebUI namespace:
```bash
kubectl create namespace openwebui
```

2. Deploy OpenWebUI with the correct configuration to connect to Ollama:
```bash
kubectl apply -f configs/openwebui/openwebui-deployment.yaml
```

3. Create a service for OpenWebUI:
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: openwebui-service
  namespace: openwebui
spec:
  selector:
    app: openwebui
  ports:
  - port: 3001
    targetPort: 3000
  type: LoadBalancer
EOF
```

4. Alternatively, you can use the included setup script:
```bash
./scripts/openwebui/setup-openwebui.sh
```

## Configuration Details

The key configuration is setting the `OLLAMA_API_BASE_URL` environment variable in the OpenWebUI deployment to point to your Ollama service:

```yaml
env:
- name: OLLAMA_API_BASE_URL
  value: "http://ollama-service.ollama.svc.cluster.local:11434"
```

This ensures that OpenWebUI can communicate with the Ollama API and access the Mistral 7B model.

## Accessing OpenWebUI

Once deployed, OpenWebUI will be accessible at:
```
http://<external-ip>:3001
```

You can find the external IP with:
```bash
kubectl get svc -n openwebui openwebui-service
```

## Troubleshooting

If OpenWebUI cannot connect to Ollama, check the following:

1. Ensure the Ollama service is running:
```bash
kubectl get pods -n ollama
```

2. Verify the Ollama service name and endpoint:
```bash
kubectl get svc -n ollama
```

3. Check OpenWebUI logs for connection issues:
```bash
kubectl logs -n openwebui -l app=openwebui
```

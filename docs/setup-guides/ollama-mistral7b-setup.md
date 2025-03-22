# Setting Up Mistral 7B on Ollama

This guide provides instructions for deploying Mistral 7B on Ollama within a Kubernetes environment.

## Prerequisites

- Kubernetes cluster with GPU support (NVIDIA GPU Operator installed)
- `ollama` namespace configured in Kubernetes
- Storage configured for model data at `/models/ollama/`

## Installation Steps

### 1. Install Ollama

Ollama can be deployed using a Helm chart or direct Kubernetes manifests. The following steps outline the deployment process:

```bash
# Create Ollama namespace if it doesn't exist
kubectl create namespace ollama

# Set up persistent volume for Ollama models
# Ensure the path /models/ollama exists on your host
kubectl apply -f configs/ollama/ollama-pv.yaml
kubectl apply -f configs/ollama/ollama-pvc.yaml

# Deploy Ollama using the provided deployment configuration
kubectl apply -f configs/ollama/ollama-deployment.yaml
kubectl apply -f configs/ollama/ollama-service.yaml
```

### 2. Pull and Run Mistral 7B

Once Ollama is running, you can pull and run the Mistral 7B model:

```bash
# Get the Ollama service IP or use port-forwarding
kubectl -n ollama port-forward svc/ollama-service 11434:11434

# In a new terminal, pull the Mistral 7B model
ollama pull mistral:7b

# Test the model
ollama run mistral:7b
```

### 3. API Usage

Ollama provides a simple REST API that can be used to interact with the Mistral 7B model:

```bash
# Generate a response
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "mistral:7b",
  "prompt": "What is machine learning?",
  "stream": false
}'
```

## Monitoring and Management

Monitor resource usage and model performance:

```bash
# Check pod status
kubectl -n ollama get pods

# View logs
kubectl -n ollama logs -f deployment/ollama

# Check resource usage
kubectl -n ollama top pods
```

## Troubleshooting

Common issues and solutions:

- **GPU not detected**: Ensure NVIDIA GPU Operator is installed and running correctly
- **Out of memory errors**: Adjust resource limits in the deployment configuration
- **Slow model loading**: Consider preloading models or adjusting resource allocations

## Next Steps

- Configure model fine-tuning
- Set up high availability
- Implement API authentication

# Deploying Whisper on Triton Inference Server

This guide outlines the steps to deploy OpenAI's Whisper speech recognition model on NVIDIA Triton Inference Server within a Kubernetes environment.

## Prerequisites

- Kubernetes cluster with GPU support (NVIDIA GPU Operator installed)
- `triton-inference` namespace configured in Kubernetes
- Storage configured for model data at `/models/triton/model_repo/`
- Access to Docker Hub or NGC for pulling Triton container images

## Installation Steps

### 1. Prepare Whisper Model for Triton

Whisper must be converted to a format compatible with Triton Inference Server:

```bash
# Clone the repository containing conversion scripts
git clone https://github.com/Ai-Model-Installv1/triton-whisper-scripts.git
cd triton-whisper-scripts

# Install dependencies
pip install -r requirements.txt

# Convert Whisper model to ONNX format
python convert_whisper_to_onnx.py --model-size base --output-dir /models/triton/model_repo/whisper
```

### 2. Set Up Triton Model Repository

Organize the model repository according to Triton's requirements:

```bash
# Create the model repository structure
mkdir -p /models/triton/model_repo/whisper/{1,config}

# Copy the model files
cp /path/to/converted/model/*.onnx /models/triton/model_repo/whisper/1/

# Create model configuration file
cp configs/triton/whisper/config.pbtxt /models/triton/model_repo/whisper/config/
```

### 3. Deploy Triton Inference Server

Deploy Triton using Kubernetes manifests:

```bash
# Create Triton namespace if it doesn't exist
kubectl create namespace triton-inference

# Set up persistent volume for Triton models
kubectl apply -f configs/triton/triton-pv.yaml
kubectl apply -f configs/triton/triton-pvc.yaml

# Deploy Triton using the provided configuration
kubectl apply -f configs/triton/triton-deployment.yaml
kubectl apply -f configs/triton/triton-service.yaml
```

### 4. Test the Whisper Deployment

Verify the deployment by sending inference requests:

```bash
# Port-forward the Triton HTTP endpoint
kubectl -n triton-inference port-forward svc/triton-inference-server 8000:8000

# In a new terminal, test with a sample audio file
curl -X POST localhost:8000/v2/models/whisper/infer -d @scripts/triton/sample_request.json
```

## Performance Tuning

Optimize Whisper on Triton:

```bash
# Configure dynamic batching
kubectl apply -f configs/triton/whisper-dynamic-batching.yaml

# Monitor performance
kubectl -n triton-inference exec -it [triton-pod-name] -- tritonserver --metrics-interval-ms=1000
```

## Monitoring and Scaling

```bash
# Check Triton pod status
kubectl -n triton-inference get pods

# View Triton logs
kubectl -n triton-inference logs -f deployment/triton-inference-server

# Scale the deployment if needed
kubectl -n triton-inference scale deployment/triton-inference-server --replicas=3
```

## Troubleshooting

Common issues and solutions:

- **Model loading errors**: Check model configuration file format and paths
- **GPU memory issues**: Adjust the model configuration for more efficient memory usage
- **Inference timeouts**: Increase timeout settings in both client and server configurations

## Next Steps

- Implement client applications using the Triton client SDK
- Set up model versioning and A/B testing
- Configure model ensembles for complex inference pipelines

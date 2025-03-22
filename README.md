# Ai-Model-Installv1

A project to document the installation and deployment of AI models on a Kubernetes cluster, focusing on Mistral 7b on Ollama and Whisper on Triton Inference Server.

## Overview

This repository tracks installation commands, scripts, issues, and information related to deploying AI models on a Kubernetes-based infrastructure. It serves as documentation for the setup process and a reference for future deployments.

## Project Goals

1. Setup Mistral 7b on Ollama
2. Deploy Whisper on Triton Inference Server
3. Document the process, challenges, and solutions

## Directory Structure

```
Ai-Model-Installv1/
├── docs/                      # Documentation
│   ├── setup-guides/          # Setup guides for each model
│   └── troubleshooting/       # Troubleshooting information
├── scripts/                   # Installation and helper scripts
│   ├── ollama/                # Scripts for Ollama setup
│   └── triton/                # Scripts for Triton setup
├── configs/                   # Configuration files
│   ├── ollama/                # Ollama configurations
│   └── triton/                # Triton configurations
├── issues/                    # Documented issues and resolutions
└── logs/                      # Installation logs
```

## Installation Requirements

Based on the Kubernetes cluster setup documents, the following components are expected to be available:

- Kubernetes cluster (v1.32.3)
- Containerd runtime
- Calico CNI (v3.26.1)
- MetalLB (v0.13.12)
- NVIDIA GPU Operator
- Namespaces: `ollama` and `triton-inference`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

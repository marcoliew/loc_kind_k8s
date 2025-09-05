kind create cluster --name dev --config kind-2-node-cluster.yaml

kind export kubeconfig --name dev


# Create cluster with specific Kubernetes version
kind create cluster --name my-cluster --image kindest/node:v1.30.0

# Or for older versions
kind create cluster --image kindest/node:v1.29.2
kind create cluster --image kindest/node:v1.28.7


# Check latest Kubernetes release (requires curl and jq)
curl -s https://api.github.com/repos/kubernetes/kubernetes/releases/latest | jq -r '.tag_name'

# Check latest Kind image tags
curl -s https://registry.hub.docker.com/v2/repositories/kindest/node/tags/?page_size=100 | jq -r '.results[].name' | grep -E "^v[0-9]" | sort -V | tail -5
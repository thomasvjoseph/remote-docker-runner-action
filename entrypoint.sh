#!/bin/bash

set -euo pipefail

# Decode SSH private key
echo "${INPUT_DEPLOY_TOKEN}" | base64 -d > id_rsa
chmod 600 id_rsa

# Set defaults
REGISTRY="${INPUT_DOCKER_HOST:-docker.io}"
TAG="${INPUT_DOCKER_IMAGE_TAG:-latest}"

# Parse secrets into -e KEY=VALUE
ENV_ARGS=""
IFS=',' read -ra PAIRS <<< "${INPUT_DOCKER_SECRETS:-}"
for pair in "${PAIRS[@]}"; do
  ENV_ARGS+=" -e ${pair}"
done

# Compose Docker commands to run remotely
read -r -d '' REMOTE_CMD <<EOF
set -e

echo "🔐 Logging into Docker registry..."
docker login ${REGISTRY} -u ${INPUT_DOCKER_USERNAME} -p ${INPUT_DOCKER_PASSWORD}

echo "📥 Pulling Docker image..."
docker pull ${INPUT_DOCKER_IMAGE_URL}:${TAG}

echo "🛑 Stopping and removing existing container if it exists..."
docker ps -q --filter "name=${INPUT_DOCKER_CONTAINER_NAME}" | grep -q . && \
docker stop ${INPUT_DOCKER_CONTAINER_NAME} && docker rm ${INPUT_DOCKER_CONTAINER_NAME} || echo "No existing container."

echo "🚀 Running new container in detached mode..."
docker run -d --name ${INPUT_DOCKER_CONTAINER_NAME} ${INPUT_DOCKER_PORTS} ${ENV_ARGS} ${INPUT_DOCKER_OPTIONS} ${INPUT_DOCKER_IMAGE_URL}:${TAG}
EOF

# Run remotely via SSH
ssh -o StrictHostKeyChecking=no -i id_rsa "${INPUT_SERVER_HOST}" "$REMOTE_CMD"
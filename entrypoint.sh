#!/bin/sh

set -eu

# Decode SSH private key
echo "$INPUT_PRIVATE_KEY" | base64 -d > id_rsa
chmod 600 id_rsa

# Set defaults
TAG="${INPUT_TAG:-latest}"
REGISTRY="${INPUT_REGISTRY:-docker.io}"

# Parse env_vars into -e KEY=VAL format
ENV_ARGS=""
if [ -n "${INPUT_ENV_VARS}" ]; then
  IFS=','; set -f
  for pair in $INPUT_ENV_VARS; do
    ENV_ARGS="$ENV_ARGS -e $pair"
    set +f
  done
fi

# Build remote command
cat > remote_cmd.sh <<EOF
set -e

echo "🔐 Logging into Docker registry..."
docker login \$REGISTRY -u \$INPUT_DOCKER_USERNAME -p \$INPUT_DOCKER_PASSWORD

echo "📥 Pulling Docker image..."
docker pull \$INPUT_IMAGE:\$TAG

echo "🛑 Stopping and removing existing container if it exists..."
docker ps -q --filter "name=\$INPUT_CONTAINER_NAME" | grep -q . && \\
docker stop \$INPUT_CONTAINER_NAME && docker rm \$INPUT_CONTAINER_NAME || echo "No existing container."

echo "🚀 Running new container..."
docker run -d --name \$INPUT_CONTAINER_NAME \$INPUT_DOCKER_PORTS \$ENV_ARGS \$INPUT_DOCKER_OPTIONS \$INPUT_IMAGE:\$TAG
EOF

# SSH and run the composed command
ssh -o StrictHostKeyChecking=no -i id_rsa "${INPUT_USERNAME}@${INPUT_HOST}" 'sh -s' < remote_cmd.sh
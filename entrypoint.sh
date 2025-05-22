#!/bin/sh
set -eu

# Decode SSH private key
echo "$INPUT_PRIVATE_KEY" | base64 -d > id_rsa
chmod 600 id_rsa

# Test decode
if ! ssh-keygen -y -f id_rsa > /dev/null 2>&1; then
  echo "❌ Invalid SSH private key — likely corrupted or wrong format"
  echo "First 10 lines of decoded key:"
  head -n 10 id_rsa
  exit 1
fi

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

# Write the remote command to a temporary file
cat > remote_cmd.sh <<'EOF'
set -e

echo "🔐 Logging into Docker registry..."
docker login "$REGISTRY" -u "$INPUT_DOCKER_USERNAME" -p "$INPUT_DOCKER_PASSWORD"

echo "📥 Pulling Docker image..."
docker pull "$INPUT_IMAGE:$TAG"

echo "🛑 Stopping and removing existing container if it exists..."
docker ps -q --filter "name=$INPUT_CONTAINER_NAME" | grep -q . && \
docker stop "$INPUT_CONTAINER_NAME" && docker rm "$INPUT_CONTAINER_NAME" || echo "No existing container."

echo "🚀 Running new container..."
docker run -d \
  --name "$INPUT_CONTAINER_NAME" \
  $INPUT_DOCKER_PORTS \
  $ENV_ARGS \
  $INPUT_DOCKER_OPTIONS \
  "$INPUT_IMAGE:$TAG"
EOF

# Copy environment variables into remote script
sed -i "1i REGISTRY=$REGISTRY" remote_cmd.sh
sed -i "1i INPUT_DOCKER_PASSWORD=$INPUT_DOCKER_PASSWORD" remote_cmd.sh
sed -i "1i INPUT_DOCKER_USERNAME=$INPUT_DOCKER_USERNAME" remote_cmd.sh
sed -i "1i INPUT_CONTAINER_NAME=$INPUT_CONTAINER_NAME" remote_cmd.sh
sed -i "1i INPUT_IMAGE=$INPUT_IMAGE" remote_cmd.sh
sed -i "1i TAG=$TAG" remote_cmd.sh
sed -i "1i ENV_ARGS=$ENV_ARGS" remote_cmd.sh
sed -i "1i INPUT_DOCKER_PORTS=$INPUT_DOCKER_PORTS" remote_cmd.sh
sed -i "1i INPUT_DOCKER_OPTIONS=$INPUT_DOCKER_OPTIONS" remote_cmd.sh

# SSH and run the script
ssh -o StrictHostKeyChecking=no -i id_rsa "$INPUT_USERNAME@$INPUT_HOST" 'sh -s' < remote_cmd.sh
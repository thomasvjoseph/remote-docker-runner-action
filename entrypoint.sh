#!/bin/sh
set -euo pipefail

# Function to log errors and exit
log_error() {
  echo "❌ $1" >&2
  exit "${2:-1}"
}

# Ensure required environment variables are set
: "${INPUT_PRIVATE_KEY:?Missing INPUT_PRIVATE_KEY}"
: "${INPUT_HOST:?Missing INPUT_HOST}"
: "${INPUT_USERNAME:?Missing INPUT_USERNAME}"
: "${INPUT_IMAGE:?Missing INPUT_IMAGE}"
: "${INPUT_CONTAINER_NAME:?Missing INPUT_CONTAINER_NAME}"

# Set defaults
TAG="${INPUT_TAG:-latest}"
REGISTRY="${INPUT_REGISTRY:-docker.io}"

# Decode and save the SSH private key
echo "🔐 Decoding SSH private key..."
echo "$INPUT_PRIVATE_KEY" > id_rsa
chmod 600 id_rsa

if ! ssh-keygen -y -f id_rsa > /dev/null 2>&1; then
  echo "❌ Invalid SSH private key"
  exit 1
fi

echo "✅ Private key is valid!"

# Parse environment variables into -e KEY=VAL format (POSIX compatible)
ENV_ARGS=""
if [ -n "${INPUT_ENV_VARS:-}" ]; then
  # Replace commas with spaces and iterate
  env_list=$(echo "$INPUT_ENV_VARS" | tr ',' ' ')
  for pair in $env_list; do
    ENV_ARGS="$ENV_ARGS -e $pair"
  done
fi

# Create the remote command script with variables substituted
cat > remote_cmd.sh <<EOF
#!/bin/sh
set -e

echo "🔐 Logging into Docker registry..."
echo "$INPUT_DOCKER_PASSWORD" | docker login "$REGISTRY" -u "$INPUT_DOCKER_USERNAME" --password-stdin

echo "📥 Pulling Docker image..."
docker pull "$INPUT_IMAGE:$TAG"

echo "🛑 Stopping and removing existing container if it exists..."
if docker ps -q --filter "name=$INPUT_CONTAINER_NAME" | grep -q .; then
  docker stop "$INPUT_CONTAINER_NAME"
  docker rm "$INPUT_CONTAINER_NAME"
else
  echo "No existing container named $INPUT_CONTAINER_NAME."
fi

echo "🚀 Running new container..."
docker run -d \\
  --name "$INPUT_CONTAINER_NAME" \\
  ${INPUT_DOCKER_PORTS:-} \\
  ${ENV_ARGS:-} \\
  ${INPUT_DOCKER_OPTIONS:-} \\
  "$INPUT_IMAGE:$TAG"

echo "✅ Container deployed successfully!"
EOF

# Execute the remote command script via SSH
echo "🔗 Connecting to remote host and executing commands..."
ssh -o StrictHostKeyChecking=no -i id_rsa "$INPUT_USERNAME@$INPUT_HOST" 'bash -s' < remote_cmd.sh
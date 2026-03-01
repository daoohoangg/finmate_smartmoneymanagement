#!/usr/bin/env bash
set -euo pipefail

require_var() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "Missing required CI variable: ${name}" >&2
    exit 1
  fi
}

ensure_tools() {
  if command -v docker >/dev/null 2>&1 && command -v ssh >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y --no-install-recommends ca-certificates docker.io openssh-client python3
  elif command -v tdnf >/dev/null 2>&1; then
    tdnf install -y ca-certificates docker-cli openssh-clients python3
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache ca-certificates docker-cli openssh-client python3
  else
    echo "Unsupported base image: cannot install docker/ssh/python3" >&2
    exit 1
  fi
}

load_azure_credentials_from_json() {
  if [ -z "${AZURE_CREDENTIALS:-}" ]; then
    return
  fi

  eval "$(
    python3 - <<'PY'
import json
import os
import shlex

raw = os.environ.get("AZURE_CREDENTIALS", "")
if not raw:
    raise SystemExit(0)

data = json.loads(raw)
mapping = {
    "AZURE_CLIENT_ID": "clientId",
    "AZURE_CLIENT_SECRET": "clientSecret",
    "AZURE_TENANT_ID": "tenantId",
    "AZURE_SUBSCRIPTION_ID": "subscriptionId",
}
for env_name, json_key in mapping.items():
    value = os.environ.get(env_name) or data.get(json_key, "")
    print(f"export {env_name}={shlex.quote(value)}")
PY
  )"
}

b64() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

ensure_tools
load_azure_credentials_from_json

require_var ACR_NAME
require_var AZURE_VM_HOST
require_var AZURE_VM_USER
require_var AZURE_VM_SSH_PRIVATE_KEY
require_var DB_PASSWORD
require_var CLOUD_API_KEY
require_var CLOUD_API_SECRET
require_var JWT_SECRET

IMAGE_TAG="${IMAGE_TAG:-${CI_COMMIT_SHA:-latest}}"
AZURE_VM_PORT="${AZURE_VM_PORT:-22}"
FINMATE_DOCKER_NETWORK="${FINMATE_DOCKER_NETWORK:-finmate-network}"
FINMATE_BE_CONTAINER_NAME="${FINMATE_BE_CONTAINER_NAME:-finmate-api}"
FINMATE_WEB_CONTAINER_NAME="${FINMATE_WEB_CONTAINER_NAME:-finmate-web}"
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}"

if [[ "${ACR_NAME}" == *.azurecr.io ]]; then
  ACR_LOGIN_SERVER="${ACR_NAME}"
  ACR_RESOURCE_NAME="${ACR_NAME%%.azurecr.io}"
else
  ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
  ACR_RESOURCE_NAME="${ACR_NAME}"
fi

ACR_USER="${ACR_USERNAME:-}"
ACR_PASS="${ACR_PASSWORD:-}"

if [ -z "${ACR_USER}" ] || [ -z "${ACR_PASS}" ]; then
  require_var AZURE_CLIENT_ID
  require_var AZURE_CLIENT_SECRET
  require_var AZURE_TENANT_ID
  require_var AZURE_SUBSCRIPTION_ID

  az login --service-principal \
    -u "${AZURE_CLIENT_ID}" \
    -p "${AZURE_CLIENT_SECRET}" \
    --tenant "${AZURE_TENANT_ID}" >/dev/null
  az account set --subscription "${AZURE_SUBSCRIPTION_ID}"

  ACR_USER="00000000-0000-0000-0000-000000000000"
  ACR_PASS="$(az acr login --name "${ACR_RESOURCE_NAME}" --expose-token --output tsv --query accessToken)"
fi

echo "${ACR_PASS}" | docker login "${ACR_LOGIN_SERVER}" -u "${ACR_USER}" --password-stdin >/dev/null

BE_IMAGE="${ACR_LOGIN_SERVER}/finmate-be:${IMAGE_TAG}"
WEB_IMAGE="${ACR_LOGIN_SERVER}/finmate-web:${IMAGE_TAG}"

docker build -t "${BE_IMAGE}" -f finmate_smartmoneymanagement_be/Dockerfile finmate_smartmoneymanagement_be
docker build -t "${WEB_IMAGE}" -f finmate_smartmoneymanagement_flutter/Dockerfile finmate_smartmoneymanagement_flutter
docker push "${BE_IMAGE}"
docker push "${WEB_IMAGE}"

mkdir -p ~/.ssh
chmod 700 ~/.ssh
printf '%b' "${AZURE_VM_SSH_PRIVATE_KEY}" | tr -d '\r' > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

SSH_TARGET="${AZURE_VM_USER}@${AZURE_VM_HOST}"

ssh -i ~/.ssh/id_rsa \
  -p "${AZURE_VM_PORT}" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "${SSH_TARGET}" \
  "ACR_LOGIN_SERVER_B64='$(b64 "${ACR_LOGIN_SERVER}")' \
   ACR_USER_B64='$(b64 "${ACR_USER}")' \
   ACR_PASS_B64='$(b64 "${ACR_PASS}")' \
   BE_IMAGE_B64='$(b64 "${BE_IMAGE}")' \
   WEB_IMAGE_B64='$(b64 "${WEB_IMAGE}")' \
   FINMATE_DOCKER_NETWORK_B64='$(b64 "${FINMATE_DOCKER_NETWORK}")' \
   FINMATE_BE_CONTAINER_NAME_B64='$(b64 "${FINMATE_BE_CONTAINER_NAME}")' \
   FINMATE_WEB_CONTAINER_NAME_B64='$(b64 "${FINMATE_WEB_CONTAINER_NAME}")' \
   DB_PASSWORD_B64='$(b64 "${DB_PASSWORD}")' \
   CLOUD_API_KEY_B64='$(b64 "${CLOUD_API_KEY}")' \
   CLOUD_API_SECRET_B64='$(b64 "${CLOUD_API_SECRET}")' \
   JWT_SECRET_B64='$(b64 "${JWT_SECRET}")' \
   GOOGLE_CLIENT_ID_B64='$(b64 "${GOOGLE_CLIENT_ID}")' \
   bash -s" <<'REMOTE_SCRIPT'
set -euo pipefail

decode() {
  printf '%s' "$1" | base64 -d
}

ACR_LOGIN_SERVER="$(decode "${ACR_LOGIN_SERVER_B64}")"
ACR_USER="$(decode "${ACR_USER_B64}")"
ACR_PASS="$(decode "${ACR_PASS_B64}")"
BE_IMAGE="$(decode "${BE_IMAGE_B64}")"
WEB_IMAGE="$(decode "${WEB_IMAGE_B64}")"
FINMATE_DOCKER_NETWORK="$(decode "${FINMATE_DOCKER_NETWORK_B64}")"
FINMATE_BE_CONTAINER_NAME="$(decode "${FINMATE_BE_CONTAINER_NAME_B64}")"
FINMATE_WEB_CONTAINER_NAME="$(decode "${FINMATE_WEB_CONTAINER_NAME_B64}")"

DB_PASSWORD="$(decode "${DB_PASSWORD_B64}")"
CLOUD_API_KEY="$(decode "${CLOUD_API_KEY_B64}")"
CLOUD_API_SECRET="$(decode "${CLOUD_API_SECRET_B64}")"
JWT_SECRET="$(decode "${JWT_SECRET_B64}")"
GOOGLE_CLIENT_ID="$(decode "${GOOGLE_CLIENT_ID_B64}")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed on Azure VM." >&2
  exit 1
fi

echo "${ACR_PASS}" | docker login "${ACR_LOGIN_SERVER}" -u "${ACR_USER}" --password-stdin >/dev/null
docker network create "${FINMATE_DOCKER_NETWORK}" >/dev/null 2>&1 || true
docker pull "${BE_IMAGE}"
docker pull "${WEB_IMAGE}"

docker rm -f "${FINMATE_BE_CONTAINER_NAME}" >/dev/null 2>&1 || true
docker rm -f "${FINMATE_WEB_CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run -d \
  --name "${FINMATE_BE_CONTAINER_NAME}" \
  --restart unless-stopped \
  --network "${FINMATE_DOCKER_NETWORK}" \
  -p 8080:8080 \
  -e DB_PASSWORD="${DB_PASSWORD}" \
  -e CLOUD_API_KEY="${CLOUD_API_KEY}" \
  -e CLOUD_API_SECRET="${CLOUD_API_SECRET}" \
  -e JWT_SECRET="${JWT_SECRET}" \
  -e GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID}" \
  "${BE_IMAGE}"

docker run -d \
  --name "${FINMATE_WEB_CONTAINER_NAME}" \
  --restart unless-stopped \
  --network "${FINMATE_DOCKER_NETWORK}" \
  -p 80:80 \
  "${WEB_IMAGE}"

for container in "${FINMATE_BE_CONTAINER_NAME}" "${FINMATE_WEB_CONTAINER_NAME}"; do
  if ! docker ps --filter "name=^/${container}$" --filter "status=running" --format '{{.Names}}' | grep -qx "${container}"; then
    echo "Container ${container} is not running." >&2
    docker logs "${container}" || true
    exit 1
  fi
done

docker image prune -f >/dev/null 2>&1 || true
REMOTE_SCRIPT

echo "Deploy completed."
echo "Web: http://${AZURE_VM_HOST}"
echo "API: http://${AZURE_VM_HOST}:8080"

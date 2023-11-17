#!/bin/bash

set -eu

if [ $# -eq 0 ]
then
  echo "No arguments provided"
  exit 1
fi

if command -v podman > /dev/null
then
  CONTAINER_EXEC=podman
  if [[ -n "${PULP_MCS_LABEL:-}" ]]
  then
    USER_COMMAND=("--userns=keep-id" "--security-opt" "label=level:$PULP_MCS_LABEL")
  else
    USER_COMMAND=("--userns=keep-id")
  fi
  ULIMIT_COMMAND=()
else
  CONTAINER_EXEC=docker
  if [[ -n "${PULP_MCS_LABEL:-}" ]]
  then
    USER_COMMAND=("-u" "$(id -u)" "--security-opt" "label=level:$PULP_MCS_LABEL")
  else
    USER_COMMAND=("-u" "$(id -u)")
  fi
  ULIMIT_COMMAND=("--ulimit" "nofile=122880:122880")
fi

if command -v getenforce > /dev/null && [ "$(getenforce)" == "Enforcing" ]
then
  VOLUME_NAME="/local:Z"
else
  VOLUME_NAME="/local"
fi

# Skip downloading the api.json if `USE_LOCAL_API_JSON` is set.
if [[ -z "${USE_LOCAL_API_JSON:-}" ]]
then
  PULP_URL="${PULP_URL:-http://localhost:24817}"
  PULP_API_ROOT="${PULP_API_ROOT:-/pulp/}"
  PULP_URL="${PULP_URL}${PULP_API_ROOT}api/v3/"

  # Download the schema
  RETRY_COUNT=0
  until curl --fail-with-body -k -o api.json "${PULP_URL}docs/api.json?bindings&plugin=$1"
  do
      if [ $RETRY_COUNT -eq 10 ]
      then
          break
      fi
      sleep 2
      ((RETRY_COUNT++))
  done
  # Get the version of the pulpcore or plugin as reported by status API
fi

DOMAIN_ENABLED="$(jq -r '.info | ."x-pulp-domain-enabled" // false' < api.json)"

if [ $# -gt 2 ]
then
  export VERSION=$3
else
  # match the component name by removing the "pulp/pulp_" prefix
  if [ "$1" = "pulpcore" ]
  then
      COMPONENT="core"
  else
      COMPONENT=${1#"pulp_"}
  fi

  VERSION="$(curl -k "${PULP_URL}status/" | jq --arg component "$COMPONENT" -r '.versions[] | select(.component == $component) | .version')"
fi

# Mount volumes from parent container with `--volumes-from` option if the
# `PARENT_CONTAINER_ID` is set.
if [ -z "${PARENT_CONTAINER_ID:-}" ]
then
  VOLUME_OPTION=("--volume" "${PWD}:${VOLUME_NAME}")
  VOLUME_DIR="/local"
else
  VOLUME_OPTION=("--volumes-from" "${PARENT_CONTAINER_ID}:rw")
  VOLUME_DIR="${PWD}"
fi

OPENAPI_PYTHON_IMAGE="${OPENAPI_PYTHON_IMAGE:-docker.io/openapitools/openapi-generator-cli:v4.3.1}"
OPENAPI_RUBY_IMAGE="${OPENAPI_RUBY_IMAGE:-docker.io/openapitools/openapi-generator-cli:v4.3.1}"
OPENAPI_TYPESCRIPT_IMAGE="${OPENAPI_TYPESCRIPT_IMAGE:-docker.io/openapitools/openapi-generator-cli:v5.2.1}"

echo ::group::BINDINGS
if [ "$2" = "python" ]
then
  $CONTAINER_EXEC run \
    "${ULIMIT_COMMAND[@]}" \
    "${USER_COMMAND[@]}" \
    --rm \
    "${VOLUME_OPTION[@]}" \
    "$OPENAPI_PYTHON_IMAGE" generate \
    -i "${VOLUME_DIR}/api.json" \
    -g python \
    -o "${VOLUME_DIR}/$1-client" \
    "--additional-properties=packageName=pulpcore.client.$1,projectName=$1-client,packageVersion=${VERSION},domainEnabled=${DOMAIN_ENABLED}" \
    -t "${VOLUME_DIR}/templates/python" \
    --skip-validate-spec \
    --strict-spec=false
  cp python/__init__.py "$1-client/pulpcore/"
  cp python/__init__.py "$1-client/pulpcore/client/"
fi
if [ "$2" = 'ruby' ]
then
  # https://github.com/OpenAPITools/openapi-generator/wiki/FAQ#how-to-skip-certain-files-during-code-generation
  mkdir -p "$1-client"
  echo git_push.sh > "$1-client/.openapi-generator-ignore"

  python3 remove-cookie-auth.py
  $CONTAINER_EXEC run \
    "${ULIMIT_COMMAND[@]}" \
    "${USER_COMMAND[@]}" \
    --rm \
    "${VOLUME_OPTION[@]}" \
    "$OPENAPI_RUBY_IMAGE" generate \
    -i "${VOLUME_DIR}/api.json" \
    -g ruby \
    -o "${VOLUME_DIR}/$1-client" \
    "--additional-properties=gemName=$1_client,gemLicense="GPLv2+",gemVersion=${VERSION},gemHomepage=https://github.com/pulp/$1" \
    --library=faraday \
    -t "${VOLUME_DIR}/templates/ruby" \
    --skip-validate-spec \
    --strict-spec=false
fi
if [ "$2" = 'typescript' ]
then
  $CONTAINER_EXEC run \
    "${ULIMIT_COMMAND[@]}" \
    "${USER_COMMAND[@]}" \
    --rm \
    "${VOLUME_OPTION[@]}" \
    "$OPENAPI_TYPESCRIPT_IMAGE" generate \
    -i "${VOLUME_DIR}/api.json" \
    -g typescript-axios \
    -o "${VOLUME_DIR}/$1-client" \
    -t "${VOLUME_DIR}/templates/typescript-axios" \
    --skip-validate-spec \
    --strict-spec=false
fi

echo ::endgroup::
if [[ -z "${USE_LOCAL_API_JSON:-}" ]]
then
  rm api.json
fi

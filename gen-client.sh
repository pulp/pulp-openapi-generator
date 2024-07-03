#!/bin/bash

set -eu

if [ $# -eq 0 ]
then
  echo "No arguments provided"
  echo "Usage: $0 <api_spec> <component> [<language> [<package>]]"
  exit 1
fi

API_SPEC="$1"
COMPONENT="$2"
LANGUAGE="${3:-python}"
PACKAGE="${4:-pulp_${COMPONENT//-/_}}"

DOMAIN_ENABLED="$(jq -r '.info."x-pulp-domain-enabled" // false' < "${API_SPEC}")"
VERSION="$(jq -r --arg component "$COMPONENT" '.info."x-pulp-app-versions"[$component] // error("No version found.")' < "${API_SPEC}")"
echo "Unnormalized Version: ${VERSION}"
VERSION="$(python3 -c "from packaging.version import Version; print(Version('${VERSION}'))")"
echo "Version: ${VERSION}"

OPENAPI_PYTHON_IMAGE="${OPENAPI_PYTHON_IMAGE:-docker.io/openapitools/openapi-generator-cli:v4.3.1}"
OPENAPI_RUBY_IMAGE="${OPENAPI_RUBY_IMAGE:-docker.io/openapitools/openapi-generator-cli:v5.3.0}"
OPENAPI_TYPESCRIPT_IMAGE="${OPENAPI_TYPESCRIPT_IMAGE:-docker.io/openapitools/openapi-generator-cli:v5.2.1}"

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

# Mount volumes from parent container with `--volumes-from` option if `PARENT_CONTAINER_ID` is set.
if [ -z "${PARENT_CONTAINER_ID:-}" ]
then
  if command -v getenforce > /dev/null && [ "$(getenforce)" == "Enforcing" ]
  then
    VOLUME_NAME="/local:Z"
  else
    VOLUME_NAME="/local"
  fi
  VOLUME_OPTION=("--volume" "${PWD}:${VOLUME_NAME}")
  VOLUME_DIR="/local"
else
  VOLUME_OPTION=("--volumes-from" "${PARENT_CONTAINER_ID}:rw")
  VOLUME_DIR="${PWD}"
fi

if [ "$LANGUAGE" = "python" ]
then
  $CONTAINER_EXEC run \
    "${ULIMIT_COMMAND[@]}" \
    "${USER_COMMAND[@]}" \
    --rm \
    "${VOLUME_OPTION[@]}" \
    "$OPENAPI_PYTHON_IMAGE" generate \
    -i "${VOLUME_DIR}/${API_SPEC}" \
    -g python \
    -o "${VOLUME_DIR}/${PACKAGE}-client" \
    "--additional-properties=packageName=pulpcore.client.${PACKAGE},projectName=${PACKAGE}-client,packageVersion=${VERSION},domainEnabled=${DOMAIN_ENABLED}" \
    -t "${VOLUME_DIR}/templates/python" \
    --skip-validate-spec \
    --strict-spec=false
  cp python/__init__.py "${PACKAGE}-client/pulpcore/"
  cp python/__init__.py "${PACKAGE}-client/pulpcore/client/"
fi

if [ "$LANGUAGE" = "ruby" ]
then
  # https://github.com/OpenAPITools/openapi-generator/wiki/FAQ#how-to-skip-certain-files-during-code-generation
  mkdir -p "${PACKAGE}-client"
  echo git_push.sh > "${PACKAGE}-client/.openapi-generator-ignore"

  python3 remove-cookie-auth.py
  $CONTAINER_EXEC run \
    "${ULIMIT_COMMAND[@]}" \
    "${USER_COMMAND[@]}" \
    --rm \
    "${VOLUME_OPTION[@]}" \
    "$OPENAPI_RUBY_IMAGE" generate \
    -i "${VOLUME_DIR}/${API_SPEC}" \
    -g ruby \
    -o "${VOLUME_DIR}/${PACKAGE}-client" \
    "--additional-properties=gemName=${PACKAGE}_client,gemLicense="GPLv2+",gemVersion=${VERSION},gemHomepage=https://github.com/pulp/${PACKAGE}" \
    --library=faraday \
    -t "${VOLUME_DIR}/templates/ruby" \
    --skip-validate-spec \
    --strict-spec=false
fi

if [ "$LANGUAGE" = "typescript" ]
then
  $CONTAINER_EXEC run \
    "${ULIMIT_COMMAND[@]}" \
    "${USER_COMMAND[@]}" \
    --rm \
    "${VOLUME_OPTION[@]}" \
    "$OPENAPI_TYPESCRIPT_IMAGE" generate \
    -i "${VOLUME_DIR}/${API_SPEC}" \
    -g typescript-axios \
    -o "${VOLUME_DIR}/${PACKAGE}-client" \
    -t "${VOLUME_DIR}/templates/typescript-axios" \
    --skip-validate-spec \
    --strict-spec=false
fi

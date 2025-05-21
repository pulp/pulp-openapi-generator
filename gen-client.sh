#!/bin/bash

set -eu

SCRIPT_NAME="$(basename "$0")"

if [ $# -eq 0 ]
then
  cat << EOF
No arguments provided.
${SCRIPT_NAME} - Generate client libraries for pulp plugins.

USAGE
    ${SCRIPT_NAME} <api_spec> <component> [<language> [<package>]]

ARGS
    api_spec:  The openapi schema file in json format.
    component: The pulp component target client. It should be a key in the
               'info.x-pulp-app-versions' object from the <api_spec> file.
    language:  The target language for the client generation. Default: python.
    package:   The name of the generated package name in the target language.
               Default: pulp_{component}

DESCRIPTION
    Generate a client for the given <language> and Pulp <component> using the
    provided openapi <api_spec>.

    The package will be created at './<package>-client/'.

    Learn more:
    <https://pulpproject.org/pulp-openapi-generator/docs/user/guides/generate-bindings/>

EXAMPLES
    Generate a pulp_rpm ruby client at 'pulp_rpm-client/' using 'rpm-api.json' spec:
    $ ${SCRIPT_NAME} rpm-api.json rpm ruby

    Generate a pulp_maven python client at 'my-maven-client/' using 'maven-api.json' spec:
    $ ${SCRIPT_NAME} maven-api.json maven python my-maven
EOF
  exit 1
fi

normalize_version ()
{
  python3 -c '
import sys
from packaging.version import Version

print(Version(sys.stdin.read()))
'
}

generator_version ()
{
  python3 -c '
import sys
from packaging.version import Version

language = sys.argv[1]
core_version = Version(sys.stdin.read())

if language.lower() == "python":
    if core_version >= Version("3.70.dev"):
        print("v7.10.0")
    else:
        print("v4.3.1")
elif language.lower() == "ruby":
    if core_version >= Version("3.70.dev"):
        print("v7.10.0")
    else:
        print("v4.3.1")
elif language.lower() == "typescript":
    print("v5.2.1")
else:
    exit(1)
' "$@"
}

API_SPEC="$1"
COMPONENT="$2"
LANGUAGE="${3:-python}"
PACKAGE="${4:-pulp_${COMPONENT//-/_}}"

OPENAPI_VERSION="$(jq -r '.openapi // false' < "${API_SPEC}")"
DOMAIN_ENABLED="$(jq -r '.info."x-pulp-domain-enabled" // false' < "${API_SPEC}")"
VERSION="$(jq -r --arg component "${COMPONENT}" '.info."x-pulp-app-versions"[$component] // error("No version found.")' < "${API_SPEC}" | normalize_version)"
CORE_VERSION="$(jq -r '.info."x-pulp-app-versions".core // "0.0.0"' < "${API_SPEC}" | normalize_version)"
GENERATOR_VERSION="$(generator_version "${LANGUAGE}" <<<"${CORE_VERSION}")"
IMAGE_OVERRIDE_VAR="OPENAPI_${LANGUAGE^^}_IMAGE"
OPENAPI_IMAGE="${!IMAGE_OVERRIDE_VAR:-docker.io/openapitools/openapi-generator-cli:${GENERATOR_VERSION}}"
IMAGE_TAG="${OPENAPI_IMAGE#*:}"

echo "${COMPONENT}: ${VERSION}  core: ${CORE_VERSION}  domains: ${DOMAIN_ENABLED}  generator: ${GENERATOR_VERSION}  openapi: ${OPENAPI_VERSION}"
echo "Using: ${OPENAPI_IMAGE}"

if command -v podman > /dev/null
then
  CONTAINER_EXEC=podman
  if [[ -n "${PULP_MCS_LABEL:-}" ]]
  then
    USER_COMMAND=("--userns=keep-id" "--security-opt" "label=level:${PULP_MCS_LABEL}")
  else
    USER_COMMAND=("--userns=keep-id")
  fi
  ULIMIT_COMMAND=()
else
  CONTAINER_EXEC=docker
  if [[ -n "${PULP_MCS_LABEL:-}" ]]
  then
    USER_COMMAND=("-u" "$(id -u)" "--security-opt" "label=level:${PULP_MCS_LABEL}")
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

REMOVE_COOKIE_AUTH_FILTER='del(.paths[][].security|select(.)[]|select(.cookieAuth))|del(.components.securitySchemes.cookieAuth)'

if [ "$LANGUAGE" = "python" ]
then
  cat "${API_SPEC}" | jq "." > patched-api.json

  $CONTAINER_EXEC run \
    "${ULIMIT_COMMAND[@]}" \
    "${USER_COMMAND[@]}" \
    --rm \
    "${VOLUME_OPTION[@]}" \
    "${OPENAPI_IMAGE}" generate \
    -i "${VOLUME_DIR}/patched-api.json" \
    -g python \
    -o "${VOLUME_DIR}/${PACKAGE}-client" \
    "--additional-properties=packageName=pulpcore.client.${PACKAGE},projectName=${PACKAGE}-client,packageVersion=${VERSION},domainEnabled=${DOMAIN_ENABLED}" \
    -t "${VOLUME_DIR}/templates/python/${IMAGE_TAG}" \
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

  cat "${API_SPEC}" | jq "${REMOVE_COOKIE_AUTH_FILTER}" > patched-api.json

  $CONTAINER_EXEC run \
    "${ULIMIT_COMMAND[@]}" \
    "${USER_COMMAND[@]}" \
    --rm \
    "${VOLUME_OPTION[@]}" \
    "${OPENAPI_IMAGE}" generate \
    -i "${VOLUME_DIR}/patched-api.json" \
    -g ruby \
    -o "${VOLUME_DIR}/${PACKAGE}-client" \
    "--additional-properties=gemName=${PACKAGE}_client,gemLicense="GPLv2+",gemVersion=${VERSION},gemHomepage=https://github.com/pulp/${PACKAGE}" \
    --library=faraday \
    -t "${VOLUME_DIR}/templates/ruby/${IMAGE_TAG}" \
    --skip-validate-spec \
    --strict-spec=false
fi

if [ "$LANGUAGE" = "typescript" ]
then
  cat "${API_SPEC}" | jq "." > patched-api.json

  $CONTAINER_EXEC run \
    "${ULIMIT_COMMAND[@]}" \
    "${USER_COMMAND[@]}" \
    --rm \
    "${VOLUME_OPTION[@]}" \
    "${OPENAPI_TYPESCRIPT_IMAGE}" generate \
    -i "${VOLUME_DIR}/patched-api.json" \
    -g typescript-axios \
    -o "${VOLUME_DIR}/${PACKAGE}-client" \
    -t "${VOLUME_DIR}/templates/typescript-axios" \
    --skip-validate-spec \
    --strict-spec=false
fi

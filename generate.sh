#!/bin/bash

set -eu

# set -x

if [ $# -eq 0 ]
then
  cat << EOF
No arguments provided.
$(basename "$0") - Generate client libraries for pulp plugins.

USAGE
    $(basename "$0") <component> [client_language]

DESCRIPTION
    The command will generate a client at the root of the repository inside a directory
    named '{plugin_name}-client/'.

    Learn more on https://pulpproject.org/pulp-openapi-generator

EXAMPLES
    PULP_URL=http://localhost:5001 $(basename "$0") pulp_rpm ruby
        Create pulp_rpm ruby client using api_spec fetched from a Pulp instance at locahost:5001

    USE_LOCAL_API_JSON=/tmp/api.json $(basename "$0") pulp_rpm
        Create pulp_rpm python (default) client using a local api_spec
EOF
  exit 1
fi

# match the component name by removing the "pulp/pulp_" prefix
if [ "$1" = "pulpcore" ]
then
    COMPONENT="core"
else
    COMPONENT=${1#"pulp_"}
fi

# Skip downloading the api.json if `USE_LOCAL_API_JSON` is set.
if [[ -z "${USE_LOCAL_API_JSON:-}" ]]
then
  PULP_URL="${PULP_URL:-http://localhost:24817}"
  PULP_API_ROOT="${PULP_API_ROOT:-/pulp/}"
  PULP_URL="${PULP_URL}${PULP_API_ROOT}api/v3/"

  # Download the schema
  RETRY_COUNT=0
  until curl --fail-with-body -k -o api.json "${PULP_URL}docs/api.json?bindings&component=${COMPONENT}"
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

echo ::group::BINDINGS

./gen-client.sh "${USE_LOCAL_API_JSON:-api.json}" "${COMPONENT}" "${2:-python}" "${1}"

echo ::endgroup::
if [[ -z "${USE_LOCAL_API_JSON:-}" ]]
then
  rm api.json
fi

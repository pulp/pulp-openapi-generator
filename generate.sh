#!/bin/bash

set -eu

if [ $# -eq 0 ]
then
  echo "No arguments provided"
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

./gen-client.sh api.json "${COMPONENT}" "${2:-python}" "${1}"

echo ::endgroup::
if [[ -z "${USE_LOCAL_API_JSON:-}" ]]
then
  rm api.json
fi

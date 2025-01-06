#!/bin/bash
# Utility to diff changes between Pulp override and the original template.

set -eu

function print_usage(){
  echo "Usage: ./diff.sh <lang> <version> <filename>"
  echo "Example: ./diff.sh ruby 7.10.0 gemspec.mustache"
  echo ""
  echo "Original templates:"
  echo "https://github.com/OpenAPITools/openapi-generator/tree/master/modules/openapi-generator/src/main/resources"
}

function validate(){
  ASSERT="${1}"
  MSG="${2:-}"
  if [ "$ASSERT" = 1 ]; then
    if [ -n "$MSG" ]; then echo "$MSG"; fi
    print_usage
    exit 1
  fi
}

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
LANG=${1:-}
VERSION=${2:-}
FILENAME=${3:-}

ARGNUM_VALIDATION=$(( $# != 3 ))

LANG_VALIDATION=$(find templates/ -name "$LANG" -type d | grep -q . || echo 1 )
LANG_ERRORMSG="ERROR: Lang='$LANG' does not have an override dir in templates/"

VERSION_VALIDATION=$(grep -q "^[0-9]"<<<"$VERSION" || echo 1)
VERSION_ERRORMSG="ERROR: Version='$VERSION' should be in the format x.y.z"

FILENAME_VALIDATION=$(find "templates/$LANG" -name "$FILENAME" -type f | grep -q . || echo 1 )
FILENAME_ERRORMSG="ERROR: Filename='$FILENAME' doesnt exit in templates/$LANG/v$VERSION/"

validate "$ARGNUM_VALIDATION"
validate "$VERSION_VALIDATION" "$VERSION_ERRORMSG"
validate "$LANG_VALIDATION" "$LANG_ERRORMSG"
validate "$FILENAME_VALIDATION" "$FILENAME_ERRORMSG"

CLIENT_NAME=$1
if [ "$LANG" = "ruby" ]
then
  CLIENT_NAME="ruby-client"
fi

LOCAL_FILE="$PROJECT_ROOT/templates/$LANG/v$VERSION/$FILENAME"
REMOTE_FILE_URL="https://raw.githubusercontent.com/OpenAPITools/openapi-generator/refs/tags/v$VERSION/modules/openapi-generator/src/main/resources/$CLIENT_NAME/$FILENAME"
git diff "$LOCAL_FILE" <(curl -s "$REMOTE_FILE_URL")

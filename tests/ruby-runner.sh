#!/usr/bin/env bash
# Script to test ruby bindings.
#
# Requirements:
# * A pulp instance running. Configure with PULP_URL. E.g, `export PULP_URL=http://localhost:5001`.
# * Ruby version 2.7 installed. Recommended to use rbenv.

set -mveuo pipefail
GIT_PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$GIT_PROJECT_ROOT"

export PULP_URL="${PULP_URL:-http://localhost:5001}"
COMPONENTS=(pulpcore pulp_file)

function setup-ruby(){
  # Configure "isolated" ruby on host machine
  # https://stackoverflow.com/a/17413767
  TMPDIR="/tmp/ruby-venv"
  rm -rf $TMPDIR
  mkdir -p $TMPDIR/local/gems
  export GEM_HOME=$TMPDIR/local/gems
}

function generate-clients(){
  for plugin in "${COMPONENTS[@]}"; do
    rm -rf ./"${plugin}-client"
    ./generate.sh "${plugin}" ruby
    pushd "${plugin}-client"
      gem build "${plugin}_client"
    popd
  done
}

function install-clients(){
  for plugin in "${COMPONENTS[@]}"; do
    gem install --both "./${plugin}-client/${plugin}_client-*.gem"
  done
}


setup-ruby
generate-clients
install-clients
ruby tests/test_ruby.rb
echo "All tests passed!"

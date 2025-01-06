#!/usr/bin/env bash
# Script to test ruby bindings locally.
#
# Requirements:
# * A pulp instance running locally on localhost:5001.
# * Ruby version 2.7 installed. Recommended to use rbenv.
 
set -mveuo pipefail

# Configure environment
GIT_PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$GIT_PROJECT_ROOT"
export PULP_URL="http://localhost:5001"
 
# Configure "isolated" ruby on host machine
# https://stackoverflow.com/a/17413767 
TMPDIR="/tmp/ruby-venv"
rm -rf $TMPDIR
mkdir -p $TMPDIR/local/gems
export GEM_HOME=$TMPDIR/local/gems

# Generate clients for pulpcore and pulp_file
rm -rf ./pulpcore-client
./generate.sh pulpcore ruby
pushd pulpcore-client
  gem build pulpcore_client
  gem install --both ./pulpcore_client-*.gem
popd

rm -rf ./pulp_file-client
./generate.sh pulp_file ruby
pushd pulp_file-client
gem build pulp_file_client
gem install --both ./pulp_file_client-*.gem
popd

# Run tests
ruby tests/ruby_workflow.rb
echo "All tests passed!"

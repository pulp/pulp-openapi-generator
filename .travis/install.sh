#!/usr/bin/env sh
set -v

export COMMIT_MSG=$(git show HEAD^2 -s)
export PULP_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulpcore\/pull\/(\d+)' | awk -F'/' '{print $7}')
export PULP_SMASH_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/PulpQE\/pulp-smash\/pull\/(\d+)' | awk -F'/' '{print $7}')
export PULP_FILE_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulp_file\/pull\/(\d+)' | awk -F'/' '{print $7}')


cd .. && git clone https://github.com/pulp/pulpcore.git

if [ -n "$PULP_PR_NUMBER" ]; then
  pushd pulpcore
  git fetch origin +refs/pull/$PULP_PR_NUMBER/merge
  git checkout FETCH_HEAD
  popd
fi

pip install -e ./pulpcore[postgres]
cp ./pulpcore/.travis/test_bindings.py $TRAVIS_BUILD_DIR/.travis/
cp ./pulpcore/.travis/test_bindings.rb $TRAVIS_BUILD_DIR/.travis/

if [ -z "$PULP_FILE_PR_NUMBER" ]; then
  pip install git+https://github.com/pulp/pulp_file.git#egg=pulp_file
else
  git clone https://github.com/pulp/pulp_file.git
  pushd pulp_file
  git fetch origin +refs/pull/$PULP_FILE_PR_NUMBER/merge
  git checkout FETCH_HEAD
  pip install -e .
  popd
fi

cd pulp-openapi-generator

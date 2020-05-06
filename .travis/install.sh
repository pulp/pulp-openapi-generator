#!/usr/bin/env sh
set -v

export COMMIT_MSG=$(git show HEAD^2 -s)
export PULP_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulpcore\/pull\/(\d+)' | awk -F'/' '{print $7}')
export PULP_SMASH_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/PulpQE\/pulp-smash\/pull\/(\d+)' | awk -F'/' '{print $7}')
export PULP_FILE_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulp_file\/pull\/(\d+)' | awk -F'/' '{print $7}')
export PULP_CERTGUARD_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulp-certguard\/pull\/(\d+)' | awk -F'/' '{print $7}')


cd .. && git clone --depth=1 https://github.com/pulp/pulpcore.git --branch master

if [ -n "$PULP_PR_NUMBER" ]; then
  pushd pulpcore
  git fetch --depth=1 origin pull/$PULP_PR_NUMBER/head:$PULP_PR_NUMBER
  git checkout $PULP_PR_NUMBER
  popd
fi

pip install -e ./pulpcore[postgres]
sed -i "s/pulp:80/localhost:24817/g" ./pulpcore/.travis/test_bindings.rb
cp ./pulpcore/.travis/test_bindings.py $TRAVIS_BUILD_DIR/.travis/
cp ./pulpcore/.travis/test_bindings.rb $TRAVIS_BUILD_DIR/.travis/

if [ -z "$PULP_FILE_PR_NUMBER" ]; then
  pip install git+https://github.com/pulp/pulp_file.git#egg=pulp_file
else
  git clone --depth=1 https://github.com/pulp/pulp_file.git --branch master
  pushd pulp_file
  git fetch --depth=1 origin pull/$PULP_FILE_PR_NUMBER/head:$PULP_FILE_PR_NUMBER
  git checkout $PULP_FILE_PR_NUMBER
  pip install -e .
  popd
fi

if [ -z "$PULP_CERTGUARD_PR_NUMBER" ]; then
  pip install git+https://github.com/pulp/pulp-certguard.git#egg=pulp-certguard
else
  git clone --depth=1 https://github.com/pulp/pulp-certguard.git --branch master
  pushd pulp-certguard
  git fetch --depth=1 origin pull/$PULP_CERTGUARD_PR_NUMBER/head:$PULP_CERTGUARD_PR_NUMBER
  git checkout $PULP_CERTGUARD_PR_NUMBER
  pip install -e .
  popd
fi

cd pulp-openapi-generator

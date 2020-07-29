# coding=utf-8
set -veuo pipefail

export HTTPIE_CONFIG_DIR=$TRAVIS_BUILD_DIR/.travis

# Run migrations.
export DJANGO_SETTINGS_MODULE=pulpcore.app.settings
export PULP_CONTENT_ORIGIN=http://localhost:24816
export PULP3_HOST=localhost:24817
django-admin makemigrations file --noinput
django-admin migrate --noinput

# Run functional tests.
export DJANGO_SETTINGS_MODULE=pulpcore.app.settings
django-admin reset-admin-password --password password
django-admin runserver 24817 >> ~/django_runserver.log 2>&1 &
gunicorn pulpcore.content:server --bind 'localhost:24816' --worker-class 'aiohttp.GunicornWebWorker' -w 2 >> ~/content_app.log 2>&1 &
rq worker -n 'resource-manager' -w 'pulpcore.tasking.worker.PulpWorker' >> ~/resource_manager.log 2>&1 &
rq worker -n 'reserved-resource-worker_1@%h' -w 'pulpcore.tasking.worker.PulpWorker' >> ~/reserved_worker-1.log 2>&1 &
sleep 12

sudo ./generate.sh pulpcore python
sudo ./generate.sh pulp_file python
pip install requests
pip install ./pulpcore-client
pip install ./pulp_file-client

python .travis/test_bindings.py

sudo rm -rf ./pulpcore-client
sudo rm -rf ./pulp_file-client

./generate.sh pulpcore ruby 0
cd pulpcore-client
gem build pulpcore_client
gem install --both ./pulpcore_client-0.gem
cd ..
./generate.sh pulp_file ruby 0
cd pulp_file-client
gem build pulp_file_client
gem install --both ./pulp_file_client-0.gem
cd ..
ruby .travis/test_bindings.rb

# Travis' scripts use unbound variables. This is problematic, because the
# changes made to this script's environment appear to persist when Travis'
# scripts execute. Perhaps this script is sourced by Travis? Regardless of why,
# we need to reset the environment when this script finishes.
#
# We can't use `trap cleanup_function EXIT` or similar, because this script is
# apparently sourced, and such a trap won't execute until the (buggy!) calling
# script finishes.
set +euo pipefail

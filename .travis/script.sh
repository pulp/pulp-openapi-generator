# coding=utf-8
set -veuo pipefail

# Run migrations.
export DJANGO_SETTINGS_MODULE=pulpcore.app.settings
export PULP_CONTENT_HOST=localhost:24816
export PULP3_HOST=localhost:24817
django-admin makemigrations file --noinput
django-admin migrate --noinput

# Run functional tests.
export DJANGO_SETTINGS_MODULE=pulpcore.app.settings
django-admin reset-admin-password --password admin
django-admin runserver 24817 >> ~/django_runserver.log 2>&1 &
gunicorn pulpcore.content:server --bind 'localhost:24816' --worker-class 'aiohttp.GunicornWebWorker' -w 2 >> ~/content_app.log 2>&1 &
rq worker -n 'resource-manager@%h' -w 'pulpcore.tasking.worker.PulpWorker' >> ~/resource_manager.log 2>&1 &
rq worker -n 'reserved-resource-worker_1@%h' -w 'pulpcore.tasking.worker.PulpWorker' >> ~/reserved_worker-1.log 2>&1 &
sleep 8

sudo ./generate.sh pulpcore 3.0.0rc1 python

sudo ./generate.sh pulp_file 0.1.0b4 ruby

# Travis' scripts use unbound variables. This is problematic, because the
# changes made to this script's environment appear to persist when Travis'
# scripts execute. Perhaps this script is sourced by Travis? Regardless of why,
# we need to reset the environment when this script finishes.
#
# We can't use `trap cleanup_function EXIT` or similar, because this script is
# apparently sourced, and such a trap won't execute until the (buggy!) calling
# script finishes.
set +euo pipefail

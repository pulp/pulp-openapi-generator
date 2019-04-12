pulp-swagger-codegen 
====================

This repository provides a script that helps generate Python bindings for pulpcore or any of it's
plugins. This script can only generate Python bindings at this time.

The first time the script is run, a docker container with swagger-codegen-cli is downloaded. All
subsequent runs will re-use the container that was downloaded on the initial run.

Requirements
------------
Pulp 3 running on localhost:24817
Docker

Generating bindings
-------------------

The ``generate.sh`` script takes two positional arguments: module name, version. The following
commands should be used to generate bindings for ``pulpcore``:

.. code-block:: bash

    sudo ./generate.sh pulpcore

Bindings for the Python plugin can be generated with the following command:

.. code-block:: bash

    sudo ./generate.sh pulp_python


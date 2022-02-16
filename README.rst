pulp-openapi-generator
======================

This repository provides a script that helps generate Python and Ruby bindings for pulpcore or any of it's
plugins.

The first time the script is run, a docker container with openapi-generator-cli is downloaded. All
subsequent runs will re-use the container that was downloaded on the initial run.

Requirements
------------
 - Pulp 3 running on localhost:24817
 - Docker

Generating bindings
-------------------

The ``generate.sh`` script takes three positional arguments: module name, language, and version.
When the optional version parameter is provided, it is used as the version string. When it is not
provided, the version reported by Pulp's status API is used. The following commands should be used
to generate Python bindings for ``pulpcore``:

.. code-block:: bash

    sudo ./generate.sh pulpcore python

This command will generate a python package inside ``pulpcore-client`` directory.

Ruby bindings for the RPM plugin can be generated with the following command:

.. code-block:: bash

    sudo ./generate.sh pulp_rpm ruby

This command will generate a Ruby Gem inside ``pulp_rpm-client`` directory.

The packages generated will have the same version as what is reported by the status API.

This command will generate a Ruby Gem with '3.0.0rc1.dev.10' version.

.. code-block:: bash

    sudo ./generate.sh pulp_rpm ruby 3.0.0rc1.dev.10

Generating Bindings Against Re-Rooted Systems
---------------------------------------------

During bindings generation the openapi schema is fetched. Use the ``PULP_V3_API_ROOT`` environment
variable to instruct the bindings generator where the root of the V3 API is located. For example,
the default ``export PULP_V3_API_ROOT="/pulp/api/v3/"`` is the default root, which then serves the
api.json at ``/pulp/api/v3/docs/api.json``.

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

During bindings generation the openapi schema is fetched. Use the ``PULP_API_ROOT`` environment
variable to instruct the bindings generator where the root of the API is located. For example, the
default ``export PULP_API_ROOT="/pulp/"`` is the default root, which then serves the api.json at
``/pulp/api/v3/docs/api.json``.

Generating Bindings Against Remote Systems
------------------------------------------

During bindings generation the openapi schema is fetched. Use the ``PULP_API`` environment
variable to instruct the bindings generator to use a Pulp API on a different host and/or port.
For example, ``export PULP_API="http://localhost:24817"`` are the default host and port, which
results in the bindings generator talking to the Pulp API at
``http://localhost:24817/pulp/api/v3/docs/api.json``.

Generating Bindings Using a Local Openapi Schema
-----------------------------------------------

If you want to use a locally present openapi schema, you can skip fetching the openapi schema
by setting the ``USE_LOCAL_API_JSON`` environment variable. Doing so you have to manually provide the
``api.json`` file containing the openapi schema in the current working directory.

Generating Bindings on a Filesystem Shared With Another Container
-----------------------------------------------------------------

When the bindings are being generated so that they can be installed inside another container, it
may be necessary to set the MCS label on the openapi-generator-cli container to match the MCS label
of the other container. Users can set the $PULP_MCS_LABEL environment variable (e.g. s0:c1,c2).
When this variable is present, the container for `openapi-generator-cli` will be started with this
MCS label. This only applies to systems that are using `podman` and SELinux is `Enforcing`.

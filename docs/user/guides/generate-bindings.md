# Generate Bindings

Generate a client binding for any Pulp component for the language of your choice.

!!! warning "Language Support"

    Only python and ruby bindings have some testing, although not extensive.

    For python clients, we recommend looking at [pulp-glue] as an alternative.
    That library is handcrafted, handles tasks for you and knows how to deal with different versions of Pulp and plugins.

    If you need to tweak the generator to make it work for your language, have a look at [how it works].

## Overview

- Requirements:
    - git
    - Python 3
    - Docker/Podman
- General workflow:
    1. Clone `pulp-openapi-generator`.
    1. Get the openapi schema for the desired Pulp components.
    1. Run the generator cli from the the repository

## Setup

To get started, first clone the repo into your machine.
It'll be used as the workspace for the bindings generation.

```bash
git clone https://github.com/pulp/pulp-openapi-generator
cd pulp-openapi-generator
```

## Get the schema

There are two basic options to get an openapi schema: (1) from an installed package and (2) from a running installation.

Note that the `api.spec` must be generated with the `--bindings` flag/url-option.
That spec is tailored for bindings generation and isn't a fully compliant `api.spec`.

1. From a python environment with Pulp packages installed.

    ```bash
    pulpcore-manager openapi --bindings \
        --component "core" \
        --file "core-api.json"
    ```

    Some Pulp settings affect client generation directly (e.g, `API_ROOT` and `DOMAIN_ENABLED`).
    If you run this command outside of a Pulp operating enviroment,
    you may need to pass an additional `--settings settings.py` parameter pointing to the corresponding settings of your target installation.

1. From a running pulp instance:

    ```bash
    PULP_URL="http://pulp.example/pulp/api/v3/"
    COMPONENT="core"
    URL="${PULP_URL}docs/api.json?bindings&component=${COMPONENT}"
    curl "${URL}" -o "${COMPONENT}-api.json"
    ```

## Generate the client

The script uses the [openapi-generator-cli image] to generate the clients, so the first run may take some time to download it.

In the example, a ruby package for pulpcore will be generated at `./pulp_rpm-client/` using an existing schema `rpm-api.json`:

```bash
./gen-client.sh rpm-api.json rpm ruby
```

## Further reading

- For Docker-in-Docker (dind) environments, see the [PARENT_CONTAINER_ID] setting.
- For filesystem shared with another container, see the [PULP_MCS_LABEL] setting.
- If you are upgrading pulpcore to `>3.70`, check the [migration guide].

[how it works]: site:pulp-openapi-generator/docs/user/learn/how-it-works/
[migration guide]: site:pulp-openapi-generator/docs/user/guides/version-migrations/
[openapi-generator-cli image]: https://openapi-generator.tech/docs/installation/#docker
[parent_container_id]: site:pulp-openapi-generator/docs/user/reference/settings/#parent_container_id
[pulp-glue]: site:pulp-glue/docs/dev/
[pulp_mcs_label]: site:pulp-openapi-generator/docs/user/reference/settings/#pulp_mcs_label.

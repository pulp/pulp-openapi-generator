# Generate Bindings

* Requirements:
    * Docker/Podman compose
* General workflow:
    1. Clone `pulp-openapi-generator`.
    2. Get the openapi schema for the desired Pulp components.
    3. Run the generator cli from the the repository

## 1) Setup

To get started, first clone the repo into your machine.
It'll be used as the workspace for the bindings generation.

```bash
git clone https://github.com/pulp/pulp-openapi-generator
cd pulp-openapi-generator
```

## 2) Get the schema

Here are some options to get a openapi schema:

1. From a python environment with Pulp packages installed:

    ```bash
    pulpcore-manager openapi --bindings \
        --component "core" \
        --file "core-api.json"      
    ```

2. From a running pulp instance:

    ```bash
    PULP_URL="http://localhost:24817/pulp/api/v3/"
    COMPONENT="core"
    URL="${PULP_URL}docs/api.json?bindings&component=${COMPONENT}"
    curl "${URL}" -o "${COMPONENT}-api.json"
    ```

## 3) Generate the client

The script uses the [openapi-generator-cli image] to generate the clients, so the first run may take some time to download it.

In the example, a ruby package for pulpcore will be generated at `./pulp_rpm-client/` using an existing schema `rpm-api.json`:

```bash
./gen-client.sh rpm-api.json rpm ruby
```

## Further reading

- For Docker-in-Docker (dind) environments, see the [PARENT_CONTAINER_ID] setting.
- For filesystem shared with another container, see the [PULP_MCS_LABEL] setting.
- If you are upgrading pulpcore to `>3.70`, check the [migration guide].

[pulp_mcs_label]: site:pulp-openapi-generator/docs/user/reference/settings/#pulp_mcs_label.
[parent_container_id]: site:pulp-openapi-generator/docs/user/reference/settings/#parent_container_id
[migration guide]: site:pulp-openapi-generator/docs/user/guides/version-migrations/
[settings reference]: site:pulp-openapi-generator/docs/user/reference/settings/
[openapi-generator-cli image]: https://openapi-generator.tech/docs/installation/#docker

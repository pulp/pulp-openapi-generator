# Quickstart

!!! note "Docker/Podman is required"

    The first time the script is run, a docker container with openapi-generator-cli is downloaded. All
    subsequent runs will re-use the container that was downloaded on the initial run.

First, clone the repo into your machine. It'll be used as the workspace for the bindings generation.
Then, choose methods A or B.

In any case, the final packages are stored in the `{plugin_label}-client` directory.

```bash
git clone https://github.com/pulp/pulp-openapi-generator
```

## A) Generate from running Pulp

Configure the settings for you Pulp instance using [`PULP_URL`](#pulp_url) and [`PULP_API_ROOT`](#pulp_api_root).
The generator will fetch the openapi schema directly from it to generate the client.

The command below will generate a ruby client for pulp_rpm at `./pulp_rpm-client/`.

```bash
PULP_URL="http://localhost:5001" ./generate.sh pulp_rpm ruby
```

## B) Generate from schema file

This will use an existing openapi schema file, which is configurable using [`USE_LOCAL_API_JSON`](#use_local_api_json).

The command below will generate a python client (default) for pulp_maven at `./pulp_maven-client/`.

```bash
USE_LOCAL_API_JSON="pulp_maven-api.json" ./generate.sh pulp_maven
```

!!! tip "Get a schema without a running instance"

    Pulpcore provides a management command that creates the openapi schema without requiring a running instance.

    A possible workflow is to create a virtual environment with pulp package installed and run:

    ```bash
    pulpcore-manager openapi --bindings --component "core" --file "core-api.json"      
    USE_LOCAL_API_JSON="pulpcore-api.json" ./generate.sh pulpcore
    ```


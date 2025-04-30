# Overview

This repository provides a script that helps generate Python and Ruby bindings for pulpcore or any of it's
plugins.

!!! note "Docker/Podman is required"

    The first time the script is run, a docker container with openapi-generator-cli is downloaded. All
    subsequent runs will re-use the container that was downloaded on the initial run.


## Quickstart

First, clone the repo into your machine. It'll be used as the workspace for the bindings generation.
Then, choose methods A or B.

In any case, the final packages are stored in the `{plugin_label}-client` directory.

```bash
git clone https://github.com/pulp/pulp-openapi-generator
```

### A) Generate from running Pulp

Configure the settings for you Pulp instance using [`PULP_URL`](#pulp_url) and [`PULP_API_ROOT`](#pulp_api_root).
The generator will fetch the openapi schema directly from it to generate the client.

The command below will generate a ruby client for pulp_rpm at `./pulp_rpm-client/`.

```bash
PULP_URL="http://localhost:5001" ./generate.sh pulp_rpm ruby
```

### B) Generate from schema file

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

## Settings

### `PULP_URL`

**For Remote Instances**.
Instruct the bindings generator to use a Pulp API on a different host and/or port.
Default: `http://localhost:24817`.

For example, the default host and port results in the bindings generator talking to the Pulp API at
`http://localhost:24817/pulp/api/v3/docs/api.json`.

### `PULP_API_ROOT`

**For Re-Rooted Systems**.
Instructs the bindings generator where the root of the API is located.

For example, the default `export PULP_API_ROOT="/pulp/"` is the default root, which then serves the api.json at
`/pulp/api/v3/docs/api.json`.

### `USE_LOCAL_API_JSON`

**For local openapi schema files**.
Instructs the bindings generator to skip fetching the schema from the API and use a local schema file.

The schema file (e.g `api.json`) containing the openapi schema should be in current working directory.


### `PARENT_CONTAINER_ID`

**For Docker-in-Docker (dind) environments**.
Specify the parent container.

Bindings are generated using the openapi-generator-cli docker container. If your environment itself runs in
a docker container, the openapi-generator-cli container has to be started as a sibling container. For
sibling containers, volumes cannot be mounted as usual. They have to be passed through from the parent
container. 

### `PULP_MCS_LABEL`

**For filesystem shared with another container**.
Set MCS (Multi-Category Security) labels to generator container (e.g. `s0:c1,c2`).

When the bindings are being generated so that they can be installed inside another container, it
may be necessary to set the MCS label on the openapi-generator-cli container to match the MCS label
of the other container.
When this variable is present, the container for `openapi-generator-cli` will be started with this
MCS label. This only applies to systems that are using `podman` and SELinux is `Enforcing`.




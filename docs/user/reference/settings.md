# Settings

## `PULP_URL`

**For Remote Instances**.
Instruct the bindings generator to use a Pulp API on a different host and/or port.
Default: `http://localhost:24817`.

For example, the default host and port results in the bindings generator talking to the Pulp API at
`http://localhost:24817/pulp/api/v3/docs/api.json`.

## `PULP_API_ROOT`

**For Re-Rooted Systems**.
Instructs the bindings generator where the root of the API is located.

For example, the default `export PULP_API_ROOT="/pulp/"` is the default root, which then serves the api.json at
`/pulp/api/v3/docs/api.json`.

## `USE_LOCAL_API_JSON`

**For local openapi schema files**.
Instructs the bindings generator to skip fetching the schema from the API and use a local schema file.

The schema file (e.g `api.json`) containing the openapi schema should be in current working directory.


## `PARENT_CONTAINER_ID`

**For Docker-in-Docker (dind) environments**.
Specify the parent container.

Bindings are generated using the openapi-generator-cli docker container. If your environment itself runs in
a docker container, the openapi-generator-cli container has to be started as a sibling container. For
sibling containers, volumes cannot be mounted as usual. They have to be passed through from the parent
container. 

## `PULP_MCS_LABEL`

**For filesystem shared with another container**.
Set MCS (Multi-Category Security) labels to generator container (e.g. `s0:c1,c2`).

When the bindings are being generated so that they can be installed inside another container, it
may be necessary to set the MCS label on the openapi-generator-cli container to match the MCS label
of the other container.
When this variable is present, the container for `openapi-generator-cli` will be started with this
MCS label. This only applies to systems that are using `podman` and SELinux is `Enforcing`.

## `USE_GENERATOR_VERSION`

**For building clients with non-standard versions**.
Specify the OpenAPI-Generator image version to use.

This is not guaranted to work.

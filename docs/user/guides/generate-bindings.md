# Generate Bindings

## Requirements

- Pulp 3 running on `localhost:24817`
- Docker or Podman

## Basic Usage


The `generate.sh` script takes three positional arguments:

```
./generate.sh <module-name> <language> [<version>]  
```

When the optional version parameter is provided, it is used as the version string.
When it is not provided, the version reported by Pulp's status API is used.

The final packages are stored in the `{plugin_label}-client` directory.

Examples:

```bash
# Create Python Package in 'pulpcore-client/'.
# Uses API reported  version
sudo ./generate.sh pulpcore python

# Create Ruby Gem in 'pulp_rpm-client/'.
# Uses API reported version
sudo ./generate.sh pulp_rpm ruby

# Create Ruby Gem 'pulp_rpm-client/'.
# Uses '3.0.0rc1.dev.10' version
sudo ./generate.sh pulp_rpm ruby 3.0.0rc1.dev.10
```

## Special Cases

### Re-Rooted Systems

During bindings generation the openapi schema is fetched. Use the `PULP_API_ROOT` environment
variable to instruct the bindings generator where the root of the API is located. For example, the
default `export PULP_API_ROOT="/pulp/"` is the default root, which then serves the api.json at
`/pulp/api/v3/docs/api.json`.

### Remote Systems

During bindings generation the openapi schema is fetched. Use the `PULP_API` environment
variable to instruct the bindings generator to use a Pulp API on a different host and/or port.
For example, `export PULP_API="http://localhost:24817"` are the default host and port, which
results in the bindings generator talking to the Pulp API at
`http://localhost:24817/pulp/api/v3/docs/api.json`.

### Local Openapi Schema

If you want to use a locally present openapi schema, you can skip fetching the openapi schema
by setting the `USE_LOCAL_API_JSON` environment variable. Doing so you have to manually provide the
`api.json` file containing the openapi schema in the current working directory.

### Docker in Docker (dind)

Bindings are generated using the openapi-generator-cli docker container. If your environment itself runs in
a docker container, the openapi-generator-cli container has to be started as a sibling container. For
sibling containers, volumes cannot be mounted as usual. They have to be passed through from the parent
container. For this to work you have to set the `PARENT_CONRAINER_ID` environment variable to specify the
parent container in a dind environment.

### Filesystem Shared With Another Container

When the bindings are being generated so that they can be installed inside another container, it
may be necessary to set the MCS label on the openapi-generator-cli container to match the MCS label
of the other container. Users can set the \$PULP_MCS_LABEL environment variable (e.g. s0:c1,c2).
When this variable is present, the container for `openapi-generator-cli` will be started with this
MCS label. This only applies to systems that are using `podman` and SELinux is `Enforcing`.

# Generate client bindings

## Usage

A general workflow for generating your own bindings.

1. Install the `pulp-bindings` package
2. Get the API schema (with or without a running Pulp)
3. Generate the client
4. Run the docs

### 1. Install pulp-bindings

The `pulp-bindgins` package uses CalVer.
Choose a version from the [tags](https://github.com/pulp/pulp-openapi-generator/tags) and install it.

```bash
VERSION="20240812.0"
pip install git+https://github.com/pulp/pulp-openapi-generator@${VERSION}
```

### 2. Get the API schema

The variables in use:

- `PACKAGE`: the python package name. E.g `pulpcore`, `pulp_container`.
- `COMPONENT`: the plugin label. E.g `core` for `pulpcore`, `rpm` for `pulp_rpm`.

=== "Without a running Pulp"

    Install the plugin of your choice in a virtual environment and generate the API schema.

    ```bash
    python -m venv venv
    ./venv/bin/python -m pip install "${PACKAGE}"
    ./venv/bin/pulpcore-manager openapi --bindings \
        --component "${COMPONENT}" \  # required
        --output "${COMPONENT}-api.json"  # default
    ```

=== "With a running Pulp"

    Use your settings to fetch the API from the Pulp instance.

    ```bash
    pulp-bindings download-spec \
        --plugin "${COMPONENT}" \  # required
        --host http://localhost:24817 \  # default
        --api-root /pulp/ \  # default
        --output "${COMPONENT}-api.json"  # default
    ```

### 3. Generate client

This will create a directory with the client code and the respective docs.

```bash
pulp-bindings generate \
    --plugin "${COMPONENT}" \  # required
    --language python \  # required
    --input-spec "path/to/${COMPONENT}.json"  # defaults: ./${COMPONENT}-api.json
    --output "${PACKAGE}-client"  # default
```

### 4. Run the docs

This will run an mkdocs server with the generated markdown docs.

```bash
pulp-bindings run-docs \
    --client-dir "${PACKAGE}-client" \  # required
    --port 54321  # default
```

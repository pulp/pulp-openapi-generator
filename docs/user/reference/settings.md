# Settings

## `PARENT_CONTAINER_ID`

**For Docker-in-Docker (dind) environments**.
Specify the parent container.

Bindings are generated using the openapi-generator-cli docker container.
If your environment itself runs in a docker container, the openapi-generator-cli container has to be started as a sibling container.
For sibling containers, volumes cannot be mounted as usual.
They have to be passed through from the parent container.

## `PULP_MCS_LABEL`

**For filesystem shared with another container**.
Set MCS (Multi-Category Security) labels to generator container (e.g. `s0:c1,c2`).

When the bindings are being generated so that they can be installed inside another container,
it may be necessary to set the MCS label on the openapi-generator-cli container to match the MCS label of the other container.
When this variable is present, the container for `openapi-generator-cli` will be started with this MCS label.
This only applies to systems that are using `podman` and SELinux is `Enforcing`.

# Version Migrations

The [openapi-generator-cli image] version used depends on the pulpcore version.

This guide list known breaking changes and recommended compatibility actions for pulpcore upgrade paths.

## pulpcore `<3.70` to `>=3.70`

Upgrading pulpcore from a `<3.70` to a `>=3.70` version will bump the `openapi-generator-cli` version from `4.3.1` to `7.10.0`.

### Python

- `Response.to_dict()|.to_json()` returns a dictionary without read-only fields.
    - **Example**: `pulp_href` isn't present anymore.
    - **Actions**: Use `Response.model_dump()`. See [model_dump docs].
- Client-side validation is more strict.
    - **Example**: Error handling depending on server-errors might break.
    - **Actions**: Update code to use client-side errors.
- Clients now use named arguments instead of positional ones
    - **Action**: Use named arguments.
- Object such as Path or UUID are not accepted as input
    - **Action**: Cast to string. E.g `str(uuid)` and `str(path)`.

### Ruby

Unknown.

[model_dump docs]: https://docs.pydantic.dev/2.10/concepts/serialization/#modelmodel_dump
[openapi-generator-cli image]: https://hub.docker.com/r/openapitools/openapi-generator-cli

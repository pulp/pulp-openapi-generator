# How it works

Pulp OpenAPI Generator builds upon the [OpenAPI Generator CLI] to provide client bindings tailored for Pulp's API.
Here's what it does on top of it.

## Template Overrides

The generator uses Mustache templates that override the standard [OpenAPI Generator templates].
These templates are used for the language-specific code generation.
They are organized by language and version in the `templates/` directory.

For example, `templates/ruby/7.10.0/gemspec.mustache` will override the [original file with the same name] in the openapi-generator repository for that version.

To avoid getting too much into the generator internals, we try to use it only when absolutely required.

## Custom Parameters

The Pulp generator script reads Pulp specific fields from the `api.spec` (such as Domain enabled)
and passes specific parameters to [configure the OpenAPI Generator CLI].
E.g, set namings, define appropriate version information, set domains and configure flags that make the client more stable.

For this to work, the `api.spec` needs to be generated with the `--bindings` option/url-parameter as shown in the [generate-bindings guide],
which results in a not fully compliant api spec.

## Version Management

Pulp supports multiple branches of pulpcore, and it uses python bindings in all the CI functional tests.
To keep everything working and being able to upgrade the generator cli version, we have a pinning mechanism in place to couple pulpcore with the generator version.

This versioning system is documented in the [version-migrations guide].

[configure the openapi generator cli]: https://openapi-generator.tech/docs/configuration
[generate-bindings guide]: site:pulp-openapi-generator/docs/user/guides/generate-bindings/#2-get-the-schema
[openapi generator cli]: https://openapi-generator.tech/docs/installation#docker
[openapi generator templates]: https://openapi-generator.tech/docs/templating
[original file with the same name]: https://github.com/OpenAPITools/openapi-generator/blob/v7.10.0/modules/openapi-generator/src/main/resources/ruby-client/gemspec.mustache
[version-migrations guide]: site:pulp-openapi-generator/docs/user/guides/version-migrations/

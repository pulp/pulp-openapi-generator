if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi

# Download the schema
curl -o api.json "http://localhost:24817/pulp/api/v3/docs/api.json?bindings&plugin=$1"
# Get the version of the pulpcore or plugin as reported by status API

if [ $# -gt 2 ];
then
    export VERSION=$3
else
    export VERSION=$(http :24817/pulp/api/v3/status/ | jq --arg plugin $1 -r '.versions[] | select(.component == $plugin) | .version')
fi

echo ::group::BINDINGS
if [ $2 = 'python' ]
then
    podman run -u $(id -u) --rm -v ${PWD}:/local openapitools/openapi-generator-cli:v4.3.1 generate \
        -i /local/api.json \
        -g python \
        -o /local/$1-client \
        --additional-properties=packageName=pulpcore.client.$1,projectName=$1-client,packageVersion=${VERSION} \
        -t /local/templates/python \
        --skip-validate-spec \
        --strict-spec=false
    ls -al $1-client
    cp python/__init__.py $1-client/pulpcore/
    cp python/__init__.py $1-client/pulpcore/client
fi
if [ $2 = 'ruby' ]
then
    python3 remove-cookie-auth.py
    podman run -u $(id -u) --rm -v ${PWD}:/local openapitools/openapi-generator-cli:v4.2.3 generate \
        -i /local/api.json \
        -g ruby \
        -o /local/$1-client \
        --additional-properties=gemName=$1_client,gemLicense="GPL-2.0+",gemVersion=${VERSION} \
        --library=faraday \
        --skip-validate-spec \
        --strict-spec=false
fi
if [ $2 = 'typescript' ]
then
    podman run -u $(id -u) --rm -v ${PWD}:/local openapitools/openapi-generator-cli:v5.0.0 generate \
        -i /local/api.json \
        -g typescript-axios \
        -o /local/$1-client \
        --skip-validate-spec \
        --strict-spec=false
fi

echo ::endgroup::
rm api.json

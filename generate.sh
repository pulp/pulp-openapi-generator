if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi

PULP_URL="${PULP_URL:-http://localhost:24817}"

# Download the schema
curl -k -o api.json "$PULP_URL/pulp/api/v3/docs/api.json?bindings&plugin=$1"
# Get the version of the pulpcore or plugin as reported by status API

if [ $# -gt 2 ];
then
    export VERSION=$3
else
    export VERSION=$(http $PULP_URL/pulp/api/v3/status/ | jq --arg plugin $1 -r '.versions[] | select(.component == $plugin) | .version')
fi

echo ::group::BINDINGS
if [ $2 = 'python' ]
then
    docker run -u $(id -u) --rm -v ${PWD}:/local openapitools/openapi-generator-cli:v4.3.1 generate \
        -i /local/api.json \
        -g python \
        -o /local/$1-client \
        --additional-properties=packageName=pulpcore.client.$1,projectName=$1-client,packageVersion=${VERSION} \
        -t /local/templates/python \
        --skip-validate-spec \
        --strict-spec=false
    cp python/__init__.py $1-client/pulpcore/
    cp python/__init__.py $1-client/pulpcore/client
fi
if [ $2 = 'ruby' ]
then
    python3 remove-cookie-auth.py
    docker run -u $(id -u) --rm -v ${PWD}:/local openapitools/openapi-generator-cli:v4.3.1 generate \
        -i /local/api.json \
        -g ruby \
        -o /local/$1-client \
        --additional-properties=gemName=$1_client,gemLicense="GPL-2.0+",gemVersion=${VERSION} \
        --library=faraday \
        -t /local/templates/ruby \
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

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi

# Download the schema
curl -o api.json "http://localhost:24817/pulp/api/v3/docs/api.json?bindings&plugin=$1"
# Get the version of the pulpcore or plugin as reported by status API

if [ ${3-x} ];
then
    export VERSION=$3
else
    export VERSION=$(http :24817/pulp/api/v3/status/ | jq --arg plugin $1 -r '.versions[] | select(.component == $plugin) | .version')
fi

if [ $2 = 'python' ]
then
    docker run -u $(id -u) --rm -v ${PWD}:/local openapitools/openapi-generator-cli:v4.2.3 generate \
        -i /local/api.json \
        -g python \
        -o /local/$1-client \
        --additional-properties=packageName=pulpcore.client.$1,projectName=$1-client,packageVersion=${VERSION} \
        --skip-validate-spec \
        --strict-spec=false
    cp python/__init__.py $1-client/pulpcore/
    cp python/__init__.py $1-client/pulpcore/client
fi
if [ $2 = 'ruby' ]
then
    docker run -u $(id -u) --rm -v ${PWD}:/local openapitools/openapi-generator-cli:v4.2.3 generate \
        -i /local/api.json \
        -g ruby \
        -o /local/$1-client \
        --additional-properties=gemName=$1_client,gemLicense="GPL-2.0+",gemVersion=${VERSION} \
        --library=faraday \
        --skip-validate-spec \
        --strict-spec=false
fi

rm api.json

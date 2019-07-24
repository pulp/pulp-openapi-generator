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
    docker run -u $(id -u) --rm -v ${PWD}:/local openapitools/openapi-generator-cli:v4.0.2 generate \
        -i /local/api.json \
        -g python \
        -o /local/$1-client \
        -DpackageName=pulpcore.client.$1 \
        -DprojectName=$1-client \
        -DpackageVersion=${VERSION} \
        --skip-validate-spec \
        --strict-spec=false
    cp python/__init__.py $1-client/pulpcore/
    cp python/__init__.py $1-client/pulpcore/client
fi
if [ $2 = 'ruby' ]
then
    if [ ! -f ./openapi-generator-cli.jar ]
    then
        curl -o openapi-generator-cli.jar https://repos.fedorapeople.org/pulp/pulp/openapi/openapi-generator-cli.jar
    fi
    java -jar openapi-generator-cli.jar generate \
        -i api.json \
        -g ruby \
        -o $1-client \
        -DgemName=$1_client \
        -DgemLicense="GPL-2.0" \
        -DgemVersion=${VERSION} \
        -Dlibrary=faraday \
        --skip-validate-spec \
        --strict-spec=false
fi

rm api.json

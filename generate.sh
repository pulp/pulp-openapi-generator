if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi

# Download the schema
curl -o api.json http://localhost:24817/pulp/api/v3/docs/api.json?plugin=$1
# Get the version of the pulpcore or plugin as reported by status API
export VERSION=$(http :24817/pulp/api/v3/status/ | jq --arg plugin $1 -r '.versions[] | select(.component == $plugin) | .version')

if [ $2 = 'python' ]
then
    if [ ${3-x} ];
    then
        export VERSION=$VERSION.dev.1
    fi
    docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli generate \
        -i /local/api.json \
        -l python \
        -o /local/$1-client \
        -DpackageName=pulpcore.client.$1 \
        -DprojectName=$1-client \
        -DpackageVersion=${VERSION}
    cp python/__init__.py $1-client/pulpcore/
    cp python/__init__.py $1-client/pulpcore/client
    # There is a bug in swagger-codegen. When using package names within a namespace it creates the package
    # accross 2 different directories. We move everything back into place here.
    cp $1-client/pulpcore.client.$1/* $1-client/pulpcore/client/$1/
    cp $1-client/pulpcore.client.$1/api/* $1-client/pulpcore/client/$1/api/
    cp $1-client/pulpcore.client.$1/models/* $1-client/pulpcore/client/$1/models/
    # Then remove the wrong directory
    rm -rf $1-client/pulpcore.client.$1
fi
if [ $2 = 'ruby' ]
then
    if [ ${3-x} ];
    then
        export VERSION=$VERSION-$3
    fi
    docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli generate \
        -i /local/api.json \
        -l ruby \
        -o /local/$1-client \
        -DgemName=$1_client \
        -DgemLicense="GPLv2" \
        -DgemVersion=${VERSION}
fi

rm api.json

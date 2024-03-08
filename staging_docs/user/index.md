# Overview

This repository provides a script that helps generate Python and Ruby bindings for pulpcore or any of it's
plugins.

The first time the script is run, a docker container with openapi-generator-cli is downloaded. All
subsequent runs will re-use the container that was downloaded on the initial run.



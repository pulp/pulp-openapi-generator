#!/usr/bin/env bash

# WARNING: DO NOT EDIT!
#
# This file was generated by plugin_template, and is managed by it. Please use
# './plugin-template --github pulp_file' to update this file.
#
# For more info visit https://github.com/pulp/plugin_template

# make sure this script runs at the repo root
cd "$(dirname "$(realpath -e "$0")")"/../../..

set -euv

TAG="${TAG:-latest}"

mkdir -p .ci/ansible/vars
cd .ci/ansible/

cat >> vars/main.yaml << VARSYAML
---
services:
  - name: pulp
    image: "ghcr.io/pulp/pulp:${TAG}"
    volumes:
      - ./settings:/etc/pulp
VARSYAML

cat >> vars/main.yaml << VARSYAML
pulp_settings: {"allowed_content_checksums": ["sha1", "sha224", "sha256", "sha384", "sha512"], "allowed_export_paths": ["/tmp"], "allowed_import_paths": ["/tmp"]}
VARSYAML

# ansible-playbook build_container.yaml
ansible-playbook start_container.yaml

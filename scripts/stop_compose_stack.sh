#!/usr/bin/env bash

set -Eeo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; # "
ROOT_DIR="${SCRIPT_DIR%/*}"
DOCKER_DIR="${ROOT_DIR}/docker"

# Stop the containers and cleanup all volumes, if asked to.
if [[ "$1" == "--cleanup" ]]; then
    docker-compose -f "${DOCKER_DIR}"/docker-compose.yaml down --volumes
else
    docker-compose -f "${DOCKER_DIR}"/docker-compose.yaml down
fi

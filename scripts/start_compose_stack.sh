#!/usr/bin/env bash

set -Eeo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; # "
ROOT_DIR="${SCRIPT_DIR%/*}"
DOCKER_DIR="${ROOT_DIR}/docker"

"${SCRIPT_DIR}"/extract_latest_backup.sh

docker-compose -f "${DOCKER_DIR}"/docker-compose.yaml up -d

# Hackaround: Change permissions of all WordPress files.
docker-compose -f "${DOCKER_DIR}"/docker-compose.yaml exec wordpress chgrp -R www-data /var/www/html/

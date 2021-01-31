#!/usr/bin/env bash

set -Eeo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; # "
ROOT_DIR="${SCRIPT_DIR%/*}"
BACKUPS_DIR="${ROOT_DIR}/backupwordpress"

cd "${BACKUPS_DIR}" || exit 1

printf 'Cleanup previous files...'
rm -rf "${BACKUPS_DIR}/extracted/"
printf ' Done.\n'

# Extract the latest backup archives.
# Since they have naming format bodyrespect-ch-1611051791-database-2021-01-23-02-58-56.zip,
# we can simply pick the last in lexicographical order.
COMPLETE="$(find . -name "*complete*.zip" | sort | tail -1)"
DATABASE="$(find . -name "*database*.zip" | sort | tail -1)"

printf 'Extracting %s...' "${COMPLETE}"
unzip -d extracted -q "${COMPLETE}"
printf ' Done.\n'

printf 'Extracting %s...' "${DATABASE}"
unzip -d extracted -q "${DATABASE}"
printf ' Done.\n'

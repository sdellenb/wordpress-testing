#!/usr/bin/env bash

set -Eeo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; # "
ROOT_DIR="${SCRIPT_DIR%/*}"
BACKUPS_DIR="${ROOT_DIR}/backupwordpress"

cd "${BACKUPS_DIR}" || exit 1

printf 'Cleanup previous files...'
rm -rf "${BACKUPS_DIR}/extracted/" "${BACKUPS_DIR}/db_dumps/"
printf ' Done.\n'

# Extract the latest backup archives.
# Since they have naming format bodyrespect-ch-1611051791-database-2021-01-23-02-58-56.zip,
# we can simply pick the last in lexicographical order.
LATEST_COMPLETE="$(find . -name "*complete*.zip" | sort | tail -1)"
LATEST_DATABASE="$(find . -name "*database*.zip" | sort | tail -1)"

[[ ! -f "${LATEST_COMPLETE}" ]] && echo "Error: complete backup file is required." && exit 1

printf 'Extracting %s...' "${LATEST_COMPLETE}"
unzip -d extracted -q "${LATEST_COMPLETE}"
printf ' Done.\n'

# Separate DB-only backup is optional.
if [[ -f "${LATEST_DATABASE}" ]]; then
  printf 'Extracting %s...' "${LATEST_DATABASE}"
  unzip -d extracted -q "${LATEST_DATABASE}"
  printf ' Done.\n'
fi

# Separate the latest DB Dump from the Wordpress folder contents and give it a fixed name for the import.
unset -v latest
for file in extracted/*.sql; do
  [[ $file -nt $latest ]] && latest=$file
done
mkdir db_dumps
mv "$latest" db_dumps/00-latest.sql
 # Cleanup all older dumps
rm -f extracted/*.sql

# Replace all links in the dump to point to the container.
# Source: https://www.wpbeginner.com/wp-tutorials/how-to-move-live-wordpress-site-to-local-server/
SITEURL=$(awk -F\' '/siteurl/ {print $4}' db_dumps/00-latest.sql)
TABLE_PREFIX=$(awk -F\' '/table_prefix/ {print $2}' extracted/wp-config.php)
DB_CHARSET=$(awk -F\' '/DB_CHARSET/ {print $4}' extracted/wp-config.php)
DB_COLLATE=$(awk -F\' '/DB_COLLATE/ {print $4}' extracted/wp-config.php)
cat <<EOT >> db_dumps/01-update_siteurl.sql
UPDATE ${TABLE_PREFIX}options SET option_value = replace(option_value, '${SITEURL}', 'http://localhost:8000') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE ${TABLE_PREFIX}posts SET post_content = replace(post_content, '${SITEURL}', 'http://localhost:8000');
UPDATE ${TABLE_PREFIX}postmeta SET meta_value = replace(meta_value,'${SITEURL}','http://localhost:8000');
EOT

# Generate the environment override file from the wp-config values, as that file will be replaced the auto-generated one.
{
  printf 'WORDPRESS_TABLE_PREFIX=%s\n' "${TABLE_PREFIX}"
  printf 'WORDPRESS_DB_CHARSET=%s\n' "${DB_CHARSET}"
  printf 'WORDPRESS_DB_COLLATE=%s\n' "${DB_COLLATE}"

 } > "${ROOT_DIR}"/docker/wordpress.env

# Delete the old config file to get the auto-generated one provided in the Docker image, which allows for environment variable overrides.
rm -f extracted/wp-config.php

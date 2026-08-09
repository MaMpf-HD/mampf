#!/bin/sh
set -e

workspace_folder="${1:?The local workspace folder is required.}"
workspace_parent="${2:-$(dirname "${workspace_folder}")}"
infra_folder="${workspace_parent}/mampf-infra"
compose_file="${workspace_folder}/.devcontainer/compose.mampf-infra.yml"

if [ -d "${infra_folder}" ]; then
    cat > "${compose_file}" <<'YAML'
services:
  app:
    volumes:
      - ../../../mampf-infra:/workspaces/mampf-infra
YAML
else
    cat > "${compose_file}" <<'YAML'
services: {}
YAML
fi

if [ "$(id -u)" = "0" ]; then
  chown "$(stat -c '%u:%g' "${workspace_folder}")" "${compose_file}"
fi
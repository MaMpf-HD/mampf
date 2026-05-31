#!/bin/bash
set -e

create_infra_venv() {
  rm -rf /workspaces/mampf-infra/.venv
  python3 -m venv /workspaces/mampf-infra/.venv
}

if ! create_infra_venv; then
  python_minor="$(python3 - <<'PY'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
PY
)"
  sudo apt-get update
  sudo apt-get install -y python3-venv || true
  sudo apt-get install -y "python${python_minor}-venv" || true
  create_infra_venv
fi

. /workspaces/mampf-infra/.venv/bin/activate
pip install --upgrade pip
pip install ansible
ansible-galaxy collection install \
  -r /workspaces/mampf-infra/collections/requirements.yml \
  -p /workspaces/mampf-infra/collections
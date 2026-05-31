#!/bin/bash
set -e

infra_root=/workspaces/mampf-infra
uv_bin="$HOME/.local/bin/uv"

ensure_uv() {
  if [ ! -x "$uv_bin" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
}

ensure_python_312() {
  "$uv_bin" python install 3.12
}

create_infra_venv() {
  rm -rf "$infra_root/.venv"
  python_312="$("$uv_bin" python find 3.12)"
  "$python_312" -m venv "$infra_root/.venv"
}

ensure_uv
ensure_python_312
create_infra_venv

cd "$infra_root"
. .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
ansible-galaxy collection install \
  -r collections/requirements.yml \
  -p collections
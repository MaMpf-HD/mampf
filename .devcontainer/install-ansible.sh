#!/bin/bash
set -e

infra_root=/workspaces/mampf-infra
uv_bin="$HOME/.local/bin/uv"
uv_version="0.11.26"

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ssh-askpass

ensure_uv() {
  if [ -x "$uv_bin" ]; then
    return
  fi
  local arch="uv-x86_64-unknown-linux-gnu"
  local base="https://github.com/astral-sh/uv/releases/download/${uv_version}"
  local tmp
  tmp="$(mktemp -d)"
  curl -LsSf -o "${tmp}/${arch}.tar.gz" "${base}/${arch}.tar.gz"
  curl -LsSf -o "${tmp}/${arch}.tar.gz.sha256" "${base}/${arch}.tar.gz.sha256"
  # Verify the download against uv's published checksum, then install the binary.
  ( cd "${tmp}" && sha256sum -c "${arch}.tar.gz.sha256" )
  tar xzf "${tmp}/${arch}.tar.gz" -C "${tmp}"
  mkdir -p "$(dirname "$uv_bin")"
  install -m 0755 "$(find "${tmp}" -type f -name uv | head -n1)" "$uv_bin"
  rm -rf "${tmp}"
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
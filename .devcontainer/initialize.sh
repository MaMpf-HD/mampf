set -eu

git submodule update --init --recursive
docker buildx rm --force mampf-container-builder >/dev/null 2>&1 || true
docker rm -f buildx_buildkit_mampf-container-builder0 >/dev/null 2>&1 || true
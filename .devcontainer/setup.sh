#!/usr/bin/env bash
# One-time setup for a villa Codespace (Ubuntu 24.04).
# Mirrors .github/workflows/test-vesuvius.yml. Full log: /tmp/villa-setup.log
set -euo pipefail
exec > >(tee -a /tmp/villa-setup.log) 2>&1
echo "[setup] $(date) starting"

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential curl git ca-certificates \
  libblosc-dev libblosc2-dev libboost-dev libceres-dev libconcurrentqueue-dev \
  libcurl4-openssl-dev libeigen3-dev liblz4-dev libopencv-contrib-dev libopencv-dev \
  libsuitesparse-dev libjpeg-dev libpng-dev libtiff-dev libzstd-dev ninja-build \
  nlohmann-json3-dev pkg-config qt6-base-dev zlib1g-dev libsqlite3-dev libssl-dev

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"

git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/ScrollPrize/villa.git

cd vesuvius
# Build the C++ packages one at a time with 3 compile jobs: building them all in
# parallel on a 4-core / 16 GB codespace got its compilers terminated.
export UV_CONCURRENT_BUILDS=1 CMAKE_BUILD_PARALLEL_LEVEL=3
uv sync --frozen --extra all
# CI (test-vesuvius.yml) re-locks and then installs a pinned zarr, which brings in
# numcodecs. The committed uv.lock lacks pynrrd and numcodecs, so add them the same way.
uv pip install "zarr==3.2.1" pynrrd
echo "[setup] $(date) done."
echo "[setup] Run tests:  cd vesuvius && PYTHONPATH=/workspaces/villa uv run --no-sync pytest tests -m 'not slow and not network'"
echo "[setup] New fix:    git fetch upstream && git switch -c my-fix upstream/main"

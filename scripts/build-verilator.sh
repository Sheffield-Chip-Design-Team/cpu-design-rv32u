#!/usr/bin/env bash
# Build a pinned Verilator from source (cocotb 2.0 needs Verilator >= 5.036; many distros
# ship older). Installs into a prefix you own, no sudo needed for the build itself.
#
#   scripts/build-verilator.sh                    # v5.040 into ~/opt/verilator-v5.040
#   scripts/build-verilator.sh --prefix DIR       # somewhere else
#   scripts/build-verilator.sh --version v5.042   # another tag
#
# Build dependencies (Debian/Ubuntu):
#   sudo apt-get install -y git make autoconf g++ flex bison help2man perl python3 \
#        libfl2 libfl-dev zlib1g zlib1g-dev ccache
# Then add the printed PATH line to your shell profile.
set -euo pipefail

VERSION="v5.040"
PREFIX=""
JOBS="$(nproc 2>/dev/null || echo 4)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --prefix)  PREFIX="$2"; shift 2 ;;
    --jobs)    JOBS="$2"; shift 2 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
PREFIX="${PREFIX:-$HOME/opt/verilator-$VERSION}"

for tool in git make autoconf g++ flex bison perl python3; do
  command -v "$tool" >/dev/null || { echo "missing build tool: $tool (see the apt line in this script)" >&2; exit 1; }
done

if [[ -x "$PREFIX/bin/verilator" ]]; then
  echo "already installed: $("$PREFIX/bin/verilator" --version)"
else
  SRC="$(mktemp -d)/verilator"
  trap 'rm -rf "$(dirname "$SRC")"' EXIT
  echo "building Verilator $VERSION into $PREFIX (about 10-20 minutes)"
  git clone --quiet --depth 1 --branch "$VERSION" https://github.com/verilator/verilator "$SRC"
  cd "$SRC"
  unset VERILATOR_ROOT
  autoconf
  ./configure --prefix="$PREFIX"
  make -j"$JOBS"
  make install
fi

echo
echo "Verilator: $("$PREFIX/bin/verilator" --version)"
echo "Add it to your PATH:"
echo "  export PATH=\"$PREFIX/bin:\$PATH\""

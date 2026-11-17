#!/usr/bin/env bash
# Install a prebuilt RISC-V GCC that can target rv32i/ilp32 (no compiler build needed).
#
#   scripts/install-riscv-prebuilt.sh             # distro package if possible, else xPack
#   scripts/install-riscv-prebuilt.sh --xpack     # always the xPack release, into ~/opt
#
# sw/Makefile accepts any of the prefixes riscv32-unknown-elf-, riscv64-unknown-elf- or
# riscv-none-elf- on your PATH: the 64-bit toolchains build rv32i code with
# -march=rv32i -mabi=ilp32, and RV32u programs use no C library (-nostdlib).
set -euo pipefail

XPACK_VERSION="14.2.0-3"
PREFIX_DIR="${PREFIX_DIR:-$HOME/opt}"
FORCE_XPACK=0
[[ "${1:-}" == "--xpack" ]] && FORCE_XPACK=1
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { sed -n '2,10p' "$0"; exit 0; }

have() { command -v "$1" >/dev/null 2>&1; }

if [[ $FORCE_XPACK == 0 ]]; then
  for p in riscv32-unknown-elf- riscv64-unknown-elf- riscv-none-elf-; do
    if have "${p}gcc"; then
      echo "found ${p}gcc: $("${p}gcc" --version | head -1)"
      echo "nothing to do (sw/Makefile picks it up)."
      exit 0
    fi
  done
  if have apt-get; then
    echo "installing the Debian/Ubuntu package gcc-riscv64-unknown-elf (needs sudo)"
    sudo apt-get update
    sudo apt-get install -y gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf
    riscv64-unknown-elf-gcc --version | head -1
    exit 0
  fi
  if have brew; then
    echo "installing riscv-gnu-toolchain from Homebrew (riscv-software-src tap)"
    brew tap riscv-software-src/riscv
    brew install riscv-tools
    exit 0
  fi
fi

# xPack: a self-contained, relocatable build of riscv-none-elf-gcc
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)  PLATFORM=linux-x64 ;;
  Linux-aarch64) PLATFORM=linux-arm64 ;;
  Darwin-arm64)  PLATFORM=darwin-arm64 ;;
  Darwin-x86_64) PLATFORM=darwin-x64 ;;
  *) echo "no xPack build for $(uname -s)-$(uname -m); install a RISC-V GCC by hand" >&2; exit 1 ;;
esac
NAME="xpack-riscv-none-elf-gcc-$XPACK_VERSION"
URL="https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v$XPACK_VERSION/$NAME-$PLATFORM.tar.gz"
if [[ ! -x "$PREFIX_DIR/$NAME/bin/riscv-none-elf-gcc" ]]; then
  mkdir -p "$PREFIX_DIR"
  echo "downloading $URL"
  curl -fL --retry 3 "$URL" | tar -xz -C "$PREFIX_DIR"
fi
"$PREFIX_DIR/$NAME/bin/riscv-none-elf-gcc" --version | head -1
echo
echo "Add it to your PATH:"
echo "  export PATH=\"$PREFIX_DIR/$NAME/bin:\$PATH\""

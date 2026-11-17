#!/usr/bin/env bash
# Fetch the IHP SRAM models (ip/IHP-Open-PDK) without downloading the whole PDK.
#
# The submodule is pinned in the superproject but marked `update = none`, so a plain
# `git submodule update --init` (and the Tiny Tapeout GDS action's recursive checkout)
# skips it: the full IHP-Open-PDK is several GB, and hardening uses the PDK the action
# installs anyway. Simulation only needs the behavioural models, so this script makes a
# partial (blob-less) clone, checks out just libs.ref/sg13g2_sram/{verilog,doc} at the
# pinned commit: a few MB.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/ip/IHP-Open-PDK"
URL="https://github.com/IHP-GmbH/IHP-Open-PDK"
PATHS=(/ihp-sg13g2/libs.ref/sg13g2_sram/verilog/ /ihp-sg13g2/libs.ref/sg13g2_sram/doc/ /LICENSE /README.md)

# The commit the superproject pins (committed tree, else the index)
SHA="$( (git -C "$ROOT" ls-tree HEAD ip/IHP-Open-PDK 2>/dev/null || true) | awk '{print $3}')"
if [[ -z "$SHA" ]]; then
  SHA="$(git -C "$ROOT" ls-files -s ip/IHP-Open-PDK | awk '{print $2}')"
fi
if [[ -z "$SHA" ]]; then
  echo "init-submodules: ip/IHP-Open-PDK is not a submodule of this repository" >&2
  exit 1
fi

if [[ ! -e "$DIR/.git" ]]; then
  rmdir "$DIR" 2>/dev/null || true
  echo "init-submodules: partial clone of $URL"
  git clone --quiet --filter=blob:none --no-checkout --depth 1 "$URL" "$DIR"
fi

git -C "$DIR" sparse-checkout set --no-cone "${PATHS[@]}"
if ! git -C "$DIR" cat-file -e "$SHA^{commit}" 2>/dev/null; then
  git -C "$DIR" fetch --quiet --filter=blob:none --depth 1 origin "$SHA"
fi
git -C "$DIR" -c advice.detachedHead=false checkout --quiet "$SHA"

MODELS="$DIR/ihp-sg13g2/libs.ref/sg13g2_sram/verilog"
for m in RM_IHPSG13_1P_512x32_c2_bm_bist RM_IHPSG13_1P_512x16_c2_bm_bist RM_IHPSG13_1P_core_behavioral_bm_bist; do
  [[ -f "$MODELS/$m.v" ]] || { echo "init-submodules: $m.v missing in $MODELS" >&2; exit 1; }
done
echo "init-submodules: IHP SRAM models at ${SHA:0:12} ($(du -sh "$DIR" | cut -f1))"

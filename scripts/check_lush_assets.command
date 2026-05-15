#!/bin/zsh
set -e

cd "$(dirname "$0")/.."

echo "Ballistics Wallet lush_assets checker"
echo

if [[ -z "${LUSH_ASSETS_DIR:-}" ]]; then
  read "drive_dir?Path to your local/synced Google Drive lush_assets folder: "
else
  drive_dir="$LUSH_ASSETS_DIR"
fi

echo
python3 scripts/check_lush_assets.py --drive-dir "$drive_dir" --copy-missing

echo
echo "Done. Press Return to close this window."
read

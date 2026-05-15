#!/usr/bin/env python3
"""Compare product image assets with the Google Drive lush_assets folder.

The script is intentionally standalone so Drive housekeeping does not become
runtime app code. It can compare against either:

  - a local/synced Drive folder: --drive-dir "/path/to/lush_assets"
  - an rclone remote path:      --rclone-remote "gdrive:lush_assets"

Use --copy-missing to copy files that exist in Drive but are missing from
assets/images.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PRODUCTS_CSV = REPO_ROOT / "merged_data_final.csv"
DEFAULT_ASSETS_DIR = REPO_ROOT / "assets" / "images"
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}


@dataclass(frozen=True)
class ProductImage:
    product_name: str
    image_name: str
    filename: str


def product_name_to_image_name(product_name: str) -> str:
    """Mirror lib/utilities.dart productNameToImageName."""
    lower = product_name.lower().strip()
    without_slashes = re.sub(r"[\\/]+", " ", lower)
    underscored = re.sub(r"\s+", "_", without_slashes)
    cleaned = re.sub(r"[^a-z0-9_'()-]+", "_", underscored)
    return re.sub(r"_+", "_", cleaned).strip("_")


def read_expected_images(products_csv: Path) -> list[ProductImage]:
    images_by_name: dict[str, ProductImage] = {}

    with products_csv.open(newline="", encoding="utf-8-sig") as handle:
        for row in csv.reader(handle):
            if len(row) < 1:
                continue

            product_name = row[0].strip()
            if not product_name:
                continue

            csv_image_name = row[2].strip() if len(row) > 2 else ""
            image_name = csv_image_name or product_name_to_image_name(product_name)
            if not image_name or image_name == "question":
                continue

            filename = f"{image_name}.png"
            images_by_name.setdefault(
                image_name,
                ProductImage(
                    product_name=product_name,
                    image_name=image_name,
                    filename=filename,
                ),
            )

    return sorted(images_by_name.values(), key=lambda image: image.filename)


def list_local_images(directory: Path) -> set[str]:
    if not directory.exists():
        return set()

    return {
        path.name
        for path in directory.iterdir()
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
    }


def list_rclone_images(remote: str) -> set[str]:
    result = subprocess.run(
        ["rclone", "lsf", "--files-only", remote],
        check=True,
        capture_output=True,
        text=True,
    )
    return {
        line.strip()
        for line in result.stdout.splitlines()
        if Path(line.strip()).suffix.lower() in IMAGE_EXTENSIONS
    }


def copy_from_rclone(remote: str, filename: str, assets_dir: Path) -> None:
    assets_dir.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "rclone",
            "copyto",
            f"{remote.rstrip('/')}/{filename}",
            str(assets_dir / filename),
        ],
        check=True,
    )


def copy_from_local_drive(drive_dir: Path, filename: str, assets_dir: Path) -> None:
    assets_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(drive_dir / filename, assets_dir / filename)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check whether Drive lush_assets images are bundled locally.",
    )
    source = parser.add_mutually_exclusive_group(required=False)
    source.add_argument(
        "--drive-dir",
        type=Path,
        default=os.environ.get("LUSH_ASSETS_DIR"),
        help="Path to a locally synced/downloaded lush_assets folder.",
    )
    source.add_argument(
        "--rclone-remote",
        help='rclone remote path, for example "gdrive:lush_assets".',
    )
    parser.add_argument(
        "--products-csv",
        type=Path,
        default=DEFAULT_PRODUCTS_CSV,
        help="Product CSV used to determine expected image names.",
    )
    parser.add_argument(
        "--assets-dir",
        type=Path,
        default=DEFAULT_ASSETS_DIR,
        help="Local Flutter image asset directory.",
    )
    parser.add_argument(
        "--copy-missing",
        action="store_true",
        help="Copy images that exist in Drive but are missing locally.",
    )
    parser.add_argument(
        "--fail-on-missing-local",
        action="store_true",
        help="Exit 1 if expected images exist in Drive but are missing locally.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    drive_dir = Path(args.drive_dir).expanduser() if args.drive_dir else None
    if not drive_dir and not args.rclone_remote:
        print(
            "Provide --drive-dir, --rclone-remote, or set LUSH_ASSETS_DIR.",
            file=sys.stderr,
        )
        return 2
    if drive_dir and not drive_dir.is_dir():
        print(f"Drive folder does not exist: {drive_dir}", file=sys.stderr)
        return 2

    expected_images = read_expected_images(args.products_csv)
    expected_filenames = {image.filename for image in expected_images}
    local_files = list_local_images(args.assets_dir)

    if args.rclone_remote:
        drive_files = list_rclone_images(args.rclone_remote)
    else:
        assert drive_dir is not None
        drive_files = list_local_images(drive_dir)

    missing_local_available_in_drive = sorted(
        expected_filenames & drive_files - local_files,
    )
    missing_everywhere = sorted(expected_filenames - local_files - drive_files)
    drive_not_referenced = sorted(drive_files - expected_filenames)

    print(f"Expected product images: {len(expected_filenames)}")
    print(f"Local asset images:      {len(local_files)}")
    print(f"Drive lush_assets files: {len(drive_files)}")
    print()

    if missing_local_available_in_drive:
        print("Missing locally, available in Drive:")
        for filename in missing_local_available_in_drive:
            print(f"  {filename}")
    else:
        print("Missing locally, available in Drive: none")

    print()
    if missing_everywhere:
        print("Expected by product library, missing from both local assets and Drive:")
        for filename in missing_everywhere:
            product = next(
                image.product_name
                for image in expected_images
                if image.filename == filename
            )
            print(f"  {filename}  ({product})")
    else:
        print(
            "Expected by product library, missing from both local assets "
            "and Drive: none",
        )

    print()
    if drive_not_referenced:
        print("Drive files not referenced by product library:")
        for filename in drive_not_referenced:
            print(f"  {filename}")
    else:
        print("Drive files not referenced by product library: none")

    if args.copy_missing and missing_local_available_in_drive:
        print()
        print("Copying missing Drive images into local assets...")
        for filename in missing_local_available_in_drive:
            if args.rclone_remote:
                copy_from_rclone(args.rclone_remote, filename, args.assets_dir)
            else:
                assert drive_dir is not None
                copy_from_local_drive(drive_dir, filename, args.assets_dir)
            print(f"  copied {filename}")

    if (
        args.fail_on_missing_local
        and missing_local_available_in_drive
        and not args.copy_missing
    ):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

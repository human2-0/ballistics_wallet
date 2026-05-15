#!/usr/bin/env python3
"""Download Lush product thumbnails for products listed in merged_data_final.csv.

The app renders product images from assets/images/<imageName>.png. This script
crawls public Lush category pages through r.jina.ai, matches product cards to
CSV product names, downloads matched thumbnails, and writes imageName values
back to the CSV.
"""

from __future__ import annotations

import argparse
import csv
import difflib
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "merged_data_final.csv"
ASSETS_DIR = ROOT / "assets" / "images"
BASE_URL = "https://www.lush.com/uk/en"
JINA_PREFIX = "https://r.jina.ai/http://r.jina.ai/http://"

START_CATEGORIES = (
    "bath-products",
    "bath-bombs",
    "bubble-bars",
    "new-products",
    "bestsellers",
    "trending-now",
    "fathers-day",
    "collaborations",
    "vegan-bath-products",
    "bath-bombs-and-bubble-bars-for-kids",
    "calming-and-relaxing-bath-bombs",
    "sweet-and-comforting-bath-bombs",
    "citrus-and-uplifting-bath-bombs",
    "fresh-and-playful-bath-bombs",
    "bath-oils",
    "fun",
)


CARD_RE = re.compile(
    r"!\[Image \d+: (?P<alt>[^\]]+)\]"
    r"\((?P<image>https://[^)]+unicorn\.lush\.com/[^)]+)\)"
    r"(?P<body>.*?)"
    r"\]\((?P<href>https://www\.lush\.com/uk/en/p/[^)]+)\)",
)
CATEGORY_RE = re.compile(r"https://www\.lush\.com/uk/en/c/([a-z0-9-]+)")


@dataclass(frozen=True)
class ProductCard:
    title: str
    image_url: str
    href: str

    @property
    def score_text(self) -> str:
        slug = self.href.rsplit("/", 1)[-1].replace("-", " ")
        return normalize_name(f"{self.title} {slug}")


def fetch_text(url: str, timeout: int = 15) -> str:
    req = urllib.request.Request(
        JINA_PREFIX + url,
        headers={"User-Agent": "ballistics-wallet-image-import/1.0"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return response.read().decode("utf-8", errors="replace")


def clean_card_title(alt: str, body: str) -> str:
    heading = re.search(r"###\s+(.+?)\s+(?:Bath Bomb|Bubble Bar|Gift|Soap|Lush Melt|Fun|Bath Oil)\b", body)
    if heading:
        return heading.group(1).strip()
    return alt.strip()


def crawl_cards(max_categories: int, delay: float) -> dict[str, ProductCard]:
    seen_categories = set[str]()
    queued = list(START_CATEGORIES)
    cards: dict[str, ProductCard] = {}

    while queued and len(seen_categories) < max_categories:
        category = queued.pop(0)
        if category in seen_categories:
            continue
        seen_categories.add(category)

        url = f"{BASE_URL}/c/{category}"
        print(f"crawl category {category}", flush=True)
        try:
            markdown = fetch_text(url)
        except (urllib.error.URLError, TimeoutError) as exc:
            print(f"skip category {category}: {exc}", flush=True)
            continue

        for match in CARD_RE.finditer(markdown):
            image_url = unwrap_lush_image_url(match.group("image"))
            if "/media/thumbnails/products/" not in image_url:
                continue
            title = clean_card_title(match.group("alt"), match.group("body"))
            key = normalize_name(title)
            cards.setdefault(key, ProductCard(title=title, image_url=image_url, href=match.group("href")))

        for linked_category in CATEGORY_RE.findall(markdown):
            if linked_category not in seen_categories and linked_category not in queued:
                queued.append(linked_category)

        time.sleep(delay)

    return cards


def unwrap_lush_image_url(url: str) -> str:
    if "https://unicorn.lush.com/" in url:
        return "https://unicorn.lush.com/" + url.split("https://unicorn.lush.com/", 1)[1]
    return url


def normalize_name(value: str) -> str:
    text = value.lower()
    text = text.replace("&", " and ")
    text = re.sub(r"'?\d{2,4}\b", " ", text)
    text = re.sub(r"\([^)]*\)", " ", text)
    text = re.sub(r"\b(new|old|v\d+|gco|spa|inc|insert|inserts|with|whole|product|flat|base)\b", " ", text)
    text = re.sub(r"\b(bath|bomb|bubble|bar|lush|melt|cube|epsom|salt)\b", " ", text)
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def asset_name(product_name: str) -> str:
    text = product_name.lower().strip()
    text = re.sub(r"[\\/]+", " ", text)
    text = re.sub(r"\s+", "_", text)
    text = re.sub(r"[^a-z0-9_'()-]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    return text or "product"


def is_existing_asset(image_name: str) -> bool:
    return bool(image_name) and (ASSETS_DIR / f"{image_name}.png").is_file()


def best_match(product_name: str, cards: dict[str, ProductCard], min_score: float) -> tuple[ProductCard | None, float]:
    wanted = normalize_name(product_name)
    if not wanted:
        return None, 0.0

    best_card: ProductCard | None = None
    best_score = 0.0
    wanted_tokens = set(wanted.split())

    for card in cards.values():
        score_text = card.score_text
        if not score_text:
            continue
        card_tokens = set(score_text.split())
        overlap = len(wanted_tokens & card_tokens) / max(len(wanted_tokens), 1)
        ratio = difflib.SequenceMatcher(None, wanted, score_text).ratio()
        score = (ratio * 0.72) + (overlap * 0.28)
        if wanted == score_text:
            score = max(score, 0.98)
        elif (
            (wanted_tokens <= card_tokens or card_tokens <= wanted_tokens)
            and len(wanted_tokens) > 1
            and len(card_tokens) > 1
        ):
            score = max(score, 0.94)
        if score > best_score:
            best_card = card
            best_score = score

    if best_score < min_score:
        return None, best_score
    return best_card, best_score


def download_png(url: str, destination: Path, timeout: int = 40) -> bool:
    req = urllib.request.Request(url, headers={"User-Agent": "ballistics-wallet-image-import/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        content_type = response.headers.get("content-type", "")
        data = response.read()

    if "image/" not in content_type or not data.startswith(b"\x89PNG"):
        return False

    destination.write_bytes(data)
    return True


def load_csv(path: Path) -> list[list[str]]:
    with path.open(newline="") as f:
        return list(csv.reader(f))


def write_csv(path: Path, rows: list[list[str]]) -> None:
    with path.open("w", newline="") as f:
        csv.writer(f, lineterminator="\n").writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="show matches without downloading or editing the CSV")
    parser.add_argument("--min-score", type=float, default=0.88)
    parser.add_argument("--max-categories", type=int, default=40)
    parser.add_argument("--delay", type=float, default=0.25)
    args = parser.parse_args()

    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    rows = load_csv(CSV_PATH)
    cards = crawl_cards(max_categories=args.max_categories, delay=args.delay)
    print(f"found {len(cards)} product cards", flush=True)

    product_to_rows: dict[str, list[int]] = {}
    product_to_image: dict[str, str] = {}
    for index, row in enumerate(rows):
        if len(row) < 3 or not row[0].strip():
            continue
        product = row[0].strip()
        product_to_rows.setdefault(product, []).append(index)
        product_to_image.setdefault(product, row[2].strip())

    downloaded = 0
    matched = 0
    skipped = 0
    for product, current_image in sorted(product_to_image.items()):
        if is_existing_asset(current_image):
            continue
        card, score = best_match(product, cards, args.min_score)
        if card is None:
            skipped += 1
            continue

        matched += 1
        name = asset_name(product)
        destination = ASSETS_DIR / f"{name}.png"
        print(f"{product} -> {card.title} ({score:.2f})", flush=True)

        if args.dry_run:
            continue

        if not destination.exists() and download_png(card.image_url, destination):
            downloaded += 1

        for row_index in product_to_rows[product]:
            rows[row_index][2] = name

    if not args.dry_run:
        write_csv(CSV_PATH, rows)

    print(f"matched {matched}, downloaded {downloaded}, skipped {skipped}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

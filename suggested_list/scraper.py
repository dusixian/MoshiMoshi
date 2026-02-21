"""
Omakase restaurant scraper — Tabelog (Japan)
Targets: Tokyo and Kyoto omakase / kaiseki categories

Usage:
    pip install requests beautifulsoup4 lxml
    python scraper.py
    python scraper.py --city tokyo --pages 3
    python scraper.py --city kyoto --pages 2 --output kyoto_results.json

Output: JSON file with restaurant details merged into restaurants.json
"""

import argparse
import json
import re
import time
import random
from pathlib import Path

import requests
from bs4 import BeautifulSoup

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

BASE_DIR = Path(__file__).parent
OUTPUT_FILE = BASE_DIR / "restaurants.json"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/122.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "ja,en-US;q=0.9,en;q=0.8",
    "Accept": "text/html,application/xhtml+xml,application/xhtml+xml;q=0.9,*/*;q=0.8",
    "Referer": "https://tabelog.com/",
}

# Tabelog search URLs for omakase/kaiseki by city
# rst=omakase(カウンター, 料亭), RdoCosTp=2 (dinner),
# Srt=D_point (sort by rating)
SEARCH_URLS = {
    "tokyo": [
        # Sushi omakase in Tokyo
        "https://tabelog.com/tokyo/rstLst/SA2301/sushi/Srt=D_point/",
        # Kaiseki / Japanese cuisine omakase
        "https://tabelog.com/tokyo/rstLst/SA2301/japanese/Srt=D_point/",
    ],
    "kyoto": [
        # Sushi omakase in Kyoto
        "https://tabelog.com/kyoto/rstLst/sushi/Srt=D_point/",
        # Kaiseki / Japanese cuisine
        "https://tabelog.com/kyoto/rstLst/japanese/Srt=D_point/",
    ],
}

CITY_CODE_MAP = {
    "tokyo": "tokyo",
    "kyoto": "kyoto",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def fetch(url: str, retries: int = 3) -> BeautifulSoup | None:
    """Fetch a URL and return a BeautifulSoup object, or None on failure."""
    for attempt in range(retries):
        try:
            resp = requests.get(url, headers=HEADERS, timeout=15)
            if resp.status_code == 200:
                return BeautifulSoup(resp.text, "lxml")
            elif resp.status_code == 429:
                wait = 30 + attempt * 20
                print(f"  Rate-limited. Waiting {wait}s …")
                time.sleep(wait)
            else:
                print(f"  HTTP {resp.status_code} for {url}")
                return None
        except requests.RequestException as e:
            print(f"  Request error: {e}")
            time.sleep(5)
    return None


def sleep_between_requests():
    """Polite delay to avoid hammering the server."""
    time.sleep(random.uniform(2.5, 5.0))


def parse_score(text: str) -> float | None:
    """Extract numeric rating from Tabelog score text like '4.56'."""
    m = re.search(r"(\d+\.\d+)", text or "")
    return float(m.group(1)) if m else None


def parse_price(text: str) -> int | None:
    """
    Parse price strings like '¥20,000〜¥29,999' → midpoint integer.
    Also handles '¥15,000' or 'JPY 30,000~'.
    """
    if not text:
        return None
    text = text.replace(",", "").replace("￥", "").replace("¥", "").strip()
    # Range like 20000〜29999
    m = re.search(r"(\d+)[〜~\-]+(\d+)", text)
    if m:
        return (int(m.group(1)) + int(m.group(2))) // 2
    # Single value
    m = re.search(r"(\d{4,})", text)
    return int(m.group(1)) if m else None


# ---------------------------------------------------------------------------
# Tabelog scraper
# ---------------------------------------------------------------------------

def scrape_tabelog_listing_page(soup: BeautifulSoup, city: str) -> list[dict]:
    """Parse a Tabelog search-results page and return a list of restaurant dicts."""
    results = []

    restaurant_cards = soup.select("li.list-rst__item")
    if not restaurant_cards:
        # Try alternative selector used on some page versions
        restaurant_cards = soup.select(".list-rst")

    for card in restaurant_cards:
        try:
            # Name
            name_tag = card.select_one(".list-rst__rst-name-main")
            if not name_tag:
                name_tag = card.select_one(".list-rst__name a")
            name = name_tag.get_text(strip=True) if name_tag else None

            # Detail page URL
            link_tag = card.select_one("a.list-rst__rst-name-main, .list-rst__name a")
            detail_url = link_tag["href"] if link_tag and link_tag.get("href") else None

            # Area / address
            area_tag = card.select_one(".list-rst__area-genre .c-link-arrow")
            area = area_tag.get_text(strip=True) if area_tag else None

            # Tabelog score
            score_tag = card.select_one(".c-rating__val.c-rating__val--score")
            score = parse_score(score_tag.get_text() if score_tag else None)

            # Dinner price
            price_dinner_tag = card.select_one(
                ".list-rst__budget-item:nth-of-type(1) .list-rst__budget-num"
            )
            # Fallback: first budget element
            if not price_dinner_tag:
                price_dinner_tag = card.select_one(".list-rst__budget-num")
            price_dinner = parse_price(
                price_dinner_tag.get_text() if price_dinner_tag else None
            )

            # Genre / cuisine type
            genre_tag = card.select_one(".list-rst__area-genre .list-rst__area-genre-item")
            cuisine = genre_tag.get_text(strip=True) if genre_tag else None

            # Review count
            review_tag = card.select_one(".list-rst__review-item .c-rating-v2__review-num")
            if not review_tag:
                review_tag = card.select_one(".list-rst__comments-num")
            review_count = None
            if review_tag:
                m = re.search(r"(\d+)", review_tag.get_text())
                if m:
                    review_count = int(m.group(1))

            if not name:
                continue

            results.append(
                {
                    "name": name,
                    "city": city.capitalize(),
                    "area": area,
                    "cuisine": cuisine,
                    "tabelog_score": score,
                    "price_per_person_jpy": price_dinner,
                    "price_per_person_usd_approx": (
                        round(price_dinner / 149) if price_dinner else None
                    ),
                    "tabelog_url": detail_url,
                    "tabelog_review_count": review_count,
                }
            )

        except Exception as e:
            print(f"  Error parsing card: {e}")
            continue

    return results


def scrape_detail_page(url: str) -> dict:
    """Scrape a restaurant detail page for phone and address."""
    info = {}
    soup = fetch(url)
    if not soup:
        return info

    # Phone
    phone_tag = soup.select_one(".rstinfo-table__tel-num")
    if phone_tag:
        info["phone"] = phone_tag.get_text(strip=True)

    # Address
    addr_tag = soup.select_one(".rstinfo-table__address")
    if addr_tag:
        # Remove the map link part
        for a in addr_tag.find_all("a"):
            a.decompose()
        info["address_ja"] = addr_tag.get_text(strip=True)

    # Seats
    seats_tag = soup.find("th", string=re.compile("座席"))
    if seats_tag:
        seats_val = seats_tag.find_next_sibling("td")
        if seats_val:
            info["seats"] = seats_val.get_text(strip=True)[:80]

    # Opening hours
    hours_tag = soup.select_one(".rstinfo-table__opening-time")
    if hours_tag:
        info["hours"] = hours_tag.get_text(strip=True)[:120]

    return info


def scrape_city(city: str, pages: int = 2, fetch_details: bool = False) -> list[dict]:
    """Scrape Tabelog listings for a city across multiple pages."""
    all_restaurants: list[dict] = []
    urls = SEARCH_URLS.get(city.lower(), [])

    for base_url in urls:
        print(f"\n  Category URL: {base_url}")
        for page in range(1, pages + 1):
            url = base_url if page == 1 else f"{base_url.rstrip('/')}/?Pgnum={page}"
            print(f"    Page {page}: {url}")
            soup = fetch(url)
            if not soup:
                print("    Failed to fetch page, skipping.")
                break

            restaurants = scrape_tabelog_listing_page(soup, city)
            print(f"    Found {len(restaurants)} restaurants on this page.")
            all_restaurants.extend(restaurants)

            # Check if next page exists
            next_btn = soup.select_one("a.c-pagination__arrow--next")
            if not next_btn:
                print("    No next page, stopping pagination.")
                break

            sleep_between_requests()

    # De-duplicate by name
    seen = set()
    unique = []
    for r in all_restaurants:
        key = r["name"].strip().lower()
        if key not in seen:
            seen.add(key)
            unique.append(r)

    print(f"\n  Total unique restaurants found for {city}: {len(unique)}")

    # Optionally enrich with detail-page data
    if fetch_details:
        print("  Fetching detail pages for phone/address …")
        for r in unique[:20]:  # limit to first 20 to be polite
            if r.get("tabelog_url"):
                print(f"    Detail: {r['name']}")
                extra = scrape_detail_page(r["tabelog_url"])
                r.update(extra)
                sleep_between_requests()

    return unique


# ---------------------------------------------------------------------------
# Merge with existing restaurants.json
# ---------------------------------------------------------------------------

def load_existing(path: Path) -> dict:
    if path.exists():
        with open(path) as f:
            return json.load(f)
    return {"metadata": {}, "restaurants": []}


def merge_scraped(existing: dict, scraped: list[dict], city: str) -> dict:
    """
    Add scraped restaurants that aren't already in the list (by name match).
    """
    existing_names = {
        r["name"].lower().strip() for r in existing.get("restaurants", [])
    }
    existing_names_ja = {
        r.get("name_ja", "").lower().strip()
        for r in existing.get("restaurants", [])
    }

    added = 0
    for idx, r in enumerate(scraped):
        name_lower = r["name"].lower().strip()
        if name_lower in existing_names or name_lower in existing_names_ja:
            continue  # already in the list
        r["id"] = f"{city[:3]}_{900 + idx:03d}"  # temporary id
        r["source"] = "tabelog_scrape"
        existing["restaurants"].append(r)
        added += 1

    print(f"  Added {added} new restaurants from scrape.")
    return existing


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Scrape omakase restaurant info from Tabelog"
    )
    parser.add_argument(
        "--city",
        choices=["tokyo", "kyoto", "both"],
        default="both",
        help="Which city to scrape (default: both)",
    )
    parser.add_argument(
        "--pages",
        type=int,
        default=2,
        help="Number of listing pages to scrape per category (default: 2)",
    )
    parser.add_argument(
        "--details",
        action="store_true",
        help="Also scrape individual restaurant detail pages (slower)",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=str(OUTPUT_FILE),
        help=f"Output JSON file (default: {OUTPUT_FILE})",
    )
    args = parser.parse_args()

    output_path = Path(args.output)
    cities = ["tokyo", "kyoto"] if args.city == "both" else [args.city]

    existing_data = load_existing(output_path)

    for city in cities:
        print(f"\n{'='*60}")
        print(f"Scraping {city.upper()} …")
        print(f"{'='*60}")
        scraped = scrape_city(city, pages=args.pages, fetch_details=args.details)

        if scraped:
            existing_data = merge_scraped(existing_data, scraped, city)
        else:
            print(f"  No results scraped for {city}.")

    # Save
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(existing_data, f, ensure_ascii=False, indent=2)

    print(f"\nSaved {len(existing_data['restaurants'])} restaurants to {output_path}")


if __name__ == "__main__":
    main()

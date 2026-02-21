# suggested_list

Curated omakase & high-end Japanese restaurant data for Tokyo and Kyoto.

## Files

| File | Description |
|------|-------------|
| `restaurants.json` | Pre-compiled list of ~24 top restaurants |
| `scraper.py` | Tabelog scraper to fetch live data and merge it in |

## restaurants.json schema

```json
{
  "name":                  "English name",
  "name_ja":               "日本語名",
  "city":                  "Tokyo | Kyoto",
  "area":                  "Neighborhood",
  "address":               "English address",
  "address_ja":            "日本語住所",
  "phone":                 "+81-...",
  "google_rating":         4.6,
  "google_review_count":   1100,
  "price_per_person_jpy":  35000,
  "price_per_person_usd_approx": 235,
  "cuisine":               "Sushi Omakase | Kaiseki | ...",
  "michelin_stars":        2,
  "tabelog_score":         4.38,
  "reservation_difficulty": "Easy | Moderate | Hard | Very Hard | Extremely Hard",
  "notes":                 "Free-text notes"
}
```

## Running the scraper

```bash
# Install deps
pip install requests beautifulsoup4 lxml

# Scrape both cities (2 pages each) and merge into restaurants.json
python scraper.py

# Scrape only Kyoto, 3 pages, also hit detail pages for phone/address
python scraper.py --city kyoto --pages 3 --details

# Custom output file
python scraper.py --city tokyo --output tokyo_live.json
```

> **Note:** Tabelog occasionally returns 429 (rate-limit). The scraper backs off automatically. Run during off-peak hours for best results.

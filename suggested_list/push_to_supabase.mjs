// Usage: node push_to_supabase.mjs
// Reads SUPABASE_URL and SUPABASE_KEY from environment or .env.local

import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dir = dirname(fileURLToPath(import.meta.url));

// Load .env.local from web/ folder
let SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
let SUPABASE_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  try {
    const envFile = readFileSync(join(__dir, "../web/.env.local"), "utf8");
    for (const line of envFile.split("\n")) {
      const [k, ...v] = line.split("=");
      if (k === "NEXT_PUBLIC_SUPABASE_URL") SUPABASE_URL = v.join("=").trim();
      if (k === "NEXT_PUBLIC_SUPABASE_ANON_KEY") SUPABASE_KEY = v.join("=").trim();
    }
  } catch {
    console.error("❌ Could not find web/.env.local");
    console.error("   Create it with:\n   NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co\n   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key");
    process.exit(1);
  }
}

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error("❌ Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_SUPABASE_ANON_KEY");
  process.exit(1);
}

const data = JSON.parse(readFileSync(join(__dir, "restaurants.json"), "utf8"));
const restaurants = data.restaurants.map((r) => ({
  name: r.name,
  name_ja: r.name_ja,
  city: r.city,
  area: r.area,
  address: r.address,
  address_ja: r.address_ja,
  phone: r.phone,
  google_rating: r.google_rating,
  google_review_count: r.google_review_count,
  price_per_person_jpy: r.price_per_person_jpy,
  price_per_person_usd_approx: r.price_per_person_usd_approx,
  cuisine: r.cuisine,
  michelin_stars: r.michelin_stars,
  tabelog_score: r.tabelog_score,
  reservation_difficulty: r.reservation_difficulty,
  notes: r.notes,
}));

console.log(`📤 Pushing ${restaurants.length} restaurants to Supabase...`);

const res = await fetch(`${SUPABASE_URL}/rest/v1/resturant`, {
  method: "POST",
  headers: {
    apikey: SUPABASE_KEY,
    Authorization: `Bearer ${SUPABASE_KEY}`,
    "Content-Type": "application/json",
    Prefer: "resolution=merge-duplicates,return=minimal",
  },
  body: JSON.stringify(restaurants),
});

if (res.ok) {
  console.log(`✅ Done! ${restaurants.length} restaurants imported.`);
} else {
  const err = await res.text();
  console.error("❌ Error:", res.status, err);
}

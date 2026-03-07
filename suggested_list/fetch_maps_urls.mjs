import { readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const envPath = resolve(__dirname, "../web/.env.local");

// Parse .env.local
const env = {};
readFileSync(envPath, "utf8")
  .split("\n")
  .forEach((line) => {
    const [k, ...v] = line.split("=");
    if (k && v.length) env[k.trim()] = v.join("=").trim();
  });

const SUPABASE_URL = env["NEXT_PUBLIC_SUPABASE_URL"];
const SUPABASE_KEY = env["NEXT_PUBLIC_SUPABASE_ANON_KEY"];
const GOOGLE_API_KEY = env["GOOGLE_PLACES_API_KEY"];

async function fetchAllRestaurants() {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/resturant?select=id,name,city,address`, {
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
    },
  });
  return res.json();
}

async function searchPlaceId(name, city) {
  const query = encodeURIComponent(`${name} ${city ?? ""}`);
  const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${query}&type=restaurant&key=${GOOGLE_API_KEY}`;
  const res = await fetch(url);
  const data = await res.json();
  return data.results?.[0]?.place_id ?? null;
}

async function fetchMapsUrl(placeId) {
  const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=url&key=${GOOGLE_API_KEY}`;
  const res = await fetch(url);
  const data = await res.json();
  return data.result?.url ?? null;
}

async function updateMapsUrl(id, mapsUrl) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/resturant?id=eq.${id}`, {
    method: "PATCH",
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify({ maps_url: mapsUrl }),
  });
  return res.ok;
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  const restaurants = await fetchAllRestaurants();
  console.log(`Found ${restaurants.length} restaurants\n`);

  for (const r of restaurants) {
    process.stdout.write(`[${r.id}] ${r.name} ... `);
    try {
      const placeId = await searchPlaceId(r.name, r.city);
      if (!placeId) {
        console.log("❌ place not found");
        continue;
      }
      const mapsUrl = await fetchMapsUrl(placeId);
      if (!mapsUrl) {
        console.log("❌ no maps URL");
        continue;
      }
      const ok = await updateMapsUrl(r.id, mapsUrl);
      console.log(ok ? `✅ ${mapsUrl}` : "❌ update failed");
    } catch (e) {
      console.log(`❌ error: ${e.message}`);
    }
    await sleep(300); // avoid rate limit
  }

  console.log("\nDone!");
}

main();

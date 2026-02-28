// Fetches photos from Google Places API and uploads to Supabase Storage
// Usage: node suggested_list/fetch_images.mjs

import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dir = dirname(fileURLToPath(import.meta.url));

// Load .env.local
let SUPABASE_URL, SUPABASE_KEY, GOOGLE_KEY;
try {
  const envFile = readFileSync(join(__dir, "../web/.env.local"), "utf8");
  for (const line of envFile.split("\n")) {
    const [k, ...v] = line.split("=");
    const val = v.join("=").trim();
    if (k === "NEXT_PUBLIC_SUPABASE_URL") SUPABASE_URL = val;
    if (k === "NEXT_PUBLIC_SUPABASE_ANON_KEY") SUPABASE_KEY = val;
    if (k === "GOOGLE_PLACES_API_KEY") GOOGLE_KEY = val;
  }
} catch {
  console.error("❌ Could not read web/.env.local");
  process.exit(1);
}

if (!SUPABASE_URL || !SUPABASE_KEY || !GOOGLE_KEY) {
  console.error("❌ Missing env vars. Need: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, GOOGLE_PLACES_API_KEY");
  process.exit(1);
}

const BUCKET = "restaurant-images";

// Create storage bucket if it doesn't exist
async function ensureBucket() {
  const res = await fetch(`${SUPABASE_URL}/storage/v1/bucket`, {
    method: "POST",
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ id: BUCKET, name: BUCKET, public: true }),
  });
  if (res.ok) console.log(`✅ Created bucket: ${BUCKET}`);
  // 409 = already exists, that's fine
}

// Search Google Places by name → get photo_reference
async function getPhotoReference(name, city) {
  const query = `${name} ${city} restaurant`;
  const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query)}&key=${GOOGLE_KEY}`;
  const res = await fetch(url);
  const data = await res.json();
  const first = data.results?.[0];
  return first?.photos?.[0]?.photo_reference ?? null;
}

// Download photo from Google Places
async function downloadPhoto(photoRef) {
  const url = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${photoRef}&key=${GOOGLE_KEY}`;
  const res = await fetch(url);
  if (!res.ok) return null;
  const buffer = await res.arrayBuffer();
  return Buffer.from(buffer);
}

// Upload image to Supabase Storage
async function uploadToStorage(imageBuffer, filename) {
  const res = await fetch(`${SUPABASE_URL}/storage/v1/object/${BUCKET}/${filename}`, {
    method: "POST",
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      "Content-Type": "image/jpeg",
      "x-upsert": "true",
    },
    body: imageBuffer,
  });
  if (!res.ok) {
    console.error("  Upload error:", await res.text());
    return null;
  }
  return `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${filename}`;
}

// Update restaurant record with image_url
async function updateImageUrl(name, imageUrl) {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/resturant?name=eq.${encodeURIComponent(name)}`,
    {
      method: "PATCH",
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({ image_url: imageUrl }),
    }
  );
  return res.ok;
}

// Main
const data = JSON.parse(readFileSync(join(__dir, "restaurants.json"), "utf8"));
const restaurants = data.restaurants;

await ensureBucket();
console.log(`\n🍣 Fetching images for ${restaurants.length} restaurants...\n`);

for (const r of restaurants) {
  process.stdout.write(`  ${r.name} ... `);

  const photoRef = await getPhotoReference(r.name, r.city);
  if (!photoRef) {
    console.log("⚠️  No photo found");
    continue;
  }

  const imageBuffer = await downloadPhoto(photoRef);
  if (!imageBuffer) {
    console.log("⚠️  Failed to download");
    continue;
  }

  const filename = `${r.id}.jpg`;
  const imageUrl = await uploadToStorage(imageBuffer, filename);
  if (!imageUrl) continue;

  const ok = await updateImageUrl(r.name, imageUrl);
  console.log(ok ? "✅" : "❌ DB update failed");

  // Small delay to avoid rate limiting
  await new Promise((r) => setTimeout(r, 300));
}

console.log("\n🎉 Done!");

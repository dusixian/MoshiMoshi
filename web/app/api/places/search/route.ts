import { NextRequest, NextResponse } from "next/server"
import type { PlaceSearchResponse } from "@/lib/types/place"

const PLACES_API_BASE = "https://maps.googleapis.com/maps/api/place/textsearch/json"

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl
  const query = searchParams.get("q")?.trim()

  if (!query) {
    return NextResponse.json({ error: "Missing query parameter: q" }, { status: 400 })
  }

  const apiKey = process.env.GOOGLE_PLACES_API_KEY
  if (!apiKey) {
    return NextResponse.json(
      { error: "GOOGLE_PLACES_API_KEY is not configured" },
      { status: 500 }
    )
  }

  const params = new URLSearchParams({
    query,
    type: "restaurant",
    language: "ja",
    key: apiKey,
  })

  try {
    const res = await fetch(`${PLACES_API_BASE}?${params}`, { cache: "no-store" })

    if (!res.ok) {
      return NextResponse.json(
        { error: `Google API responded with ${res.status}` },
        { status: 502 }
      )
    }

    const data: PlaceSearchResponse = await res.json()

    if (data.status !== "OK" && data.status !== "ZERO_RESULTS") {
      return NextResponse.json(
        { error: data.error_message ?? `Google Places status: ${data.status}` },
        { status: 502 }
      )
    }

    // Return only the fields the frontend needs (avoid leaking raw API response)
    const results = (data.results ?? []).slice(0, 10).map((r) => ({
      place_id: r.place_id,
      name: r.name,
      formatted_address: r.formatted_address,
      rating: r.rating,
      user_ratings_total: r.user_ratings_total,
      price_level: r.price_level,
      types: r.types,
    }))

    return NextResponse.json({ results, status: data.status })
  } catch (err) {
    console.error("[places/search] fetch error:", err)
    return NextResponse.json({ error: "Failed to reach Google Places API" }, { status: 500 })
  }
}

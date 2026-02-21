import { NextRequest, NextResponse } from "next/server"
import type { PlaceDetailsResponse } from "@/lib/types/place"

const PLACES_API_BASE = "https://maps.googleapis.com/maps/api/place/details/json"

const FIELDS = [
  "place_id",
  "name",
  "formatted_address",
  "formatted_phone_number",
  "international_phone_number",
  "rating",
  "user_ratings_total",
  "price_level",
  "website",
  "opening_hours",
  "geometry",
].join(",")

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl
  const placeId = searchParams.get("place_id")?.trim()

  if (!placeId) {
    return NextResponse.json({ error: "Missing query parameter: place_id" }, { status: 400 })
  }

  const apiKey = process.env.GOOGLE_PLACES_API_KEY
  if (!apiKey) {
    return NextResponse.json(
      { error: "GOOGLE_PLACES_API_KEY is not configured" },
      { status: 500 }
    )
  }

  const params = new URLSearchParams({
    place_id: placeId,
    fields: FIELDS,
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

    const data: PlaceDetailsResponse = await res.json()

    if (data.status !== "OK") {
      return NextResponse.json(
        { error: data.error_message ?? `Google Places status: ${data.status}` },
        { status: data.status === "NOT_FOUND" ? 404 : 502 }
      )
    }

    const r = data.result
    const detail = {
      place_id: r.place_id,
      name: r.name,
      formatted_address: r.formatted_address,
      phone: r.international_phone_number ?? r.formatted_phone_number ?? null,
      rating: r.rating ?? null,
      user_ratings_total: r.user_ratings_total ?? null,
      price_level: r.price_level ?? null,
      website: r.website ?? null,
      opening_hours: r.opening_hours?.weekday_text ?? null,
      lat: r.geometry?.location.lat ?? null,
      lng: r.geometry?.location.lng ?? null,
    }

    return NextResponse.json({ detail })
  } catch (err) {
    console.error("[places/details] fetch error:", err)
    return NextResponse.json({ error: "Failed to reach Google Places API" }, { status: 500 })
  }
}

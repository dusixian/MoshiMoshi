// Google Places API types

export interface PlaceSearchResult {
  place_id: string
  name: string
  formatted_address: string
  rating?: number
  user_ratings_total?: number
  /** 0–4, where 4 = very expensive */
  price_level?: number
  types?: string[]
  geometry?: {
    location: { lat: number; lng: number }
  }
}

export interface PlaceDetails {
  place_id: string
  name: string
  formatted_address: string
  /** Local format, e.g. "03-3535-3600" */
  formatted_phone_number?: string
  /** International format, e.g. "+81 3-3535-3600" */
  international_phone_number?: string
  rating?: number
  user_ratings_total?: number
  /** 0–4, where 4 = very expensive */
  price_level?: number
  website?: string
  opening_hours?: {
    weekday_text?: string[]
    open_now?: boolean
  }
  geometry?: {
    location: { lat: number; lng: number }
  }
}

export interface PlaceSearchResponse {
  results: PlaceSearchResult[]
  status: string
  error_message?: string
}

export interface PlaceDetailsResponse {
  result: PlaceDetails
  status: string
  error_message?: string
}

/** price_level (0–4) → rough dinner estimate in JPY */
export function priceLevelToJpy(level?: number): string {
  switch (level) {
    case 0: return "無料"
    case 1: return "〜¥2,000"
    case 2: return "¥2,000〜¥8,000"
    case 3: return "¥8,000〜¥20,000"
    case 4: return "¥20,000〜"
    default: return "不明"
  }
}

/** price_level → yen signs string */
export function priceLevelToYenSigns(level?: number): string {
  if (level === undefined) return "–"
  return "¥".repeat(Math.max(1, level)) || "¥"
}

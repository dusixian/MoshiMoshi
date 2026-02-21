"use client"

import { useState, useRef } from "react"
import { Search, Loader2, MapPin, Phone, Star, X, ChevronRight } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { cn } from "@/lib/utils"
import { priceLevelToYenSigns } from "@/lib/types/place"
import type { PlaceSearchResult, PlaceDetails } from "@/lib/types/place"

// ------------------------------------------------------------------ types ---

export interface SelectedRestaurant {
  place_id: string
  name: string
  address: string
  phone: string | null
  rating: number | null
  user_ratings_total: number | null
  price_level: number | null
  website: string | null
  opening_hours: string[] | null
}

interface RestaurantSearchProps {
  /** Called when the user confirms a restaurant selection */
  onSelect?: (restaurant: SelectedRestaurant) => void
  /** Optional placeholder text for the search input */
  placeholder?: string
  className?: string
}

// --------------------------------------------------------------- component ---

export default function RestaurantSearch({
  onSelect,
  placeholder = "例：すきやばし次郎、Narisawa Tokyo …",
  className,
}: RestaurantSearchProps) {
  const [query, setQuery] = useState("")
  const [results, setResults] = useState<PlaceSearchResult[]>([])
  const [selected, setSelected] = useState<SelectedRestaurant | null>(null)
  const [loadingSearch, setLoadingSearch] = useState(false)
  const [loadingDetail, setLoadingDetail] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  // ---- search ----

  async function handleSearch() {
    const q = query.trim()
    if (!q) return

    setError(null)
    setResults([])
    setSelected(null)
    setLoadingSearch(true)

    try {
      const res = await fetch(`/api/places/search?q=${encodeURIComponent(q)}`)
      const data = await res.json()

      if (!res.ok) {
        setError(data.error ?? "検索中にエラーが発生しました")
        return
      }

      if (data.status === "ZERO_RESULTS" || data.results.length === 0) {
        setError("該当する飲食店が見つかりませんでした。別のキーワードでお試しください。")
        return
      }

      setResults(data.results)
    } catch {
      setError("通信エラーが発生しました。しばらくしてから再試行してください。")
    } finally {
      setLoadingSearch(false)
    }
  }

  // ---- select a result → fetch details ----

  async function handleSelectResult(result: PlaceSearchResult) {
    setError(null)
    setLoadingDetail(true)

    try {
      const res = await fetch(`/api/places/details?place_id=${result.place_id}`)
      const data = await res.json()

      if (!res.ok) {
        setError(data.error ?? "詳細情報の取得中にエラーが発生しました")
        return
      }

      const d = data.detail
      setSelected({
        place_id: d.place_id,
        name: d.name,
        address: d.formatted_address,
        phone: d.phone,
        rating: d.rating,
        user_ratings_total: d.user_ratings_total,
        price_level: d.price_level,
        website: d.website,
        opening_hours: d.opening_hours,
      })
      setResults([]) // hide list once a place is picked
    } catch {
      setError("通信エラーが発生しました。しばらくしてから再試行してください。")
    } finally {
      setLoadingDetail(false)
    }
  }

  // ---- confirm selection ----

  function handleConfirm() {
    if (selected) onSelect?.(selected)
  }

  // ---- reset ----

  function handleReset() {
    setQuery("")
    setResults([])
    setSelected(null)
    setError(null)
    inputRef.current?.focus()
  }

  // ---------------------------------------------------------------- render ---

  return (
    <div className={cn("flex flex-col gap-3", className)}>
      {/* Search bar */}
      <div className="flex gap-2">
        <Input
          ref={inputRef}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleSearch()}
          placeholder={placeholder}
          disabled={loadingSearch || loadingDetail}
          className="flex-1"
        />
        <Button
          onClick={handleSearch}
          disabled={!query.trim() || loadingSearch || loadingDetail}
          variant="default"
          size="default"
        >
          {loadingSearch ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Search className="h-4 w-4" />
          )}
          <span className="ml-1.5">検索</span>
        </Button>
      </div>

      {/* Error */}
      {error && (
        <p className="text-sm text-destructive px-1">{error}</p>
      )}

      {/* Loading detail spinner */}
      {loadingDetail && (
        <div className="flex items-center gap-2 text-sm text-muted-foreground px-1">
          <Loader2 className="h-4 w-4 animate-spin" />
          <span>詳細情報を取得中…</span>
        </div>
      )}

      {/* Search results list */}
      {results.length > 0 && !selected && (
        <div className="flex flex-col gap-1.5">
          <p className="text-xs text-muted-foreground px-1">
            {results.length} 件の候補 — 選択してください
          </p>
          {results.map((r) => (
            <button
              key={r.place_id}
              onClick={() => handleSelectResult(r)}
              disabled={loadingDetail}
              className={cn(
                "w-full text-left rounded-lg border border-border px-4 py-3",
                "hover:bg-accent transition-colors",
                "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
                loadingDetail && "opacity-50 cursor-not-allowed"
              )}
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm truncate">{r.name}</p>
                  <p className="text-xs text-muted-foreground mt-0.5 truncate">
                    {r.formatted_address}
                  </p>
                </div>
                <div className="flex items-center gap-2 shrink-0 mt-0.5">
                  {r.rating !== undefined && (
                    <span className="flex items-center gap-0.5 text-xs text-muted-foreground">
                      <Star className="h-3 w-3 fill-yellow-400 text-yellow-400" />
                      {r.rating.toFixed(1)}
                    </span>
                  )}
                  {r.price_level !== undefined && (
                    <span className="text-xs text-muted-foreground">
                      {priceLevelToYenSigns(r.price_level)}
                    </span>
                  )}
                  <ChevronRight className="h-3.5 w-3.5 text-muted-foreground" />
                </div>
              </div>
            </button>
          ))}
        </div>
      )}

      {/* Selected restaurant detail card */}
      {selected && (
        <Card className="border-primary/40 bg-primary/5">
          <CardContent className="pt-4 pb-4 px-4">
            <div className="flex items-start justify-between gap-2 mb-3">
              <h3 className="font-semibold text-sm leading-snug">{selected.name}</h3>
              <button
                onClick={handleReset}
                className="shrink-0 text-muted-foreground hover:text-foreground transition-colors"
                aria-label="選択をリセット"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="flex flex-col gap-1.5">
              {/* Address */}
              <div className="flex items-start gap-1.5 text-xs text-muted-foreground">
                <MapPin className="h-3.5 w-3.5 mt-0.5 shrink-0" />
                <span>{selected.address}</span>
              </div>

              {/* Phone */}
              {selected.phone && (
                <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                  <Phone className="h-3.5 w-3.5 shrink-0" />
                  <span>{selected.phone}</span>
                </div>
              )}

              {/* Rating + price */}
              <div className="flex items-center gap-3 mt-1">
                {selected.rating !== null && (
                  <span className="flex items-center gap-1 text-xs">
                    <Star className="h-3.5 w-3.5 fill-yellow-400 text-yellow-400" />
                    <span className="font-medium">{selected.rating.toFixed(1)}</span>
                    {selected.user_ratings_total !== null && (
                      <span className="text-muted-foreground">
                        ({selected.user_ratings_total.toLocaleString()})
                      </span>
                    )}
                  </span>
                )}
                {selected.price_level !== null && (
                  <span className="text-xs text-muted-foreground">
                    {priceLevelToYenSigns(selected.price_level)}
                  </span>
                )}
              </div>
            </div>

            {onSelect && (
              <Button onClick={handleConfirm} className="mt-4 w-full" size="sm">
                このレストランを使用する
              </Button>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  )
}

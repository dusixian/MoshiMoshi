//
//  GooglePlacesService.swift
//  MoshiMoshi
//

import Foundation

// MARK: - Google Place Model

struct GooglePlaceResult: Identifiable {
    let id: String          // place_id
    let name: String
    let address: String?
    let rating: Double?
    let photoReference: String?
    var phone: String?
    var latitude: Double?
    var longitude: Double?

    func toRestaurant() -> Restaurant {
        let lat = latitude
        let lng = longitude
        let mapsUrl: String? = lat != nil && lng != nil
            ? "https://www.google.com/maps/search/?api=1&query=\(lat!),\(lng!)"
            : nil
        return Restaurant(
            id: abs(id.hashValue % 999999),
            name: name,
            nameJa: nil,
            city: cityFromAddress(),
            area: nil,
            address: address,
            phone: phone,
            googleRating: rating,
            pricePerPersonUsdApprox: nil,
            cuisine: nil,
            michelinStars: nil,
            reservationDifficulty: nil,
            notes: nil,
            imageUrl: nil,
            mapsUrl: mapsUrl
        )
    }

    private func cityFromAddress() -> String? {
        // Try to extract city-level info from formatted_address as a best-effort
        guard let addr = address else { return nil }
        let parts = addr.split(separator: ",")
        if parts.count >= 2 {
            return String(parts[parts.count - 2]).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
}

// MARK: - Service

class GooglePlacesService: ObservableObject {
    private let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GOOGLE_PLACES_API_KEY"] as? String else {
            fatalError("Missing GOOGLE_PLACES_API_KEY in Secrets.plist")
        }
        return key
    }()

    struct RegionSuggestion: Identifiable {
        let id: String          // place_id
        let name: String        // e.g. "Tokyo", "Kyoto"
        let fullDescription: String  // e.g. "Tokyo, Japan"
    }

    func autocompleteRegions(query: String) async throws -> [RegionSuggestion] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        // types=(cities) restricts to cities/municipalities; no country restriction so any region works
        let urlStr = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(q)&types=(cities)&language=en&key=\(apiKey)"
        guard let url = URL(string: urlStr) else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AutocompleteResponse.self, from: data)

        return response.predictions.map { p in
            RegionSuggestion(
                id: p.placeId,
                name: p.structuredFormatting.mainText,
                fullDescription: p.description
            )
        }
    }

    func fetchRegionLocation(placeId: String) async throws -> (lat: Double, lng: Double)? {
        let urlStr = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeId)&fields=geometry&key=\(apiKey)"
        guard let url = URL(string: urlStr) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
        guard let loc = response.result?.geometry?.location else { return nil }
        return (loc.lat, loc.lng)
    }

    func searchRestaurants(query: String, lat: Double? = nil, lng: Double? = nil) async throws -> [GooglePlaceResult] {
        let q = (query + " restaurant").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        var urlStr = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(q)&type=restaurant&key=\(apiKey)"
        if let lat, let lng {
            // location + radius strongly biases results to that area (50km)
            urlStr += "&location=\(lat),\(lng)&radius=50000"
        }
        guard let url = URL(string: urlStr) else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TextSearchResponse.self, from: data)

        return response.results.map { r in
            GooglePlaceResult(
                id: r.placeId,
                name: r.name,
                address: r.formattedAddress,
                rating: r.rating,
                photoReference: r.photos?.first?.photoReference,
                phone: nil,
                latitude: r.geometry?.location.lat,
                longitude: r.geometry?.location.lng
            )
        }
    }

    func fetchDetails(placeId: String) async throws -> GooglePlaceResult? {
        let urlStr = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeId)&fields=name,formatted_phone_number,formatted_address,rating,geometry,photos&key=\(apiKey)"
        guard let url = URL(string: urlStr) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)

        guard let r = response.result else { return nil }
        return GooglePlaceResult(
            id: placeId,
            name: r.name,
            address: r.formattedAddress,
            rating: r.rating,
            photoReference: r.photos?.first?.photoReference,
            phone: r.formattedPhoneNumber,
            latitude: r.geometry?.location.lat,
            longitude: r.geometry?.location.lng
        )
    }

    func photoURL(reference: String, maxWidth: Int = 400) -> URL? {
        URL(string: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(maxWidth)&photo_reference=\(reference)&key=\(apiKey)")
    }
}

// MARK: - Response models

private struct TextSearchResponse: Codable {
    let results: [PlaceItem]

    struct PlaceItem: Codable {
        let placeId: String
        let name: String
        let formattedAddress: String?
        let rating: Double?
        let photos: [Photo]?
        let geometry: Geometry?

        enum CodingKeys: String, CodingKey {
            case placeId = "place_id"
            case name
            case formattedAddress = "formatted_address"
            case rating, photos, geometry
        }
    }

    struct Photo: Codable {
        let photoReference: String
        enum CodingKeys: String, CodingKey { case photoReference = "photo_reference" }
    }

    struct Geometry: Codable {
        let location: Location
    }

    struct Location: Codable {
        let lat: Double
        let lng: Double
    }
}

private struct PlaceDetailsResponse: Codable {
    let result: PlaceDetail?

    struct PlaceDetail: Codable {
        let name: String
        let formattedPhoneNumber: String?
        let formattedAddress: String?
        let rating: Double?
        let geometry: Geometry?
        let photos: [Photo]?

        enum CodingKeys: String, CodingKey {
            case name
            case formattedPhoneNumber = "formatted_phone_number"
            case formattedAddress = "formatted_address"
            case rating, geometry, photos
        }
    }

    struct Photo: Codable {
        let photoReference: String
        enum CodingKeys: String, CodingKey { case photoReference = "photo_reference" }
    }

    struct Geometry: Codable {
        let location: Location
    }

    struct Location: Codable {
        let lat: Double
        let lng: Double
    }
}

private struct AutocompleteResponse: Codable {
    let predictions: [Prediction]

    struct Prediction: Codable {
        let placeId: String
        let description: String
        let structuredFormatting: StructuredFormatting

        enum CodingKeys: String, CodingKey {
            case placeId = "place_id"
            case description
            case structuredFormatting = "structured_formatting"
        }
    }

    struct StructuredFormatting: Codable {
        let mainText: String
        enum CodingKeys: String, CodingKey { case mainText = "main_text" }
    }
}

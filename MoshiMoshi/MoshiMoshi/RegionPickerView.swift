//
//  RegionPickerView.swift
//  MoshiMoshi
//

import SwiftUI

struct RegionPickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var placesService = GooglePlacesService()
    @StateObject private var profileService = ProfileService()

    @State private var searchText: String = ""
    @State private var suggestions: [GooglePlacesService.RegionSuggestion] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var savedRegion: String = ""
    @State private var isSaving = false

    var onSaved: ((String) -> Void)? = nil

    // place_id → (lat, lng) for quick picks (avoids extra API call)
    private let quickPickCoords: [String: (Double, Double)] = [
        "Tokyo":     (35.6762, 139.6503),
        "Kyoto":     (35.0116, 135.7681),
        "Osaka":     (34.6937, 135.5023),
        "Fukuoka":   (33.5904, 130.4017),
        "Sapporo":   (43.0642, 141.3469),
        "Nagoya":    (35.1815, 136.9066),
        "Hiroshima": (34.3853, 132.4553),
        "Nara":      (34.6851, 135.8048),
    ]
    private var quickPicks: [String] { quickPickCoords.keys.sorted() }

    var body: some View {
        ZStack {
            Color.sushiRice.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search city or region...", text: $searchText)
                        .foregroundColor(.sushiNori)
                        .autocorrectionDisabled()
                    if isSearching {
                        ProgressView().scaleEffect(0.8)
                    }
                    if !searchText.isEmpty {
                        Button(action: { searchText = ""; suggestions = [] }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 16)

                // Autocomplete results
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions) { suggestion in
                            Button(action: { select(suggestion.name, placeId: suggestion.id) }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.sushiSalmon)
                                        .font(.system(size: 16))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.sushiNori)
                                        Text(suggestion.fullDescription)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    if suggestion.name == savedRegion {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.sushiSalmon)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            if suggestion.id != suggestions.last?.id {
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    .padding(.top, 8)
                } else if searchText.isEmpty {
                    // Quick picks when search is empty
                    VStack(alignment: .leading, spacing: 12) {
                        Text("POPULAR IN JAPAN")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 24)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(quickPicks, id: \.self) { city in
                                Button(action: { select(city) }) {
                                    Text(city)
                                        .font(.system(size: 14, weight: savedRegion == city ? .semibold : .regular))
                                        .foregroundColor(savedRegion == city ? .white : .sushiNori)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(savedRegion == city ? Color.sushiSalmon : Color.cardBackground)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                // Current selection footer
                if !savedRegion.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.sushiWasabi)
                        Text("Saved: \(savedRegion)")
                            .font(.system(size: 14))
                            .foregroundColor(.sushiNori)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.sushiWasabi.opacity(0.1))
                }
            }
        }
        .navigationTitle("Default Region")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchText) { text in
            searchTask?.cancel()
            suggestions = []
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            guard trimmed.count >= 1 else { return }
            isSearching = true
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                do {
                    let results = try await placesService.autocompleteRegions(query: trimmed)
                    await MainActor.run {
                        suggestions = results
                        isSearching = false
                    }
                } catch {
                    await MainActor.run { isSearching = false }
                }
            }
        }
        .task { await loadCurrentRegion() }
    }

    private func select(_ region: String, placeId: String? = nil) {
        savedRegion = region
        searchText = ""
        suggestions = []
        hideKeyboard()
        isSaving = true
        Task {
            // Save region name to Supabase (only updates default_region, not other fields)
            try? await profileService.updateDefaultRegion(region)

            // Save coordinates so Discover can bias search without using device GPS
            if let coords = quickPickCoords[region] {
                saveCoords(coords.0, coords.1)
            } else if let pid = placeId {
                if let coords = try? await placesService.fetchRegionLocation(placeId: pid) {
                    saveCoords(coords.lat, coords.lng)
                }
            }

            await MainActor.run {
                isSaving = false
                onSaved?(region)
            }
        }
    }

    private func saveCoords(_ lat: Double, _ lng: Double) {
        UserDefaults.standard.set(lat, forKey: "defaultRegionLat")
        UserDefaults.standard.set(lng, forKey: "defaultRegionLng")
    }

    private func loadCurrentRegion() async {
        if let profile = try? await profileService.fetchProfile(),
           let region = profile.defaultRegion, !region.isEmpty {
            await MainActor.run { savedRegion = region }
        }
    }
}

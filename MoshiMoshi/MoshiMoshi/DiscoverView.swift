//
//  DiscoverView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/2/5.
//

import SwiftUI
import Supabase

struct DiscoverView: View {
    @ObservedObject var viewModel: ReservationViewModel
    @ObservedObject private var lm = LocalizationManager.shared
    @State private var searchText = ""
    @State private var restaurants: [Restaurant] = []
    @State private var isLoading = true

    // Google Places search
    @StateObject private var placesService = GooglePlacesService()
    @StateObject private var profileService = ProfileService()
    @State private var defaultRegion: String = "Tokyo"
    @State private var regionLat: Double? = nil
    @State private var regionLng: Double? = nil
    @State private var googleResults: [GooglePlaceResult] = []
    @State private var isSearchingGoogle = false
    @State private var searchTask: Task<Void, Never>? = nil

    var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    var filteredRestaurants: [Restaurant] {
        if searchText.isEmpty { return restaurants }
        return restaurants.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.cuisine?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.city?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.sushiRice.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // --- Search Bar ---
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)

                            TextField(String(format: L("Search in %@..."), defaultRegion), text: $searchText)
                                .foregroundColor(.sushiNori)

                            if isSearchingGoogle {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if isSearching {
                            // --- Google Places Results ---
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.sushiSalmon)
                                    Text(L("Search Results"))
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.sushiNori)
                                }
                                .padding(.horizontal)

                                if googleResults.isEmpty && !isSearchingGoogle {
                                    Text(L("No results found"))
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal)
                                } else {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12)
                                    ], spacing: 16) {
                                        ForEach(googleResults) { place in
                                            PlaceResultCard(place: place, viewModel: viewModel, placesService: placesService)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        } else {
                            // --- Offline Restaurant Section ---
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L("Offline Restaurant?"))
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.sushiNori)

                                Text(L("Can't find here? Give us the name and phone number, MoshiMoshi will handle the rest!"))
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .lineSpacing(2)

                                NavigationLink(destination: ReservationFormView(viewModel: viewModel)) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 14))
                                        Text(L("Manual Reservation"))
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.sushiSalmon)
                                    .cornerRadius(24)
                                }
                                .padding(.top, 4)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.sushiSalmon.opacity(0.15),
                                        Color.cardBackground
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                            .padding(.horizontal)

                            // --- Restaurant List ---
                            VStack(alignment: .leading, spacing: 16) {
                                Text(L("Featured Restaurants"))
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.sushiNori)
                                    .padding(.horizontal)

                                if isLoading {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                    .padding(.top, 40)
                                } else {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12)
                                    ], spacing: 16) {
                                        ForEach(filteredRestaurants) { restaurant in
                                            RestaurantCard(restaurant: restaurant, viewModel: viewModel)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle(L("Discover"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadRestaurants()
                if let profile = try? await profileService.fetchProfile(),
                   let region = profile.defaultRegion, !region.isEmpty {
                    defaultRegion = region
                }
                // Load saved coordinates (set by RegionPickerView); default to Tokyo
                let lat = UserDefaults.standard.double(forKey: "defaultRegionLat")
                let lng = UserDefaults.standard.double(forKey: "defaultRegionLng")
                regionLat = lat != 0 ? lat : 35.6762
                regionLng = lng != 0 ? lng : 139.6503
            }
            .onChange(of: searchText) { query in
                searchTask?.cancel()
                googleResults = []
                let trimmed = query.trimmingCharacters(in: .whitespaces)
                guard trimmed.count >= 2 else { return }
                isSearchingGoogle = true
                let lat = regionLat
                let lng = regionLng
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    guard !Task.isCancelled else { return }
                    do {
                        let results = try await placesService.searchRestaurants(query: trimmed, lat: lat, lng: lng)
                        await MainActor.run {
                            googleResults = results
                            isSearchingGoogle = false
                        }
                    } catch {
                        await MainActor.run { isSearchingGoogle = false }
                    }
                }
            }
        }
    }

    private func loadRestaurants() async {
        do {
            let result: [Restaurant] = try await SupabaseClientManager.client
                .from("resturant")
                .select()
                .execute()
                .value
            restaurants = result.shuffled()
        } catch {
            print("Failed to load restaurants:", error)
        }
        isLoading = false
    }
}


// Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : .sushiNori)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.sushiSalmon : Color.cardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.sushiSalmon.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
    }
}


// Google Place Result Card
struct PlaceResultCard: View {
    let place: GooglePlaceResult
    @ObservedObject var viewModel: ReservationViewModel
    let placesService: GooglePlacesService
    @ObservedObject private var lm = LocalizationManager.shared

    @State private var isFetching = false
    @State private var destination: Restaurant? = nil
    @State private var isActive = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder (Google Places photo)
            imagePlaceholder
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                .overlay {
                    if let ref = place.photoReference, let url = placesService.photoURL(reference: ref) {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            }
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if let rating = place.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.sushiNori)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cardBackground.opacity(0.95))
                        .cornerRadius(12)
                        .padding(8)
                    }
                }
                .overlay(alignment: .topLeading) {
                    Image(systemName: "g.circle.fill")
                        .foregroundColor(.blue)
                        .padding(8)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(place.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.sushiNori)
                    .lineLimit(1)

                Text(place.address ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                // Hidden nav link triggered programmatically
                NavigationLink(
                    destination: ReservationFormView(viewModel: viewModel, restaurant: destination ?? place.toRestaurant()),
                    isActive: $isActive
                ) { EmptyView() }
                .hidden()

                Button(action: { Task { await fetchAndBook() } }) {
                    HStack {
                        if isFetching {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(L("Book Table"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.sushiSalmon)
                    .cornerRadius(10)
                }
                .disabled(isFetching)
                .padding(.top, 4)
            }
            .padding(12)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func fetchAndBook() async {
        isFetching = true
        if let details = try? await placesService.fetchDetails(placeId: place.id) {
            await MainActor.run {
                destination = details.toRestaurant()
                isFetching = false
                isActive = true
            }
        } else {
            await MainActor.run {
                destination = place.toRestaurant()
                isFetching = false
                isActive = true
            }
        }
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.sushiNori.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}


// Restaurant Card Component
struct RestaurantCard: View {
    let restaurant: Restaurant
    @ObservedObject var viewModel: ReservationViewModel
    @ObservedObject private var lm = LocalizationManager.shared
    @Environment(\.openURL) var openURL
    @State private var showMapConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Restaurant Image
            imagePlaceholder
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                .overlay {
                    if let imageUrl = restaurant.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            }
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if let rating = restaurant.googleRating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.sushiNori)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cardBackground.opacity(0.95))
                        .cornerRadius(12)
                        .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Restaurant Details
            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.sushiNori)
                    .lineLimit(1)

                Text([priceText, restaurant.cuisine].compactMap { $0 }.joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                Button(action: { showMapConfirm = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.sushiSalmon)
                        Text(restaurant.city ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .confirmationDialog(L("Open Google Maps"), isPresented: $showMapConfirm) {
                    Button(L("Open Google Maps")) {
                        openInMaps(name: restaurant.name, address: restaurant.address)
                    }
                    Button(L("Cancel"), role: .cancel) { }
                } message: {
                    Text(restaurant.address ?? restaurant.name)
                }

                // Book Table Button
                NavigationLink(destination: ReservationFormView(viewModel: viewModel, restaurant: restaurant)) {
                    Text(L("Book Table"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.sushiSalmon)
                        .cornerRadius(10)
                }
                .padding(.top, 4)
            }
            .padding(12)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func openInMaps(name: String, address: String?) {
        if let mapsUrl = restaurant.mapsUrl, let url = URL(string: mapsUrl) {
            openURL(url)
            return
        }
        let query = "\(name) \(address ?? "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)") {
            openURL(url)
        }
    }

    private var priceText: String? {
        guard let price = restaurant.pricePerPersonUsdApprox else { return nil }
        return "From $\(price)"
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.sushiSalmon.opacity(0.3), Color.sushiNori.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}


#Preview {
    DiscoverView(viewModel: ReservationViewModel())
}

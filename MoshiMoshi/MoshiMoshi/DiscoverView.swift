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
    @State private var searchText = ""
    @State private var restaurants: [Restaurant] = []
    @State private var isLoading = true

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

                            TextField("Search restaurants", text: $searchText)
                                .foregroundColor(.sushiNori)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // --- Offline Restaurant Section ---
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Offline Restaurant?")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.sushiNori)

                            Text("Can't find here? Give us the name and phone number, MoshiMoshi will handle the rest!")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.8))
                                .lineSpacing(2)

                            NavigationLink(destination: ReservationFormView(viewModel: viewModel)) {
                                HStack(spacing: 6) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 14))
                                    Text("Manual Reservation")
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
                                    Color.white
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
                            Text("Featured Restaurants")
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
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadRestaurants()
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
            .background(isSelected ? Color.sushiSalmon : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.sushiSalmon.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
    }
}


// Restaurant Card Component
struct RestaurantCard: View {
    let restaurant: Restaurant
    @ObservedObject var viewModel: ReservationViewModel

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
                        .background(Color.white.opacity(0.95))
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

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.sushiSalmon)
                    Text(restaurant.city ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                // Book Table Button
                NavigationLink(destination: ReservationFormView(viewModel: viewModel, restaurant: restaurant)) {
                    Text("Book Table")
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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

//
//  DiscoverView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/2/5.
//

import SwiftUI

struct DiscoverView: View {
    @ObservedObject var viewModel: ReservationViewModel
    @State private var searchText = ""
    @State private var isPresentingManualReservation = false

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

                            Button(action: {
                                isPresentingManualReservation = true
                            }) {
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

                        // --- Filter Buttons ---
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterChip(title: "All", isSelected: true)
                                FilterChip(title: "Sushi/Edomae", isSelected: false)
                                FilterChip(title: "Kaiseki", isSelected: false)
                                FilterChip(title: "Kappo", isSelected: false)
                                FilterChip(title: "Tempura", isSelected: false)
                                FilterChip(title: "Yakitori", isSelected: false)
                                FilterChip(title: "Teppanyaki", isSelected: false)
                                FilterChip(title: "Modern", isSelected: false)
                                FilterChip(title: "Seasonal", isSelected: false)
                            }
                            .padding(.horizontal)
                        }

                        // --- Restaurant List ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Featured Restaurants")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.sushiNori)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                RestaurantCard(
                                    name: "Ren Omakase",
                                    priceRange: "From $100",
                                    cuisine: "Omakase",
                                    location: "Kyoto",
                                    rating: 4.8,
                                    imageName: "restaurant1"
                                )

                                RestaurantCard(
                                    name: "Sushi Saito",
                                    priceRange: "From $150",
                                    cuisine: "Sushi",
                                    location: "Tokyo",
                                    rating: 4.9,
                                    imageName: "restaurant2"
                                )

                                RestaurantCard(
                                    name: "Kikunoi",
                                    priceRange: "From $180",
                                    cuisine: "Kaiseki",
                                    location: "Kyoto",
                                    rating: 4.7,
                                    imageName: "restaurant3"
                                )

                                RestaurantCard(
                                    name: "Tempura Kondo",
                                    priceRange: "From $120",
                                    cuisine: "Tempura",
                                    location: "Tokyo",
                                    rating: 4.6,
                                    imageName: "restaurant4"
                                )

                                RestaurantCard(
                                    name: "Yakitori Torishiki",
                                    priceRange: "From $90",
                                    cuisine: "Yakitori",
                                    location: "Tokyo",
                                    rating: 4.8,
                                    imageName: "restaurant5"
                                )

                                RestaurantCard(
                                    name: "Narisawa",
                                    priceRange: "From $200",
                                    cuisine: "Modern",
                                    location: "Tokyo",
                                    rating: 4.9,
                                    imageName: "restaurant6"
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $isPresentingManualReservation) {
            NavigationView {
                ReservationFormView(viewModel: viewModel)
            }
        }
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
    let name: String
    let priceRange: String
    let cuisine: String
    let location: String
    let rating: Double
    let imageName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Restaurant Image
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.sushiSalmon.opacity(0.3), Color.sushiNori.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)

                // Rating Badge
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
            .cornerRadius(12)

            // Restaurant Details
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.sushiNori)
                    .lineLimit(1)

                Text("\(priceRange) · \(cuisine)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.sushiSalmon)
                    Text(location)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                // Book Table Button
                Button(action: {
                    // No action for now
                }) {
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
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}


#Preview {
    DiscoverView(viewModel: ReservationViewModel())
}

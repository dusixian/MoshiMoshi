//
//  HomeView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/2/5.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: ReservationViewModel
    @Binding var selectedTab: Int

    var body: some View {
        NavigationView {
            ZStack {
                Color.sushiRice.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {

                        // --- Welcome Section ---
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ready for your next reservation?")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)

                        // --- Start New Reservation Card ---
                        Button(action: {
                            selectedTab = 1  // Switch to Discover tab
                        }) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Start a New Reservation")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("Note: Restaurant availability varies. Agent will call to confirm.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack {
                                    Text("Book Now")
                                        .font(.system(size: 14))
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12))
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(16)
                                .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.sushiSalmon, Color.sushiSalmon.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: Color.sushiSalmon.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.top, -10)

                        // --- Upcoming Events Section ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Upcoming Events")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.sushiNori)
                                .padding(.horizontal)

                            if viewModel.reservations.filter({ $0.status == .confirmed }).isEmpty {
                                // Empty State
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray.opacity(0.4))

                                    Text("No upcoming reservations")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(Color.white)
                                .cornerRadius(16)
                                .padding(.horizontal)

                            } else {
                                // Show only confirmed reservations
                                ForEach(viewModel.reservations.filter { $0.status == .confirmed }.prefix(5)) { item in
                                    UpcomingEventCard(item: item)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // --- Suggested Dining Section ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Suggested Dining")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.sushiNori)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                SuggestedDiningCard(
                                    name: "Ren Omakase",
                                    priceRange: "From $100",
                                    cuisine: "Omakase",
                                    location: "Kyoto",
                                    rating: 4.8,
                                    imageName: "restaurant1"
                                )

                                SuggestedDiningCard(
                                    name: "Sushi Saito",
                                    priceRange: "From $150",
                                    cuisine: "Sushi",
                                    location: "Tokyo",
                                    rating: 4.9,
                                    imageName: "restaurant2"
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("MoshiMoshi")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


// Upcoming Event Card Component
struct UpcomingEventCard: View {
    let item: ReservationItem

    var body: some View {
        HStack(spacing: 16) {
            // Date Badge
            VStack(spacing: 2) {
                Text(monthString(from: item.request.dateTime))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.sushiSalmon.opacity(0.7))
                    .textCase(.uppercase)

                Text("\(dayString(from: item.request.dateTime))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.sushiNori)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(Color.sushiRice)
            .cornerRadius(12)

            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(item.request.restaurantName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.sushiNori)

                HStack(spacing: 10) {
                    // Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(timeString(from: item.request.dateTime))
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.gray)

                    // Status Badge
                    HStack(spacing: 4) {
                        Image(systemName: item.status.icon)
                            .font(.system(size: 10))
                        Text(item.status.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(item.status.color)
                    .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // Helper functions to format date
    func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}


// Suggested Dining Card Component
struct SuggestedDiningCard: View {
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
    HomeView(viewModel: ReservationViewModel(), selectedTab: .constant(0))
}

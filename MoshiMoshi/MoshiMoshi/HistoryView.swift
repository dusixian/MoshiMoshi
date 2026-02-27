//
//  HistoryView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/2/5.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: ReservationViewModel

    @State private var showPastEvents = false
    @State private var statusFilter: ReservationStatus? = nil

    /// Past = reservation time (Japan time) is before now.
    private var filteredReservations: [ReservationItem] {
        let now = Date()
        var list = viewModel.reservations
        if !showPastEvents {
            list = list.filter { $0.request.dateTime > now }
        }
        if let status = statusFilter {
            list = list.filter { $0.status == status }
        }
        return list
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.sushiRice.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Filters
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $showPastEvents) {
                                Text("Show past events")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.sushiNori)
                            }
                            .tint(.sushiSalmon)

                            Text("Status")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    StatusFilterChip(
                                        title: "All",
                                        isSelected: statusFilter == nil
                                    ) { statusFilter = nil }
                                    ForEach([ReservationStatus.confirmed, .actionRequired, .failed, .incomplete, .pending, .cancelled], id: \.self) { status in
                                        StatusFilterChip(
                                            title: status.rawValue,
                                            isSelected: statusFilter == status
                                        ) { statusFilter = status }
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        if filteredReservations.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.4))
                                Text(showPastEvents && statusFilter == nil && viewModel.reservations.isEmpty
                                     ? "No reservation history"
                                     : "No reservations match the current filters")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)

                        } else {
                            ForEach(filteredReservations) { item in
                                ReservationTicketView(item: item, viewModel: viewModel)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.fetchUserHistory()
            }
        }
    }
}

// MARK: - Filter chip for status (matches Discover FilterChip colors)
private struct StatusFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .sushiNori)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.sushiSalmon : Color.white)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HistoryView(viewModel: ReservationViewModel())
}

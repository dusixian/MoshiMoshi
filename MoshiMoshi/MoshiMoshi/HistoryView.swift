//
//  HistoryView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/2/5.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: ReservationViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.sushiRice.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if viewModel.reservations.isEmpty {
                            // Empty State
                            VStack(spacing: 20) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.4))

                                Text("No reservation history")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)

                        } else {
                            // Show all reservations with full details
                            ForEach(viewModel.reservations) { item in
                                ReservationTicketView(item: item)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView(viewModel: ReservationViewModel())
}

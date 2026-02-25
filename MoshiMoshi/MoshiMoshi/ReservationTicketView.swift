//
//  ReservationTicketView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/23.
//


import SwiftUI

struct ReservationTicketView: View {
    let item: ReservationItem
    @State private var showResponseSheet = false
    var isActionRequired: Bool { item.status == .actionRequired }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 1. Header: Restaurant Name & Status
            HStack(alignment: .top) {
                // temp image
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(item.request.restaurantName.prefix(1))
                            .font(.headline)
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.request.restaurantName)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                    
                    // Status Badge
                    Text(item.status.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(item.status.color.opacity(0.15))
                        .foregroundColor(item.status.color)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            // 2. Info Grid: Date, Time, Party, etc.
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    InfoRow(icon: "calendar", text: formatDate(item.request.dateTime))
                    Spacer()
                    // temp price range
                    InfoRow(icon: "dollarsign.circle", text: "Price TBD")
                        .frame(width: 140, alignment: .leading)
                }
                
                HStack(alignment: .top) {
                    InfoRow(icon: "clock", text: formatTime(item.request.dateTime))
                    Spacer()
                    // Temp location
                    InfoRow(icon: "mappin.and.ellipse", text: "Japan")
                        .frame(width: 140, alignment: .leading)
                }
                
                InfoRow(icon: "person.2", text: "\(item.request.partySize) People")
            }
            .foregroundColor(.secondary)
            
            var isActionRequired: Bool { item.status == .actionRequired }
            
            // 3. Bottom Button
            if isActionRequired {
                Button(action: {
                    showResponseSheet = true
                }) {
                    Text("Respond to Request")
                        .font(.system(size: 18, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.sushiTuna)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .padding(.top, 5)
            } else {
                NavigationLink(destination: ReservationDetailView(item: item)) {
                    Text("View Details")
                        .font(.system(size: 18, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .foregroundColor(.black)
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.top, 5)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showResponseSheet) {
            ActionResponseView(item: item)
        }
    }
    
    // MARK: - Helper Views & Formatters
    
    private func InfoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .frame(width: 24)
            Text(text)
                .font(.system(size: 16))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date) + " (GMT+9)"
    }
}

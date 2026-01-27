//
//  ReservationTicketView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/23.
//


import SwiftUI

struct ReservationTicketView: View {
    let item: ReservationItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(item.status.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: item.status.icon)
                    .font(.title3)
                    .foregroundColor(item.status.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Restaurant Name
                Text(item.request.restaurantName)
                    .font(.headline)
                    .foregroundColor(.sushiNori)
                
                // Result Message
                Text(item.resultMessage ?? "Processing...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Timestamp
                Text(item.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.top, 4)
            }
            
            Spacer()
            
            // Status Badge
            Text(item.status.rawValue.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.status.color.opacity(0.1))
                .foregroundColor(item.status.color)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

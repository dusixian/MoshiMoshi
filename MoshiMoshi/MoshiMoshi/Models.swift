//
//  Models.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/23.
//

import Foundation
import SwiftUI


struct ReservationRequest: Codable {
    var restaurantName: String = ""
    var restaurantPhone: String = ""
    var customerName: String = ""
    var customerPhone: String = ""
    
    var dateTime: Date = Date()
    
    var reservationDate: String = ""
    var reservationTime: String = ""
    
    var partySize: Int = 2
    var specialRequests: String = ""
    
    // Mapping keys to match Python/Next.js snake_case
    enum CodingKeys: String, CodingKey {
        case restaurantName = "restaurant_name"
        case restaurantPhone = "restaurant_phone"
        case customerName = "customer_name"
        case customerPhone = "customer_phone"
        case reservationDate = "reservation_date"
        case reservationTime = "reservation_time"
        case partySize = "party_size"
        case specialRequests = "special_requests"
    }
}


struct ReservationData: Codable, Identifiable {
    let id: String
    let status: String
    let bookingConfirmed: Bool?
    let failureReason: String?
    
    struct Details: Codable {
        let notes: String?
        let alternative_times: String?
        let status: String?
    }
    let confirmationDetails: Details?
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case bookingConfirmed = "booking_confirmed"
        case failureReason = "failure_reason"
        case confirmationDetails = "confirmation_details"
    }
}


struct CreateReservationResponse: Codable {
    let success: Bool
    let reservation: ReservationData
}


enum ReservationStatus: String, Codable {
    case pending = "Calling..."
    case confirmed = "Confirmed"
    case failed = "Failed"
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .confirmed: return .sushiWasabi
        case .failed: return .sushiTuna
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "phone.connection"
        case .confirmed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}


struct ReservationItem: Identifiable {
    let id: UUID = UUID()
    var backendId: String?
    let request: ReservationRequest
    var status: ReservationStatus
    var resultMessage: String?
    let timestamp = Date()
}

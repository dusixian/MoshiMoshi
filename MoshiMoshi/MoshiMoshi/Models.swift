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


struct BackendResponse: Codable {
    let success: Bool?
    let message: String?
    let error: String?
}


enum ReservationStatus: String, Codable {
    case pending = "Calling..."
    case confirmed = "Confirmed"
    case failed = "Failed"
    case busy = "Line Busy"
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .confirmed: return .sushiWasabi // Green
        case .failed, .busy: return .sushiTuna   // Red
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "phone.connection"
        case .confirmed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .busy: return "phone.down.circle.fill"
        }
    }
}

struct ReservationItem: Identifiable {
    let id = UUID()
    let request: ReservationRequest
    var status: ReservationStatus
    var resultMessage: String?
    let timestamp = Date()
}

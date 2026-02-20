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
    var customerEmail: String = ""

    var dateTime: Date = Date()

    var reservationDate: String = ""
    var reservationTime: String = ""

    var partySize: Int = 2
    var specialRequests: String = ""

    enum CodingKeys: String, CodingKey {
        case restaurantName = "restaurant_name"
        case restaurantPhone = "restaurant_phone"
        case customerName = "customer_name"
        case customerPhone = "customer_phone"
        case customerEmail = "customer_email"
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
        let summary: String?
        let results: DataResults?
        let transcript: [ChatMessage]?
        let callStats: CallStats?
        
        struct DataResults: Codable {
            let reservationStatus: ValueWrapper?
            let requiredAction: ValueWrapper?
            let rejectionReason: ValueWrapper?
            let restaurantNotes: ValueWrapper?
                
            enum CodingKeys: String, CodingKey {
                case reservationStatus = "reservation_status"
                case requiredAction = "required_action"
                case rejectionReason = "rejection_reason"
                case restaurantNotes = "restaurant_notes"
            }
        }
        
        struct ValueWrapper: Codable {
            let value: String?
        }
        
        struct ChatMessage: Codable, Identifiable {
            let id = UUID()
            let role: String
            let message: String
            
            enum CodingKeys: String, CodingKey {
                case role
                case message
            }
        }
        
        struct CallStats: Codable {
            let duration: Double
            let cost: Double
        }

        enum CodingKeys: String, CodingKey {
            case summary
            case results
            case transcript
            case callStats = "call_stats"
        }
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
    case actionRequired = "Action Required"
    case failed = "Failed"
    case incomplete = "Incomplete"
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .confirmed: return .sushiWasabi
        case .actionRequired: return .sushiTuna
        case .failed: return .black
        case .incomplete: return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "phone.connection"
        case .confirmed: return "checkmark.circle.fill"
        case .actionRequired: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.circle.fill"
        case .incomplete: return "phone.down.circle.fill"
        }
    }
}

struct ReservationItem: Identifiable {
    let id: UUID = UUID()
    var backendId: String?
    let request: ReservationRequest
    var status: ReservationStatus
    var resultMessage: String?
    var fullData: ReservationData?
    let timestamp = Date()
}

// MARK: - User profile (Supabase profiles table)
struct UserProfile: Codable, Equatable {
    var id: UUID?
    var fullName: String?
    var email: String?
    var phone: String?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email = "email"
        case phone = "phone"
        case updatedAt = "updated_at"
    }
}

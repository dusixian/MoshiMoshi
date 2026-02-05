//
//  ViewModel.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/23.
//

import SwiftUI
import Foundation

class ReservationViewModel: ObservableObject {
    @Published var request = ReservationRequest()
    @Published var reservations: [ReservationItem] = [] // List of history
    @Published var isSubmitting = false
    @Published var showProfileSheet = false
    
    // Persist user contact info
    @AppStorage("savedUserName") var savedUserName: String = ""
    @AppStorage("savedUserPhone") var savedUserPhone: String = ""
    
    init() {
        refreshUserData()
    }
    
    // Load default data from AppStorage
    func refreshUserData() {
        if !savedUserName.isEmpty { request.customerName = savedUserName }
        if !savedUserPhone.isEmpty { request.customerPhone = savedUserPhone }
    }
    
    // MARK: - Main Logic
    func startAICall() {
        self.isSubmitting = true
        
        // 1. Pre-processing: Format Date and Time for the Backend
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.request.reservationDate = dateFormatter.string(from: request.dateTime)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        self.request.reservationTime = timeFormatter.string(from: request.dateTime)
        
        // 2. Create a "Pending" ticket immediately for UX
        let newReservation = ReservationItem(
            request: self.request,
            status: .pending,
            resultMessage: "Connecting to AI Agent..."
        )
        
        // Insert to top of the list
        withAnimation {
            self.reservations.insert(newReservation, at: 0)
        }
        
        // 3. Initiate the Network Call asynchronously
        Task {
            do {
                // Call the API Service
                let response = try await APIService.shared.sendReservation(request: self.request)
                
                // 4. Handle Success
                await MainActor.run {
                    self.updateTicket(
                        id: newReservation.id,
                        status: .confirmed,
                        message: response.message ?? "Call initiated successfully."
                    )
                    self.isSubmitting = false
                    print("✅ Success: \(response)")
                }
                
            } catch {
                // 5. Handle Failure
                print("❌ Network Error: \(error.localizedDescription)")
                
                await MainActor.run {
                    self.updateTicket(
                        id: newReservation.id,
                        status: .failed,
                        message: "Connection failed: \(error.localizedDescription)"
                    )
                    self.isSubmitting = false
                }
            }
        }
    }
    
    // Helper function to update a specific ticket in the list
    func updateTicket(id: UUID, status: ReservationStatus, message: String) {
        if let index = reservations.firstIndex(where: { $0.id == id }) {
            withAnimation {
                reservations[index].status = status
                reservations[index].resultMessage = message
            }
        }
    }
    
    // Form Validation
    var isValid: Bool {
        return !request.restaurantName.isEmpty &&
               !request.restaurantPhone.isEmpty &&
               !request.customerName.isEmpty &&
               !request.customerPhone.isEmpty
    }
}

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
        var newUIItem = ReservationItem(
            backendId: nil,
            request: self.request,
            status: .pending,
            resultMessage: "Initiating call..."
        )
        
        // Insert to top of the list
        withAnimation {
            self.reservations.insert(newUIItem, at: 0)
        }
        
        // 3. Initiate the Network Call asynchronously
        Task {
            do {
                // Call Backend to Create
                let response = try await APIService.shared.sendReservation(request: self.request)

                // for webhook testing
                let presentationTestID = "0a43df25-e617-4ff8-9c16-2243337df28b"

                await MainActor.run {
                    // Update UI item
                    if let index = self.reservations.firstIndex(where: { $0.id == newUIItem.id }) {
                        self.reservations[index].backendId = presentationTestID
                        // self.reservations[index].backendId = response.reservation.id
                        self.reservations[index].resultMessage = "AI is calling the restaurant..."
                    }
                    self.isSubmitting = false
                }
                        
                // Start Polling
                await startPolling(backendId: presentationTestID, uiItemId: newUIItem.id)
                // await startPolling(backendId: response.reservation.id, uiItemId: newUIItem.id)
                        
            } catch {
                await MainActor.run {
                    self.updateTicket(id: newUIItem.id, status: .failed, message: "Network Error: \(error.localizedDescription)")
                    self.isSubmitting = false
                }
            }
        }
    }
    
    
    // MARK: - Polling Logic
        func startPolling(backendId: String, uiItemId: UUID) async {
            var attempts = 0
            let maxAttempts = 30 // 最多查 30 次 (60秒)
            
            while attempts < maxAttempts {
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                
                do {
                    // Check status
                    if let data = try await APIService.shared.fetchReservation(id: backendId) {
                        
                        print("🔍 Polling: Status is \(data.status)")
                        
                        // If completed
                        if data.status == "completed" || data.status == "failed" {
                            
                            await MainActor.run {
                                if data.bookingConfirmed == true {
                                    // Success
                                    let notes = data.confirmationDetails?.notes
                                    let displayMsg = (notes != nil && !notes!.isEmpty) ? notes! : "Reservation Confirmed!"
                                    self.updateTicket(id: uiItemId, status: .confirmed, message: displayMsg)
                                } else {
                                    // Fail
                                    let altTime = data.confirmationDetails?.alternative_times
                                    let reason = data.failureReason ?? "Reservation rejected"
                                    var displayMsg = reason
                                    if let alt = altTime, !alt.isEmpty {
                                        displayMsg = "\(reason)\nAlternative Time: \(alt)"
                                    }
                                    self.updateTicket(id: uiItemId, status: .failed, message: displayMsg)
                                }
                            }
                            break
                        }
                    }
                } catch {
                    print("Polling error: \(error)")
                }
                
                attempts += 1
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

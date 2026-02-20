//
//  ViewModel.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/23.
//

import SwiftUI
import Foundation
import Supabase


class ReservationViewModel: ObservableObject {
    @Published var request = ReservationRequest()
    @Published var reservations: [ReservationItem] = [] // List of history
    @Published var isSubmitting = false
    @Published var showProfileSheet = false
    
    // Fallback from UserDefaults when DB has no profile
    @AppStorage("savedUserName") var savedUserName: String = ""
    @AppStorage("savedUserPhone") var savedUserPhone: String = ""
    @AppStorage("savedUserEmail") var savedUserEmail: String = ""

    init() {
        refreshUserData()
    }

    /// Fill contact from DB profile (call when opening reservation form). Falls back to UserDefaults if no profile.
    func fillContactFromProfile(name: String?, email: String?, phone: String?) {
        if let n = name, !n.isEmpty { request.customerName = n }
        if let e = email, !e.isEmpty { request.customerEmail = e }
        if let p = phone, !p.isEmpty { request.customerPhone = p }
    }

    // Load default data from AppStorage (fallback)
    func refreshUserData() {
        if !savedUserName.isEmpty { request.customerName = savedUserName }
        if !savedUserPhone.isEmpty { request.customerPhone = savedUserPhone }
        if !savedUserEmail.isEmpty { request.customerEmail = savedUserEmail }
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
        let newUIItem = ReservationItem(
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

                // Use the real backend ID returned from the server
                let realBackendId = response.reservation.id

                await MainActor.run {
                    // Update UI item
                    if let index = self.reservations.firstIndex(where: { $0.id == newUIItem.id }) {
                        self.reservations[index].backendId = realBackendId
                        self.reservations[index].resultMessage = "AI is calling the restaurant..."
                    }
                    self.isSubmitting = false
                }
                
                // Initialize Supabase Realtime Listener
                await startRealtimeListener(backendId: realBackendId, uiItemId: newUIItem.id)
                        
            } catch {
                await MainActor.run {
                    self.updateTicket(id: newUIItem.id, status: .failed, message: "Network Error: \(error.localizedDescription)")
                    self.isSubmitting = false
                }
            }
        }
    }
    
    // MARK: - Supabase Realtime V2 Logic
        func startRealtimeListener(backendId: String, uiItemId: UUID) async {
            let channel = APIService.shared.supabase.channel("public:reservations:id=eq.\(backendId)")
                
            // 1. Establish a channel listening to the specific row matching the backendId
            let changes = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "reservations",
                filter: .eq("id", value: backendId)
            )
                
            // Subscribe to the channel
            do {
                try await channel.subscribeWithError()
                print("🎧 RealtimeV2: Listening for status updates on reservation \(backendId)...")
            } catch {
                print("❌ RealtimeV2 connection failed: \(error)")
                // If the WebSocket fails to connect, update the UI to prevent infinite loading
                await MainActor.run {
                    self.updateTicket(id: uiItemId, status: .failed, message: "Connection error. Please refresh.")
                }
                return // Exit the listener
            }
                
            // 3. Await the server push stream
            for await change in changes {
                do {
                    // Instantly decode the incoming data!
                    let updatedRecord = try change.record.decode(as: ReservationData.self)
                    print("⚡️ RealtimeV2 update received! Latest status: \(updatedRecord.status)")
                
                    await MainActor.run {
                        self.handleStatusUpdate(record: updatedRecord, uiItemId: uiItemId)
                    }
                        
                    // Mission accomplished, unsubscribe to release resources
                    await channel.unsubscribe()
                    break
                    
                } catch {
                    print("❌ RealtimeV2 data parsing failed: \(error)")
                }
            }
        }
    
    // MARK: - Helpers
    private func handleStatusUpdate(record: ReservationData, uiItemId: UUID) {
        let failureReason = record.failureReason ?? ""
        let summary = record.confirmationDetails?.analysis?.transcriptSummary ?? ""
            
        switch record.status {
        case "completed", "confirmed":
            let msg = summary.isEmpty ? "Reservation Confirmed!" : "Confirmed: \(summary)"
            updateTicket(id: uiItemId, status: .confirmed, message: msg)
                
        case "action_required":
            let msg = failureReason.isEmpty ? "Action needed." : failureReason
            updateTicket(id: uiItemId, status: .actionRequired, message: "⚠️ Action Required:\n\(msg)")
                
        case "failed":
            let msg = failureReason.isEmpty ? "Rejected by restaurant." : failureReason
            updateTicket(id: uiItemId, status: .failed, message: "❌ Failed: \(msg)")
                
        case "incomplete":
            updateTicket(id: uiItemId, status: .incomplete, message: "⚠️ Call disconnected. Please try again.")
                
        default:
            print("Received unknown status update: \(record.status)")
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

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
    @Published var hasLoadedHistory = false
    
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
                // Get user id
                let session = try await APIService.shared.supabase.auth.session
                self.request.userId = session.user.id.uuidString
                
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
    
    // MARK: - Fetch History from Database
        func fetchUserHistory() {
            guard !hasLoadedHistory else { return }
            
            Task {
                do {
                    // 1. Get the current authenticated user's session
                    let session = try await APIService.shared.supabase.auth.session
                    let currentUserId = session.user.id
                    
                    // 2. Fetch all reservation rows for this user, ordered by creation date (newest first)
                    let rows: [ReservationDBRow] = try await APIService.shared.supabase
                        .from("reservations")
                        .select()
                        .eq("user_id", value: currentUserId)
                        .order("created_at", ascending: false)
                        .execute()
                        .value
                    
                    // 3. Convert DB rows to UI-friendly ReservationItems
                    var loadedItems: [ReservationItem] = []
                    
                    for row in rows {
                        // Reconstruct the request data
                        var req = ReservationRequest()
                        req.restaurantName = row.restaurantName
                        req.restaurantPhone = row.restaurantPhone ?? ""
                        req.customerName = row.customerName ?? ""
                        req.customerPhone = row.customerPhone ?? ""
                        req.customerEmail = row.customerEmail ?? ""
                        req.partySize = row.partySize ?? 2
                        req.specialRequests = row.specialRequests ?? ""
                        req.reservationDate = row.reservationDate ?? ""
                        req.reservationTime = row.reservationTime ?? ""
                        
                        // Reconstruct DateTime in Japan time (JST) for UI and upcoming filter.
                        // DB returns DATE as "yyyy-MM-dd", TIME as "HH:mm:ss" or "HH:mm" (PostgreSQL/Supabase).
                        let jst = TimeZone(identifier: "Asia/Tokyo")!
                        let dateStr = row.reservationDate ?? ""
                        let timeStr = row.reservationTime ?? ""
                        if !dateStr.isEmpty, !timeStr.isEmpty {
                            let combinedFull = "\(dateStr) \(timeStr)"
                            let formatterWithSec = DateFormatter()
                            formatterWithSec.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            formatterWithSec.timeZone = jst
                            let formatterNoSec = DateFormatter()
                            formatterNoSec.dateFormat = "yyyy-MM-dd HH:mm"
                            formatterNoSec.timeZone = jst
                            let parsed = formatterWithSec.date(from: combinedFull)
                                ?? formatterNoSec.date(from: "\(dateStr) \(timeStr.prefix(5))")
                            if let parsed = parsed {
                                req.dateTime = parsed
                            }
                        }
                        
                        // Map the raw database status to our UI enum
                        let rawStatus = row.status.lowercased()
                        var uiStatus: ReservationStatus = .pending
                        
                        if rawStatus == "completed" || rawStatus == "confirmed" {
                            uiStatus = .confirmed
                        } else if rawStatus == "action_required" {
                            uiStatus = .actionRequired
                        } else if rawStatus == "failed" {
                            uiStatus = .failed
                        } else if rawStatus == "incomplete" {
                            uiStatus = .incomplete
                        } else if rawStatus == "cancelled" {
                            uiStatus = .cancelled
                        }
                        
                        // Reconstruct the full data object for the details sheet
                        let fullData = ReservationData(
                            id: row.id,
                            status: row.status,
                            bookingConfirmed: nil,
                            failureReason: row.failureReason,
                            updatedAt: row.updatedAt,
                            audioUrl: row.audioUrl,
                            confirmationDetails: row.confirmationDetails
                        )
                        
                        // Determine the display message for the card
                        let summary = row.confirmationDetails?.summary ?? ""
                        let failureMsg = row.failureReason ?? ""
                        var displayMsg = ""
                        
                        switch uiStatus {
                        case .confirmed: displayMsg = summary.isEmpty ? "Reservation Confirmed!" : "Confirmed: \(summary)"
                        case .actionRequired: displayMsg = failureMsg.isEmpty ? "Action needed." : "⚠️ Action Required:\n\(failureMsg)"
                        case .failed: displayMsg = failureMsg.isEmpty ? "Rejected by restaurant." : "❌ Failed: \(failureMsg)"
                        case .incomplete: displayMsg = "⚠️ Call disconnected."
                        case .pending: displayMsg = "Processing..."
                        case .cancelled: displayMsg = "Cancelled"
                        }
                        
                        // Assemble the final item
                        let item = ReservationItem(
                            backendId: row.id,
                            request: req,
                            status: uiStatus,
                            resultMessage: displayMsg,
                            fullData: fullData
                        )
                        loadedItems.append(item)
                    }
                    
                    let finalItems = loadedItems
                    
                    // 4. Update the main Published array on the Main Thread
                    await MainActor.run {
                        self.reservations = finalItems
                        self.hasLoadedHistory = true
                    }
                    
                } catch {
                    print("❌ Failed to fetch user history: \(error.localizedDescription)")
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
            
            let summary = record.confirmationDetails?.summary ?? ""
                
            switch record.status {
            case "completed", "confirmed":
                let msg = summary.isEmpty ? "Reservation Confirmed!" : "Confirmed: \(summary)"
                updateTicket(id: uiItemId, status: .confirmed, message: msg, fullRecord: record)
                    
            case "action_required":
                let msg = failureReason.isEmpty ? "Action needed." : failureReason
                updateTicket(id: uiItemId, status: .actionRequired, message: "⚠️ Action Required:\n\(msg)", fullRecord: record)
                    
            case "failed":
                let msg = failureReason.isEmpty ? "Rejected by restaurant." : failureReason
                updateTicket(id: uiItemId, status: .failed, message: "❌ Failed: \(msg)", fullRecord: record)
                    
            case "incomplete":
                updateTicket(id: uiItemId, status: .incomplete, message: "⚠️ Call disconnected.", fullRecord: record)

            case "cancelled":
                updateTicket(id: uiItemId, status: .cancelled, message: "Cancelled", fullRecord: record)

            default:
                print("Received unknown status update: \(record.status)")
            }
        }
        
        func updateTicket(id: UUID, status: ReservationStatus, message: String, fullRecord: ReservationData? = nil) {
            if let index = reservations.firstIndex(where: { $0.id == id }) {
                DispatchQueue.main.async {
                    withAnimation {
                        self.reservations[index].status = status
                        self.reservations[index].resultMessage = message
                        if let record = fullRecord {
                            self.reservations[index].fullData = record
                        }
                    }
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
    
    /// Action Required, excluding past events (reservation time in Japan time before now).
    var actionRequiredItems: [ReservationItem] {
        let now = Date()
        return reservations.filter { item in
            guard item.status == .actionRequired else { return false }
            return item.request.dateTime > now
        }
    }

    /// Mark a reservation as cancelled (local update; optionally sync to backend later).
    func cancelReservation(uiItemId: UUID) {
        updateTicket(id: uiItemId, status: .cancelled, message: "Cancelled")
    }
        
    // Failed and Incomplete
    var failedOrIncompleteItems: [ReservationItem] {
        return reservations.filter { $0.status == .failed || $0.status == .incomplete }
    }
            
    /// Confirmed reservations whose date/time (in Japan time) is still in the future.
    var upcomingReservations: [ReservationItem] {
        let now = Date()
        return reservations.filter { item in
            guard item.status == .confirmed else { return false }
            return item.request.dateTime > now
        }
    }
}

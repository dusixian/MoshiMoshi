//
//  ActionResponseView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/02/20.
//

import SwiftUI

struct ActionResponseView: View {
    let item: ReservationItem
    @Environment(\.dismiss) var dismiss
    
    @State private var userResponse: String = ""
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.sushiRice.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    // 1. Restaurant Header Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.request.restaurantName)
                            .font(.title2.bold())
                            .foregroundColor(.sushiNori)
                        Text("Follow-up required to secure your booking")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // 2. Display the issue/reason from the Database
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Message from Restaurant", systemImage: "quote.opening")
                            .font(.headline)
                            .foregroundColor(.sushiTuna)
                        
                        // Prioritize the specific required action value, fall back to failure reason
                        let reason = item.fullData?.confirmationDetails?.results?.requiredAction?.value
                                     ?? item.fullData?.failureReason
                                     ?? "Additional information is required."
                        
                        Text(reason)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    }
                    
                    // 3. User Input Field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Response")
                            .font(.headline)
                            .foregroundColor(.sushiNori)
                        
                        TextField("e.g. 8:00 PM works for me", text: $userResponse, axis: .vertical)
                            .lineLimit(4...8)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    // 4. Submission Button
                    Button(action: {
                        sendCallback()
                    }) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send & Call Back")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userResponse.isEmpty ? Color.gray.opacity(0.5) : Color.sushiTuna)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .disabled(userResponse.isEmpty || isSubmitting)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    /// Sends the user response to the backend and triggers a follow-up call
    private func sendCallback() {
        guard let reservationId = item.backendId else {
            print("[ActionResponse] Missing reservation ID")
            isSubmitting = false
            return
        }

        isSubmitting = true

        Task {
            do {
                try await APIService.shared.retryReservation(
                    reservationId: reservationId,
                    userResponse: userResponse
                )

                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                print("[ActionResponse] Failed to send callback: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    // TODO: Show error alert to user
                }
            }
        }
    }
}

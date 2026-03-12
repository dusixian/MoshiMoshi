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
    @EnvironmentObject var viewModel: ReservationViewModel

    @State private var userResponse: String = ""
    @State private var isSubmitting: Bool = false

    // Editable reservation fields
    @State private var restaurantName: String = ""
    @State private var restaurantPhone: String = ""
    @State private var dateTime: Date = Date()
    @State private var partySize: Int = 2
    @State private var customerName: String = ""
    @State private var customerEmail: String = ""
    @State private var customerPhone: String = ""

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.sushiRice.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 1. Restaurant Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.request.restaurantName)
                                .font(.title2.bold())
                                .foregroundColor(.sushiNori)
                            Text("Follow-up required to secure your booking")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        // 2. Message from Restaurant
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Message from Restaurant", systemImage: "quote.opening")
                                .font(.headline)
                                .foregroundColor(.sushiTuna)

                            let latestConversation = item.conversations.first
                            let reason = latestConversation?.failureReason
                                         ?? item.fullData?.failureReason
                                         ?? "Additional information is required."

                            Text(reason)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        }

                        // 3. Your Response (pre-filled with special requests)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Response")
                                .font(.headline)
                                .foregroundColor(.sushiNori)

                            TextField("e.g. 8:00 PM works for me", text: $userResponse, axis: .vertical)
                                .lineLimit(4...8)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }

                        // 4. Editable Reservation Summary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RESTAURANT INFO")
                                .font(.caption.bold())
                                .foregroundColor(.gray)

                            editRow(icon: "fork.knife", placeholder: "Restaurant name", text: $restaurantName)
                            editRow(icon: "phone", placeholder: "Restaurant phone", text: $restaurantPhone)

                            Text("RESERVATION DETAILS")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.top, 4)

                            // Date picker row
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                DatePicker("", selection: $dateTime, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.cardBackground)
                            .cornerRadius(12)

                            // Party size row
                            HStack(spacing: 12) {
                                Image(systemName: "person.2")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                Text("Party Size")
                                    .foregroundColor(.sushiNori)
                                Spacer()
                                Text("\(partySize)")
                                    .foregroundColor(.sushiTuna)
                                    .fontWeight(.semibold)
                                Stepper("", value: $partySize, in: 1...20)
                                    .labelsHidden()
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .cornerRadius(12)

                            Text("YOUR CONTACT")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.top, 4)

                            editRow(icon: "person", placeholder: "Your name", text: $customerName)
                            editRow(icon: "envelope", placeholder: "Email", text: $customerEmail)
                                .keyboardType(.emailAddress)
                            editRow(icon: "phone", placeholder: "Phone number", text: $customerPhone)
                                .keyboardType(.phonePad)
                        }

                        Color.clear.frame(height: 72)
                    }
                    .padding()
                }

                // 5. Sticky Send Button
                Button(action: { sendCallback() }) {
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
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
            .onAppear {
                userResponse      = item.request.specialRequests
                restaurantName    = item.request.restaurantName
                restaurantPhone   = item.request.restaurantPhone
                dateTime          = item.request.dateTime
                partySize         = item.request.partySize
                customerName      = item.request.customerName
                customerEmail     = item.request.customerEmail
                customerPhone     = item.request.customerPhone
            }
        }
    }

    @ViewBuilder
    private func editRow(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            TextField(placeholder, text: text)
                .foregroundColor(.sushiNori)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    /// Sends the user response to the backend and triggers a follow-up call
    private func sendCallback() {
        guard let reservationId = item.backendId else { return }
        isSubmitting = true

        Task {
            do {
                try await APIService.shared.retryReservation(
                    reservationId: reservationId,
                    userResponse: userResponse
                )

                await MainActor.run {
                    viewModel.updateTicket(id: item.id, status: .pending, message: "AI is calling back...")
                    isSubmitting = false
                    dismiss()
                }

                await viewModel.startRealtimeListener(backendId: reservationId, uiItemId: item.id)

            } catch {
                print("[ActionResponse] Failed to send callback: \(error)")
                await MainActor.run { isSubmitting = false }
            }
        }
    }
}

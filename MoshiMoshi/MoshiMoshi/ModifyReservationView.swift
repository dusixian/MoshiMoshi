//
//  ModifyReservationView.swift
//  MoshiMoshi
//

import SwiftUI

struct ModifyReservationView: View {
    let item: ReservationItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ReservationViewModel

    @State private var isSubmitting = false

    // Editable fields
    @State private var restaurantName: String = ""
    @State private var restaurantPhone: String = ""
    @State private var dateTime: Date = Date()
    @State private var partySize: Int = 2
    @State private var customerName: String = ""
    @State private var customerEmail: String = ""
    @State private var customerPhone: String = ""
    @State private var specialRequests: String = ""

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.sushiRice.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.request.restaurantName)
                                .font(.title2.bold())
                                .foregroundColor(.sushiNori)
                            Text("Modify your previous booking information")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        // RESTAURANT INFO
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RESTAURANT INFO")
                                .font(.caption.bold())
                                .foregroundColor(.gray)

                            editRow(icon: "fork.knife", placeholder: "Restaurant name", text: $restaurantName)
                            editRow(icon: "phone", placeholder: "Restaurant phone", text: $restaurantPhone)
                                .keyboardType(.phonePad)
                        }

                        // RESERVATION DETAILS
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RESERVATION DETAILS")
                                .font(.caption.bold())
                                .foregroundColor(.gray)

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
                        }

                        // YOUR CONTACT
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YOUR CONTACT")
                                .font(.caption.bold())
                                .foregroundColor(.gray)

                            editRow(icon: "person", placeholder: "Your name", text: $customerName)
                            editRow(icon: "envelope", placeholder: "Email", text: $customerEmail)
                                .keyboardType(.emailAddress)
                            editRow(icon: "phone", placeholder: "Phone number", text: $customerPhone)
                                .keyboardType(.phonePad)
                        }

                        // SPECIAL REQUESTS
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SPECIAL REQUESTS")
                                .font(.caption.bold())
                                .foregroundColor(.gray)

                            TextField("Any allergies or special requests...", text: $specialRequests, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }

                        Color.clear.frame(height: 72)
                    }
                    .padding()
                }

                // Sticky button
                Button(action: { submitModification() }) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Call & Modify")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.sushiTuna)
                .foregroundColor(.white)
                .cornerRadius(16)
                .contentShape(Rectangle())
                .disabled(isSubmitting)
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
                restaurantName  = item.request.restaurantName
                restaurantPhone = item.request.restaurantPhone
                dateTime        = item.request.dateTime
                partySize       = item.request.partySize
                customerName    = item.request.customerName
                customerEmail   = item.request.customerEmail
                customerPhone   = item.request.customerPhone
                specialRequests = item.request.specialRequests
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

    private struct ModificationPayload: Encodable {
        let restaurantName: String
        let restaurantPhone: String
        let reservationDate: String
        let reservationTime: String
        let partySize: Int
        let customerName: String
        let customerEmail: String
        let customerPhone: String
        let specialRequests: String

        enum CodingKeys: String, CodingKey {
            case restaurantName   = "restaurant_name"
            case restaurantPhone  = "restaurant_phone"
            case reservationDate  = "reservation_date"
            case reservationTime  = "reservation_time"
            case partySize        = "party_size"
            case customerName     = "customer_name"
            case customerEmail    = "customer_email"
            case customerPhone    = "customer_phone"
            case specialRequests  = "special_requests"
        }
    }

    private func submitModification() {
        guard let reservationId = item.backendId else { return }
        isSubmitting = true

        Task {
            do {
                // 1. Format date/time strings
                let dateFmt = DateFormatter()
                dateFmt.dateFormat = "yyyy-MM-dd"
                let timeFmt = DateFormatter()
                timeFmt.dateFormat = "HH:mm"
                let dateStr = dateFmt.string(from: dateTime)
                let timeStr = timeFmt.string(from: dateTime)

                // 2. Update reservation fields
                let payload = ModificationPayload(
                    restaurantName:  restaurantName,
                    restaurantPhone: restaurantPhone,
                    reservationDate: dateStr,
                    reservationTime: timeStr,
                    partySize:       partySize,
                    customerName:    customerName,
                    customerEmail:   customerEmail,
                    customerPhone:   customerPhone,
                    specialRequests: specialRequests
                )
                try await APIService.shared.supabase
                    .from("reservations")
                    .update(payload)
                    .eq("id", value: reservationId)
                    .execute()

                // 3. Set modify_tag on latest conversation so retry route knows this is a modification
                try await APIService.shared.supabase
                    .from("conversations")
                    .update(["modify_tag": "[User Modification Requested]"])
                    .eq("reservation_id", value: reservationId)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()

                // 4. Call retry with modification context
                let userResponse = "User modification request. Updated details — Date: \(dateStr), Time: \(timeStr), Party: \(partySize), Special requests: \(specialRequests.isEmpty ? "None" : specialRequests)"
                try await APIService.shared.retryReservation(
                    reservationId: reservationId,
                    userResponse: userResponse
                )

                await MainActor.run {
                    viewModel.updateTicket(id: item.id, status: .pending, message: "AI is calling back with updated details...")
                    isSubmitting = false
                    dismiss()
                }

                await viewModel.startRealtimeListener(backendId: reservationId, uiItemId: item.id)

            } catch {
                print("[Modify] Failed: \(error)")
                await MainActor.run { isSubmitting = false }
            }
        }
    }
}

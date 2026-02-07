//
//  ReservationFormView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/22.
//

import SwiftUI


struct ReservationFormView: View {
    @ObservedObject var viewModel: ReservationViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.sushiRice.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // --- The Form Section ---
                    VStack(alignment: .leading, spacing: 24) {
                        // Section 1: Restaurant
                        VStack(alignment: .leading) {
                            Text("RESTAURANT INFO").modifier(OmakaseHeader())
                            OmakaseTextField(icon: "fork.knife", placeholder: "Restaurant Name", text: $viewModel.request.restaurantName)
                            OmakaseTextField(icon: "phone", placeholder: "Restaurant Phone", text: $viewModel.request.restaurantPhone)
                                .keyboardType(.phonePad)
                        }

                        // Section 2: Details
                        VStack(alignment: .leading) {
                            Text("RESERVATION DETAILS").modifier(OmakaseHeader())
                            HStack {
                                Image(systemName: "calendar").foregroundColor(.sushiNori)
                                DatePicker("", selection: $viewModel.request.dateTime, displayedComponents: [.date, .hourAndMinute]).labelsHidden()
                            }
                            .padding().background(Color.white).cornerRadius(12)

                            HStack {
                                Image(systemName: "person.2").foregroundColor(.sushiNori)
                                Text("Party Size").foregroundColor(.sushiNori)
                                Spacer()
                                Text("\(viewModel.request.partySize)").fontWeight(.bold).foregroundColor(.sushiSalmon)
                                Stepper("", value: $viewModel.request.partySize, in: 1...20).labelsHidden()
                            }
                            .padding().background(Color.white).cornerRadius(12)
                        }

                        // Section 3: User Info
                        VStack(alignment: .leading) {
                            Text("YOUR CONTACT").modifier(OmakaseHeader())
                            OmakaseTextField(icon: "person", placeholder: "Your Name", text: $viewModel.request.customerName)
                            OmakaseTextField(icon: "iphone", placeholder: "Your Phone", text: $viewModel.request.customerPhone)
                                .keyboardType(.phonePad)
                        }

                        // Section 4: Notes
                        VStack(alignment: .leading) {
                            Text("SPECIAL REQUESTS").modifier(OmakaseHeader())

                            TextField("Any allergies or special requests...", text: $viewModel.request.specialRequests, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .foregroundColor(.sushiNori)
                        }
                    }
                    .padding(.horizontal)

                    // --- START CALL BUTTON ---
                    Button(action: {
                        viewModel.startAICall()
                        dismiss()
                    }) {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "phone.arrow.up.right.fill")
                                Text("Start AI Call").fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.isValid ? Color.sushiSalmon : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(28)
                        .shadow(color: viewModel.isValid ? Color.sushiSalmon.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 10)
                    }
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("New Reservation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.sushiSalmon)
            }
        }
    }
}


// Helper View: Custom Styled Text Field
struct OmakaseTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.sushiNori.opacity(0.6))
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .foregroundColor(.sushiNori)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}


extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


#Preview {
    ReservationFormView(viewModel: ReservationViewModel())
}

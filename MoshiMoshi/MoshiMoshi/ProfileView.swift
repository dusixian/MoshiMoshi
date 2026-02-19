//
//  ProfileView.swift
//  MoshiMoshi
//
//  Personal information: name, email, phone (with country code). Saved to Supabase profiles.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var profileService = ProfileService()

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phoneCountryCode: String = "+1"
    @State private var phoneNational: String = ""

    @State private var isLoading = false
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        ZStack {
            Color.sushiRice.ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEFAULT CONTACT INFO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.top, 20)

                    OmakaseTextField(icon: "person.fill", placeholder: "Your Default Name", text: $fullName)
                    OmakaseTextField(icon: "envelope.fill", placeholder: "Your Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    // Phone: country code + number (both user-entered)
                    HStack(spacing: 12) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.sushiNori.opacity(0.6))
                            .frame(width: 24)
                        TextField("+1", text: $phoneCountryCode)
                            .keyboardType(.phonePad)
                            .foregroundColor(.sushiNori)
                            .frame(width: 56)
                        TextField("Phone number", text: $phoneNational)
                            .keyboardType(.phonePad)
                            .foregroundColor(.sushiNori)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                if let err = saveError {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.sushiTuna)
                }

                Button(action: saveProfile) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.sushiSalmon)
                    .cornerRadius(12)
                }
                .disabled(isSaving)
                .padding(.horizontal)

                Text("This information will be automatically filled in when you make a new reservation request.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadProfile() }
    }

    private func loadProfile() async {
        isLoading = true
        saveError = nil
        defer { isLoading = false }
        do {
            if let profile = try await profileService.fetchProfile() {
                fullName = profile.fullName ?? ""
                email = profile.email ?? ""
                let parsed = PhoneCountryCode.parse(full: profile.phone ?? "")
                phoneCountryCode = parsed.code
                phoneNational = parsed.national
            } else {
                fullName = UserDefaults.standard.string(forKey: "savedUserName") ?? ""
                email = UserDefaults.standard.string(forKey: "savedUserEmail") ?? ""
                let savedPhone = UserDefaults.standard.string(forKey: "savedUserPhone") ?? ""
                let parsed = PhoneCountryCode.parse(full: savedPhone)
                phoneCountryCode = parsed.code
                phoneNational = parsed.national
            }
        } catch {
            fullName = UserDefaults.standard.string(forKey: "savedUserName") ?? ""
            email = UserDefaults.standard.string(forKey: "savedUserEmail") ?? ""
            let savedPhone = UserDefaults.standard.string(forKey: "savedUserPhone") ?? ""
            let parsed = PhoneCountryCode.parse(full: savedPhone)
            phoneCountryCode = parsed.code
            phoneNational = parsed.national
        }
    }

    private func saveProfile() {
        saveError = nil
        isSaving = true
        let fullPhone = PhoneCountryCode.fullPhone(countryCode: phoneCountryCode, national: phoneNational)
        Task {
            do {
                try await profileService.upsertProfile(
                    fullName: fullName.isEmpty ? nil : fullName,
                    email: email.isEmpty ? nil : email,
                    phone: fullPhone.isEmpty ? nil : fullPhone
                )
                syncToUserDefaults()
                await MainActor.run { isSaving = false }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                }
            }
        }
    }

    private func syncToUserDefaults() {
        UserDefaults.standard.set(fullName, forKey: "savedUserName")
        UserDefaults.standard.set(email, forKey: "savedUserEmail")
        let fullPhone = PhoneCountryCode.fullPhone(countryCode: phoneCountryCode, national: phoneNational)
        UserDefaults.standard.set(fullPhone, forKey: "savedUserPhone")
    }
}

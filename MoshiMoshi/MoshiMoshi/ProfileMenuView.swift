//
//  ProfileMenuView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/2/5.
//

import SwiftUI

struct ProfileMenuView: View {
    @AppStorage("savedUserName") var savedUserName: String = ""
    @AppStorage("savedUserPhone") var savedUserPhone: String = ""
    @AppStorage("savedUserEmail") var savedUserEmail: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.sushiRice.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        HStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(Color.sushiSalmon.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Text(getInitials())
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.sushiSalmon)
                            }

                            // User Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(savedUserName.isEmpty ? "User Name" : savedUserName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.sushiNori)
                                
                                if !savedUserEmail.isEmpty {
                                    Text(savedUserEmail)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .underline()
                                }

                                if !savedUserPhone.isEmpty {
                                    Text(savedUserPhone)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                        // --- Account Section ---
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Account")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                NavigationLink(destination: ProfileView()) {
                                    MenuRowContent(icon: "person.circle", title: "Personal Information")
                                }

                                Divider().padding(.leading, 60)

                                MenuRow(icon: "creditcard", title: "Payment Methods", subtitle: "Visa .... 4242", action: {})

                                Divider().padding(.leading, 60)

                                MenuRow(icon: "bell", title: "Notifications", subtitle: "Enabled", action: {})
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // --- Preferences Section ---
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Preferences")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                MenuRow(icon: "globe", title: "Language", subtitle: "English", action: {})

                                Divider().padding(.leading, 60)

                                MenuRow(icon: "mappin.circle", title: "Default Region", subtitle: "Tokyo, Japan", action: {})

                                Divider().padding(.leading, 60)

                                MenuRow(icon: "lock.shield", title: "Privacy & Security", action: {})
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // --- Support Section ---
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Support")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                MenuRow(icon: "questionmark.circle", title: "Help Center", action: {})

                                Divider().padding(.leading, 60)

                                MenuRow(icon: "gearshape", title: "App Settings", action: {})
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // --- Sign Out Button ---
                        Button(action: {
                            // Sign out logic
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 16))
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .accentColor(.sushiSalmon)
    }

    func getInitials() -> String {
        if savedUserName.isEmpty {
            return "U"
        }
        let names = savedUserName.split(separator: " ")
        if names.count >= 2 {
            let first = String(names[0].prefix(1))
            let last = String(names[1].prefix(1))
            return (first + last).uppercased()
        } else {
            return String(savedUserName.prefix(2)).uppercased()
        }
    }
}


struct MenuRowContent: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.sushiRice)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.sushiNori)
            }

            // Title
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.sushiNori)

            Spacer()

            // Subtitle (if any)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}


struct MenuRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MenuRowContent(icon: icon, title: title, subtitle: subtitle)
        }
    }
}

#Preview {
    ProfileMenuView()
}

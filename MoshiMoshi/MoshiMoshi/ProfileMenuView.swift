//
//  ProfileMenuView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/2/5.
//

import SwiftUI
import UserNotifications

struct ProfileMenuView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var profileService = ProfileService()
    @ObservedObject private var lm = LocalizationManager.shared
    @State private var displayName: String = ""
    @State private var displayEmail: String = ""
    @State private var displayPhone: String = ""
    @State private var displayRegion: String = "Tokyo"
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @State private var showSettingsAlert = false

    private var languageLabel: String {
        switch lm.language {
        case "ja": return "日本語"
        case "zh-Hans": return "中文"
        default: return "English"
        }
    }

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

                            // User Info (from DB)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayName.isEmpty ? L("User Name") : displayName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.sushiNori)

                                if !displayEmail.isEmpty {
                                    Text(displayEmail)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .underline()
                                }

                                if !displayPhone.isEmpty {
                                    Text(displayPhone)
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
                            Text(L("Account"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                NavigationLink(destination: ProfileView(onSave: { Task { await loadProfileFromDB() } })) {
                                    MenuRowContent(icon: "person.circle", title: L("Personal Information"))
                                }

                                Divider().padding(.leading, 60)

                                MenuRow(icon: "creditcard", title: L("Payment Methods"), subtitle: "Visa .... 4242", action: {})

                                Divider().padding(.leading, 60)

                                Toggle(isOn: $notificationsEnabled) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.sushiRice)
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "bell")
                                                .font(.system(size: 18))
                                                .foregroundColor(.sushiNori)
                                        }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(L("Notifications"))
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.sushiNori)
                                                Text(notificationsEnabled ? L("Enabled") : L("Disabled"))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .tint(.sushiSalmon)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .onChange(of: notificationsEnabled) { newValue in
                                    if newValue {
                                        checkAndRequestNotificationPermission()
                                    }
                                }
                            }
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // --- Preferences Section ---
                        VStack(alignment: .leading, spacing: 0) {
                            Text(L("Preferences"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                NavigationLink(destination: LanguagePickerView()) {
                                    MenuRowContent(icon: "globe", title: L("Language"), subtitle: languageLabel)
                                }

                                Divider().padding(.leading, 60)

                                NavigationLink(destination: RegionPickerView(onSaved: { region in
                                    displayRegion = region
                                })) {
                                    MenuRowContent(icon: "mappin.circle", title: L("Default Region"), subtitle: displayRegion)
                                }

                                Divider().padding(.leading, 60)

                                MenuRow(icon: "lock.shield", title: L("Privacy & Security"), action: {})
                            }
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // --- Support Section ---
                        VStack(alignment: .leading, spacing: 0) {
                            Text(L("Support"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                MenuRow(icon: "questionmark.circle", title: L("Help Center"), action: {})

                                Divider().padding(.leading, 60)

                                NavigationLink(destination: AppSettingsView()) {
                                    MenuRowContent(icon: "gearshape", title: L("App Settings"))
                                }
                            }
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // --- Sign Out Button ---
                        Button(action: {
                            auth.signOut()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 16))
                                Text(L("Sign Out"))
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
            .navigationTitle(L("Profile"))
            .navigationBarTitleDisplayMode(.large)
            .alert(isPresented: $showSettingsAlert) {
                Alert(
                    title: Text(L("Permission Denied")),
                    message: Text(L("Please enable notifications for MoshiMoshi in your iPhone Settings to receive reservation updates.")),
                    primaryButton: .default(Text(L("Go to Settings")), action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }),
                    secondaryButton: .cancel(Text(L("Cancel")))
                )
            }
        }
        .accentColor(.sushiSalmon)
        .onAppear { Task { await loadProfileFromDB() } }
    }

    private func loadProfileFromDB() async {
        do {
            if let profile = try await profileService.fetchProfile() {
                await MainActor.run {
                    displayName = profile.fullName ?? ""
                    displayEmail = profile.email ?? ""
                    displayPhone = profile.phone ?? ""
                    displayRegion = profile.defaultRegion ?? "Tokyo"
                }
            } else {
                await MainActor.run {
                    displayName = UserDefaults.standard.string(forKey: "savedUserName") ?? ""
                    displayEmail = UserDefaults.standard.string(forKey: "savedUserEmail") ?? ""
                    displayPhone = UserDefaults.standard.string(forKey: "savedUserPhone") ?? ""
                }
            }
        } catch {
            await MainActor.run {
                displayName = UserDefaults.standard.string(forKey: "savedUserName") ?? ""
                displayEmail = UserDefaults.standard.string(forKey: "savedUserEmail") ?? ""
                displayPhone = UserDefaults.standard.string(forKey: "savedUserPhone") ?? ""
            }
        }
    }

    func getInitials() -> String {
        if displayName.isEmpty {
            return "U"
        }
        let names = displayName.split(separator: " ")
        if names.count >= 2 {
            let first = String(names[0].prefix(1))
            let last = String(names[1].prefix(1))
            return (first + last).uppercased()
        } else {
            return String(displayName.prefix(2)).uppercased()
        }
    }
    private func checkAndRequestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    self.notificationsEnabled = false
                    self.showSettingsAlert = true
                } else if settings.authorizationStatus == .notDetermined {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        DispatchQueue.main.async {
                            self.notificationsEnabled = granted
                        }
                    }
                }
            }
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

// MARK: - App Settings View
struct AppSettingsView: View {
    @AppStorage("appColorScheme") private var appColorScheme: String = "system"
    @ObservedObject private var lm = LocalizationManager.shared

    private var options: [(label: String, icon: String, value: String)] {[
        (L("System Default"), "circle.lefthalf.filled", "system"),
        (L("Light Mode"),     "sun.max.fill",            "light"),
        (L("Dark Mode"),      "moon.fill",               "dark"),
    ]}

    var body: some View {
        ZStack {
            Color.sushiRice.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 0) {
                    ForEach(options, id: \.value) { option in
                        Button(action: { appColorScheme = option.value }) {
                            HStack(spacing: 16) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.sushiSalmon)
                                    .frame(width: 28)
                                Text(option.label)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                Spacer()
                                if appColorScheme == option.value {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.sushiSalmon)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                        if option.value != "dark" {
                            Divider().padding(.leading, 64)
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()
            }
        }
        .navigationTitle(L("App Settings"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Language Picker View
struct LanguagePickerView: View {
    @ObservedObject private var lm = LocalizationManager.shared

    private let options: [(label: String, native: String, value: String)] = [
        ("English",  "English", "en"),
        ("Japanese", "日本語",   "ja"),
        ("Chinese",  "中文简体", "zh-Hans"),
    ]

    var body: some View {
        ZStack {
            Color.sushiRice.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 0) {
                    ForEach(options, id: \.value) { option in
                        Button(action: { lm.language = option.value }) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.native)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text(option.label)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if lm.language == option.value {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.sushiSalmon)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                        if option.value != "zh-Hans" {
                            Divider().padding(.leading, 20)
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()
            }
        }
        .navigationTitle(L("Language"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileMenuView()
        .environmentObject(AuthManager())
}

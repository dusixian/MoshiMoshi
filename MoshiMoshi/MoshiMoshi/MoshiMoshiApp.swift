//
//  MoshiMoshiApp.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/22.
//

import SwiftUI

@main
struct MoshiMoshiApp: App {
    @StateObject private var auth = AuthManager()
    @AppStorage("appColorScheme") private var appColorScheme: String = "system"
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    private var appLocale: Locale { Locale(identifier: appLanguage) }

    private var preferredColorScheme: ColorScheme? {
        switch appColorScheme {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if auth.isLoggedIn {
                ContentView()
                    .environmentObject(auth)
                    .preferredColorScheme(preferredColorScheme)
                    .environment(\.locale, appLocale)
            } else {
                LoginView()
                    .environmentObject(auth)
                    .preferredColorScheme(preferredColorScheme)
                    .environment(\.locale, appLocale)
            }
        }
    }
}

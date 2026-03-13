//
//  MoshiMoshiApp.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/22.
//

import SwiftUI
import UserNotifications

// AppDelegate to handle notification presentation
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set notification delegate to show notifications even when app is in foreground
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct MoshiMoshiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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

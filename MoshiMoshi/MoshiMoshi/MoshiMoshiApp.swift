//
//  MoshiMoshiApp.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/22.
//

import SwiftUI
import UserNotifications
import AVFoundation

// AppDelegate to handle notification presentation and background execution
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set notification delegate to show notifications even when app is in foreground
        UNUserNotificationCenter.current().delegate = self
        
        // Configure AVAudioSession to deceive iOS into keeping the app alive in the background
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 AVAudioSession configured for background execution")
        } catch {
            print("❌ Failed to set audio session category: \(error.localizedDescription)")
        }
        
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

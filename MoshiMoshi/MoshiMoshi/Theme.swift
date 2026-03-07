//
//  Theme.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/23.
//

import SwiftUI

// Extension to define the custom color palette
extension Color {
    // App background — beige in light, near-black in dark
    static let sushiRice = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
            : UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1)
    })

    // Card / surface background — white in light, dark gray in dark
    static let cardBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor.white
    })

    // Primary text / icon — dark green in light, soft white in dark
    static let sushiNori = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.88, green: 0.92, blue: 0.89, alpha: 1)
            : UIColor(red: 0.20, green: 0.28, blue: 0.25, alpha: 1)
    })

    // These accent colors stay the same in both modes
    static let sushiSalmon = Color(red: 1.00, green: 0.45, blue: 0.35) // Primary Action
    static let sushiWasabi = Color(red: 0.78, green: 0.85, blue: 0.55) // Success / Green
    static let sushiTuna   = Color(red: 0.80, green: 0.20, blue: 0.20) // Error / Alert
}

// Custom modifier for section headers
struct OmakaseHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.headline, design: .serif))
            .foregroundColor(.sushiNori.opacity(0.6))
            .padding(.leading, 4)
            .padding(.bottom, 4)
    }
}

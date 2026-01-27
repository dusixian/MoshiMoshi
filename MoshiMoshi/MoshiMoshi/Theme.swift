//
//  Theme.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/23.
//

import SwiftUI

// Extension to define the custom color palette
extension Color {
    static let sushiRice = Color(red: 0.98, green: 0.96, blue: 0.93) // Background Beige
    static let sushiSalmon = Color(red: 1.00, green: 0.45, blue: 0.35) // Primary Action (Salmon)
    static let sushiNori = Color(red: 0.20, green: 0.28, blue: 0.25)   // Text (Dark Green/Black)
    static let sushiWasabi = Color(red: 0.78, green: 0.85, blue: 0.55) // Accents (Light Green)
    static let sushiTuna = Color(red: 0.80, green: 0.20, blue: 0.20)   // Error or Alert
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

//
//  ContentView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/22.
//

import SwiftUI


struct ContentView: View {
    @StateObject var viewModel = ReservationViewModel()
    @State private var selectedTab = 0

    init() {
        // Customize TabBar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.98, alpha: 1.0) // Light background

        // Add subtle shadow for separation
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)

        // Adjust positioning for better vertical centering
        let itemAppearance = UITabBarItemAppearance()

        // Configure for stacked layout (icon above text)
        itemAppearance.normal.iconColor = UIColor.gray
        itemAppearance.selected.iconColor = UIColor(Color.sushiSalmon)

        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray,
            .font: UIFont.systemFont(ofSize: 10)
        ]
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.sushiSalmon),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        // Adjust vertical positioning to move content down
        itemAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 6)
        itemAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 6)

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            DiscoverView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("Discover")
                }
                .tag(1)

            HistoryView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(2)

            ProfileMenuView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.sushiSalmon)
    }
}


#Preview {
    ContentView()
}

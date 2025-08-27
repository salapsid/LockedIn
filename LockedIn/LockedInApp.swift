//
//  LockedInApp.swift
//  LockedIn
//
//  Created by Siddharth Salapaka on 8/23/25.
//

import SwiftUI

@main
struct LockedInApp: App {
    @StateObject private var profilesVM = ProfilesViewModel()
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(viewModel: profilesVM)
                    .tabItem {
                        Label("Lock In", systemImage: "lock.fill")
                    }
                ProfilesView(viewModel: profilesVM)
                    .tabItem {
                        Label("Profiles", systemImage: "person.3.fill")
                    }
            }
            .tint(AppTheme.accentSecondary)
        }
    }
}

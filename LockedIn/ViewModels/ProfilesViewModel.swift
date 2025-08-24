//
//  ProfilesViewModel.swift
//  LockedIn
//
//  Created by Assistant on 8/23/25.
//

import SwiftUI
import FamilyControls

@available(iOS 16.0, *)
@MainActor
final class ProfilesViewModel: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var isPresentingAddSheet: Bool = false

    @Published var newProfileName: String = ""
    @Published var newSelection: FamilyActivitySelection = FamilyActivitySelection()

    // Currently locked profile identifier (if any)
    @Published var lockedProfileId: UUID? = nil

    func requestAuthorizationIfNeeded() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("Authorization failed: \(error)")
        }
    }

    func beginAdd() {
        newProfileName = ""
        newSelection = FamilyActivitySelection()
        isPresentingAddSheet = true
    }

    func saveNewProfile() {
        let profile = Profile(name: newProfileName.isEmpty ? "New Profile" : newProfileName, selection: newSelection)
        profiles.append(profile)
        isPresentingAddSheet = false
        // NFC write is now initiated manually per profile via a button in the list
    }

    func deleteProfiles(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
    }

    // MARK: - Locking Helpers

    func lock(to profileId: UUID) {
        lockedProfileId = profileId
    }

    func unlock() {
        lockedProfileId = nil
    }
}



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
    @Published var isPresentingEditSheet: Bool = false

    @Published var newProfileName: String = ""
    @Published var newSelection: FamilyActivitySelection = FamilyActivitySelection()

    @Published var editProfileId: UUID? = nil
    @Published var editProfileName: String = ""
    @Published var editSelection: FamilyActivitySelection = FamilyActivitySelection()

    // Currently locked profile identifier (if any)
    @Published var lockedProfileId: UUID? = nil

    // Emergency unlocks remaining for this device (user-level). Defaults to 3.
    @Published var emergencyUnlocksRemaining: Int = 3

    // MARK: - Init

    init() {
        loadProfiles()
        loadLockedState()
        loadEmergencyUnlocks()
    }

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
        saveProfiles()
    }

    // MARK: - Edit

    func beginEdit(profile: Profile) {
        // Prevent editing the profile currently in use
        if let lockedId = lockedProfileId, lockedId == profile.id {
            return
        }
        editProfileId = profile.id
        editProfileName = profile.name
        editSelection = profile.selection
        isPresentingEditSheet = true
    }

    func saveEditedProfile() {
        guard let editId = editProfileId, let index = profiles.firstIndex(where: { $0.id == editId }) else {
            isPresentingEditSheet = false
            return
        }
        // Prevent saving edits to the profile currently in use
        if let lockedId = lockedProfileId, lockedId == editId {
            isPresentingEditSheet = false
            return
        }
        profiles[index].name = editProfileName
        profiles[index].selection = editSelection
        isPresentingEditSheet = false
        saveProfiles()
    }

    func deleteProfiles(at offsets: IndexSet) {
        // Prevent deleting the profile currently in use
        let safeOffsets = IndexSet(offsets.filter { index in
            guard profiles.indices.contains(index) else { return false }
            let id = profiles[index].id
            return lockedProfileId != id
        })
        guard safeOffsets.isEmpty == false else { return }
        profiles.remove(atOffsets: safeOffsets)
        saveProfiles()
        // If the currently locked profile was deleted, clear the locked state
        if let lockedId = lockedProfileId, profiles.contains(where: { $0.id == lockedId }) == false {
            lockedProfileId = nil
            saveLockedState()
        }
    }

    func deleteProfile(id: UUID) {
        // Prevent deleting the profile currently in use
        if let lockedId = lockedProfileId, lockedId == id {
            isPresentingEditSheet = false
            return
        }
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            profiles.remove(at: index)
            saveProfiles()
            if lockedProfileId == id {
                lockedProfileId = nil
                saveLockedState()
            }
        }
        isPresentingEditSheet = false
    }

    // MARK: - Locking Helpers

    func lock(to profileId: UUID) {
        lockedProfileId = profileId
        saveLockedState()
    }

    func unlock() {
        lockedProfileId = nil
        saveLockedState()
    }

    // MARK: - Persistence

    private var profilesFileURL: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("profiles.json")
    }

    private func loadProfiles() {
        let url = profilesFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Profile].self, from: data)
            profiles = decoded
        } catch {
            print("Failed to load profiles: \(error)")
        }
    }

    private func saveProfiles() {
        let url = profilesFileURL
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Failed to save profiles: \(error)")
        }
    }

    // Persist the locked profile ID so UI reflects the correct state after relaunch
    private let lockedStateKey = "lockedProfileId"
    private let emergencyUnlocksKey = "emergencyUnlocksRemaining"

    private func loadLockedState() {
        if let idString = UserDefaults.standard.string(forKey: lockedStateKey),
           let id = UUID(uuidString: idString) {
            // Only restore if this profile still exists
            if profiles.contains(where: { $0.id == id }) {
                lockedProfileId = id
            } else {
                UserDefaults.standard.removeObject(forKey: lockedStateKey)
            }
        }
    }

    private func saveLockedState() {
        if let id = lockedProfileId {
            UserDefaults.standard.set(id.uuidString, forKey: lockedStateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lockedStateKey)
        }
    }

    private func loadEmergencyUnlocks() {
        let stored = UserDefaults.standard.object(forKey: emergencyUnlocksKey) as? Int
        if let value = stored {
            emergencyUnlocksRemaining = max(0, value)
        } else {
            emergencyUnlocksRemaining = 3
            UserDefaults.standard.set(3, forKey: emergencyUnlocksKey)
        }
    }

    private func saveEmergencyUnlocks() {
        UserDefaults.standard.set(emergencyUnlocksRemaining, forKey: emergencyUnlocksKey)
    }

    // MARK: - Emergency Unlocks

    /// Consumes one emergency unlock to immediately clear restrictions and unlock.
    /// Returns true if an unlock was performed; false if not eligible (e.g., none remaining or not locked).
    func consumeEmergencyUnlock() -> Bool {
        guard emergencyUnlocksRemaining > 0 else { return false }
        guard lockedProfileId != nil else { return false }
        RestrictionsManager.shared.clear()
        unlock()
        emergencyUnlocksRemaining = max(0, emergencyUnlocksRemaining - 1)
        saveEmergencyUnlocks()
        return true
    }
}



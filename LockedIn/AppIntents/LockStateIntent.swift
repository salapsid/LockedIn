//
//  LockStateIntent.swift
//  LockedIn
//
//  Created by Assistant on 8/27/25.
//

import Foundation
import AppIntents

@available(iOS 16.0, *)
struct IsLockModeOnIntent: AppIntent {
    static var title: LocalizedStringResource = "Is Lock Mode On?"
    static var description = IntentDescription("Returns whether LockedIn's Lock Mode is currently active.")

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let isLocked = UserDefaults.standard.string(forKey: "lockedProfileId") != nil
        return .result(value: isLocked)
    }
}

@available(iOS 16.0, *)
struct LockedInShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .purple

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: IsLockModeOnIntent(),
            phrases: [
                "Is Lock Mode on in ${applicationName}",
                "Is ${applicationName} protection on",
                "Is Lock Mode on with ${applicationName}"
            ],
            shortTitle: "Is Lock Mode On",
            systemImageName: "lock.fill"
        )
    }
}



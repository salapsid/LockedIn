//
//  RestrictionsManager.swift
//  LockedIn
//
//  Created by Assistant on 8/24/25.
//

import Foundation
import ManagedSettings
import FamilyControls

@available(iOS 16.0, *)
final class RestrictionsManager {
    static let shared = RestrictionsManager()

    private let store = ManagedSettingsStore()

    func apply(selection: FamilyActivitySelection) {
        // Block selected apps and web domains from the selection
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.application.denyAppRemoval = true
    }

    func clear() {
        store.shield.applications = nil
        store.shield.webDomains = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
        store.application.denyAppRemoval = false
    }
}



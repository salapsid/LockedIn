//
//  Profile.swift
//  LockedIn
//
//  Created by Assistant on 8/23/25.
//

import Foundation
import FamilyControls

@available(iOS 16.0, *)
struct Profile: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var selection: FamilyActivitySelection

    init(id: UUID = UUID(), name: String, selection: FamilyActivitySelection) {
        self.id = id
        self.name = name
        self.selection = selection
    }
}



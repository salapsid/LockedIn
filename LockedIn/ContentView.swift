//
//  ContentView.swift
//  LockedIn
//
//  Created by Siddharth Salapaka on 8/23/25.
//

import SwiftUI
import FamilyControls

struct ContentView: View {
    @ObservedObject var viewModel: ProfilesViewModel
    @State private var alertMessage: String?

    var body: some View {
        ZStack {
            Button(action: handleLockInTapped) {
                Circle()
                    .fill(viewModel.lockedProfileId == nil ? Color.accentColor : Color.red)
                    .frame(width: 220, height: 220)
                    .overlay(
                        Text(viewModel.lockedProfileId == nil ? "Lock In" : "Unlock")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            .contentShape(Circle())
            .shadow(radius: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            await viewModel.requestAuthorizationIfNeeded()
        }
        .alert(item: Binding(get: {
            alertMessage.map { AlertMessage(message: $0) }
        }, set: { newValue in
            alertMessage = newValue?.message
        })) { alert in
            Alert(title: Text("Lock In"), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    ContentView(viewModel: ProfilesViewModel())
}

private struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

@available(iOS 16.0, *)
private extension ContentView {
    func handleLockInTapped() {
        NFCReader.shared.beginRead { result in
            switch result {
            case .success(let profileId):
                // Toggle behavior: same tag unlocks, different tag locks to that profile
                if let lockedId = viewModel.lockedProfileId, lockedId == profileId {
                    RestrictionsManager.shared.clear()
                    viewModel.unlock()
                    alertMessage = "Restrictions cleared."
                } else if let profile = viewModel.profiles.first(where: { $0.id == profileId }) {
                    RestrictionsManager.shared.apply(selection: profile.selection)
                    viewModel.lock(to: profileId)
                    alertMessage = "Applied restrictions for \(profile.name)."
                } else {
                    alertMessage = "No matching profile found on this device."
                }
            case .failure(let error):
                alertMessage = error.localizedDescription
            }
        }
    }
}

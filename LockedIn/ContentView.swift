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
    @State private var showEmergencyConfirm: Bool = false
    @State private var lockScale: CGFloat = 1.0
    @State private var lockRotation: Double = 0
    
    private func currentLockedProfileName() -> String? {
        guard let id = viewModel.lockedProfileId else { return nil }
        return viewModel.profiles.first(where: { $0.id == id })?.name
    }

    var body: some View {
        VStack(spacing: 20) {
            Button(action: handleLockInTapped) {
                Circle()
                    .fill(Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25, opacity: 1))
                    .frame(width: 220, height: 220)
                    .overlay(
                        Image(systemName: viewModel.lockedProfileId == nil ? "lock.open.fill" : "lock.fill")
                            .font(.system(size: 88, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(lockScale)
                            .rotationEffect(.degrees(lockRotation))
                    )
            }
            .contentShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)

            Text(viewModel.lockedProfileId == nil
                 ? "Tap the lock, then scan your NFC tag to lock in."
                 : "Tap the lock, then scan the same NFC tag to unlock.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let name = currentLockedProfileName() {
                Text("Using profile: \(name)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            if viewModel.lockedProfileId != nil {
                VStack(spacing: 8) {
                    Text("Emergency unlocks left: \(viewModel.emergencyUnlocksRemaining)")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.75))
                    Button(action: { showEmergencyConfirm = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Emergency Unlock")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.35))
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.emergencyUnlocksRemaining == 0)
                    .opacity(viewModel.emergencyUnlocksRemaining == 0 ? 0.5 : 1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2))
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
        .confirmationDialog(
            "Use an emergency unlock?",
            isPresented: $showEmergencyConfirm,
            titleVisibility: .visible
        ) {
            Button("Use 1 of \(viewModel.emergencyUnlocksRemaining) now", role: .destructive) {
                let didUnlock = viewModel.consumeEmergencyUnlock()
                if didUnlock {
                    alertMessage = "Unlocked using an emergency unlock. Remaining: \(viewModel.emergencyUnlocksRemaining)."
                    animateLockFeedback(isLocking: false)
                } else {
                    alertMessage = viewModel.lockedProfileId == nil ? "Device is not locked." : "No emergency unlocks remaining."
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("If you lost your NFC device, you can unlock without scanning. You have a limited number of uses.")
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
    func animateLockFeedback(isLocking: Bool) {
        let angle: Double = isLocking ? 20 : -20
        withAnimation(.spring(response: 0.5, dampingFraction: 0.4, blendDuration: 0.2)) {
            lockScale = 1.15
            lockRotation = angle
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.2)) {
                lockScale = 1.0
                lockRotation = 0
            }
        }
    }

    func handleLockInTapped() {
        NFCReader.shared.beginRead { result in
            switch result {
            case .success(let profileId):
                // Only allow unlocking with the same tag; do not overwrite an existing lock
                if let lockedId = viewModel.lockedProfileId {
                    if lockedId == profileId {
                        RestrictionsManager.shared.clear()
                        viewModel.unlock()
                        animateLockFeedback(isLocking: false)
                    } else {
                        alertMessage = "Device is already locked. Scan the same NFC tag to unlock."
                    }
                } else {
                    if let profile = viewModel.profiles.first(where: { $0.id == profileId }) {
                        RestrictionsManager.shared.apply(selection: profile.selection)
                        viewModel.lock(to: profileId)
                        animateLockFeedback(isLocking: true)
                    } else {
                        alertMessage = "No matching profile found on this device."
                    }
                }
            case .failure(let error):
                alertMessage = error.localizedDescription
            }
        }
    }
}

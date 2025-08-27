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
    @State private var showInfoSheet: Bool = false
    
    private func currentLockedProfileName() -> String? {
        guard let id = viewModel.lockedProfileId else { return nil }
        return viewModel.profiles.first(where: { $0.id == id })?.name
    }

    var body: some View {
        VStack(spacing: 20) {
            Button(action: handleLockInTapped) {
                Circle()
                    .fill(AppTheme.controlFill)
                    .frame(width: 220, height: 220)
                    .overlay(
                        Image(systemName: viewModel.lockedProfileId == nil ? "lock.open.fill" : "lock.fill")
                            .font(.system(size: 88, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .scaleEffect(lockScale)
                            .rotationEffect(.degrees(lockRotation))
                    )
            }
            .contentShape(Circle())
            .shadow(color: AppTheme.subtleShadow, radius: 14, x: 0, y: 8)

            Text(viewModel.lockedProfileId == nil
                 ? "Tap the lock, then scan your NFC tag to lock in."
                 : "Tap the lock, then scan the same NFC tag to unlock.")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let name = currentLockedProfileName() {
                Text("Using profile: \(name)")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
            }

            if viewModel.lockedProfileId != nil {
                VStack(spacing: 8) {
                    Text("Emergency unlocks left: \(viewModel.emergencyUnlocksRemaining)")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(AppTheme.textMuted)
                    Button(action: { showEmergencyConfirm = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Emergency Unlock")
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.danger.opacity(0.35))
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.emergencyUnlocksRemaining == 0)
                    .opacity(viewModel.emergencyUnlocksRemaining == 0 ? 0.5 : 1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .overlay(alignment: .top) {
            ZStack {
                Text("Lock In")
                    .font(Font(AppTheme.navBarLargeTitleFont))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                HStack {
                    Spacer()
                    Button(action: { showInfoSheet = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 25, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .accessibilityLabel("How to prevent Settings access during Lock Mode")
                }
            }
            .padding(.top, 24)
            .padding(.horizontal)
        }
        .task {
            await viewModel.requestAuthorizationIfNeeded()
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoInstructionsSheet()
                .presentationDetents([.medium, .large])
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

private struct InfoInstructionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // How It Works
                    Text("How It Works")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Create profiles in LockedIn and associate each with an NFC tag.")
                        Text("• On the Lock In screen, tap the lock, then scan that profile’s NFC tag to start Lock Mode.")
                        Text("• While locked, LockedIn applies restrictions to apps/web domains you selected for that profile.")
                        Text("• To unlock, tap the lock and scan the SAME NFC tag. This prevents switching profiles to bypass limits.")
                        Text("• If needed, use limited ‘Emergency Unlocks’ without scanning; these are capped and tracked.")
                    }

                    Divider().padding(.vertical, 8)

                    // Strict Mode
                    Text("Strict Mode")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Strict Mode helps prevent turning off Screen Time during Lock Mode by redirecting Settings to LockedIn using Shortcuts.")
                        Text("Setup (one-time):")
                            .font(.subheadline).bold()
                        Text("1) Open Shortcuts → Automation → + → New Automation → App → Choose ‘Settings’. Enable ‘Is Opened’. Enable ‘Run Immediately’. Disable ‘Notify When Run’. Tap Next.")
                        Text("2) Add action ‘Is Lock Mode On?’ (from LockedIn) and turn off ‘Show When Run’.")
                        Text("3) Add ‘If’ → condition: If ‘Is Lock Mode On?’ is true → add ‘Open App’ → choose ‘LockedIn’. Place it inside the If block. Tap Done.")
                        Text("Test: Start Lock Mode in LockedIn, open Settings → you should be redirected to LockedIn. Stop Lock Mode → Settings opens normally.")
                        Text("Tips:")
                            .font(.subheadline).bold()
                        Text("• Add the Shortcuts app to your blocked groups while locked to avoid disabling this automation.")
                        Text("• If ‘Is Lock Mode On?’ isn’t visible in Shortcuts, open LockedIn once and try again.")
                    }
                }
                .padding()
            }
            .navigationTitle("Info")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

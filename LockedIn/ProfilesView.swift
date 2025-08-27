//
//  ProfilesView.swift
//  LockedIn
//
//  Created by Assistant on 8/23/25.
//

import SwiftUI
import FamilyControls

@available(iOS 16.0, *)
struct ProfilesView: View {
    @ObservedObject var viewModel: ProfilesViewModel

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    Text("Profiles")
                        .font(Font(AppTheme.navBarLargeTitleFont))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        Spacer()
                        Button {
                            viewModel.beginAdd()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 25, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .accessibilityLabel("Add Profile")
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal)

                if viewModel.profiles.isEmpty {
                    ContentUnavailableView("No Profiles", systemImage: "person.3.fill", description: Text("Add a profile to manage selected apps and websites."))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.profiles) { profile in
                                ProfileRowView(profile: profile, viewModel: viewModel)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .task {
            await viewModel.requestAuthorizationIfNeeded()
        }
        .fullScreenCover(isPresented: $viewModel.isPresentingAddSheet) {
            AddProfileSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isPresentingEditSheet) {
            EditProfileSheet(viewModel: viewModel)
        }
    }
}

@available(iOS 16.0, *)
private struct ProfileRowView: View {
    let profile: Profile
    @ObservedObject var viewModel: ProfilesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let isLocked = viewModel.lockedProfileId == profile.id
            HStack(spacing: 8) {
                Text(profile.name)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
                if isLocked {
                    Text("In Use")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentSecondary.opacity(0.25))
                        .foregroundColor(AppTheme.accentSecondary)
                        .cornerRadius(6)
                        .accessibilityLabel("Profile in use")
                }
            }

            Text(summary(for: profile))
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(AppTheme.textMuted)

            Button {
                NFCWriter.shared.beginWrite(profile: profile)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text("Scan to NFC")
                }
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.accentPrimary.opacity(0.25))
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Scan \(profile.name) to NFC")

            HStack(spacing: 12) {
                Button {
                    viewModel.beginEdit(profile: profile)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accentSecondary.opacity(0.20))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.lockedProfileId == profile.id)

                Button(role: .destructive) {
                    viewModel.deleteProfile(id: profile.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .foregroundColor(AppTheme.danger)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.danger.opacity(0.15))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.lockedProfileId == profile.id)
                .accessibilityLabel("Delete \(profile.name)")
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(12)
        .shadow(color: AppTheme.subtleShadow, radius: 10, x: 0, y: 10)
        .contextMenu {
            Button(role: .destructive) {
                if let index = viewModel.profiles.firstIndex(where: { $0.id == profile.id }) {
                    viewModel.deleteProfiles(at: IndexSet(integer: index))
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(viewModel.lockedProfileId == profile.id)
            Button {
                viewModel.beginEdit(profile: profile)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .disabled(viewModel.lockedProfileId == profile.id)
        }
    }

    private func summary(for profile: Profile) -> String {
        let appCount = profile.selection.applicationTokens.count
        let webCount = profile.selection.webDomainTokens.count
        let categoryCount = profile.selection.categoryTokens.count
        return "Apps: \(appCount) • Websites: \(webCount) • Categories: \(categoryCount)"
    }
}

@available(iOS 16.0, *)
private struct AddProfileSheet: View {
    @ObservedObject var viewModel: ProfilesViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.footnote)
                        .foregroundColor(AppTheme.textMuted)
                    TextField("Focus name", text: $viewModel.newProfileName)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(12)
                        .background(AppTheme.surfaceElevated)
                        .cornerRadius(10)
                }
                .padding()

                Divider().background(AppTheme.surfaceElevated)

                FamilyActivityPicker(selection: $viewModel.newSelection)
            }
            .background(AppTheme.backgroundGradient)
            .tint(AppTheme.accentSecondary)
            .preferredColorScheme(.dark)
            .navigationTitle("New Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.isPresentingAddSheet = false }
                        .foregroundColor(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.saveNewProfile() }
                        .disabled(viewModel.newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .foregroundColor(viewModel.newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.textMuted : AppTheme.textPrimary)
                }
            }
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = AppTheme.navBarBackgroundUIColor
                appearance.titleTextAttributes = [
                    .foregroundColor: AppTheme.navBarTitleUIColor,
                    .font: AppTheme.navBarTitleFont
                ]
                appearance.largeTitleTextAttributes = [
                    .foregroundColor: AppTheme.navBarTitleUIColor,
                    .font: AppTheme.navBarLargeTitleFont
                ]
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().tintColor = AppTheme.tintUIColor
            }
        }
    }
}

@available(iOS 16.0, *)
private struct EditProfileSheet: View {
    @ObservedObject var viewModel: ProfilesViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Name").foregroundColor(AppTheme.textMuted)) {
                    TextField("Focus name", text: $viewModel.editProfileName)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(AppTheme.textPrimary)
                }

                Section(header: Text("Choose apps and websites").foregroundColor(AppTheme.textMuted)) {
                    FamilyActivityPicker(selection: $viewModel.editSelection)
                        .frame(minHeight: 360)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.backgroundGradient)
            .tint(AppTheme.accentSecondary)
            .preferredColorScheme(.dark)
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.isPresentingEditSheet = false }
                        .foregroundColor(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.saveEditedProfile() }
                        .disabled(viewModel.editProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (viewModel.editProfileId != nil && viewModel.lockedProfileId == viewModel.editProfileId))
                        .foregroundColor((viewModel.editProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (viewModel.editProfileId != nil && viewModel.lockedProfileId == viewModel.editProfileId)) ? AppTheme.textMuted : AppTheme.textPrimary)
                }
            }
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = AppTheme.navBarBackgroundUIColor
                appearance.titleTextAttributes = [
                    .foregroundColor: AppTheme.navBarTitleUIColor,
                    .font: AppTheme.navBarTitleFont
                ]
                appearance.largeTitleTextAttributes = [
                    .foregroundColor: AppTheme.navBarTitleUIColor,
                    .font: AppTheme.navBarLargeTitleFont
                ]
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().tintColor = AppTheme.tintUIColor
            }
        }
    }
}

struct ProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            ProfilesView(viewModel: ProfilesViewModel())
        } else {
            Text("Requires iOS 16+")
        }
    }
}



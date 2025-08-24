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
        NavigationStack {
            Group {
                if viewModel.profiles.isEmpty {
                    ContentUnavailableView("No Profiles", systemImage: "person.3.fill", description: Text("Add a profile to manage selected apps and websites."))
                } else {
                    List {
                        ForEach(viewModel.profiles) { profile in
                            VStack(alignment: .leading, spacing: 8) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.name)
                                        .font(.headline)
                                    Text(summary(for: profile))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Button {
                                    NFCWriter.shared.beginWrite(profile: profile)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "dot.radiowaves.left.and.right")
                                        Text("Scan to NFC")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                .tint(.blue)
                                .accessibilityLabel("Scan \(profile.name) to NFC")
                            }
                        }
                        .onDelete(perform: viewModel.deleteProfiles)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("profiles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.beginAdd()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add Profile")
                }
            }
        }
        .task {
            await viewModel.requestAuthorizationIfNeeded()
        }
        .sheet(isPresented: $viewModel.isPresentingAddSheet) {
            AddProfileSheet(viewModel: viewModel)
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
            Form {
                Section(header: Text("Name")) {
                    TextField("Focus name", text: $viewModel.newProfileName)
                        .textInputAutocapitalization(.words)
                }

                Section(header: Text("Choose apps and websites")) {
                    FamilyActivityPicker(selection: $viewModel.newSelection)
                        .frame(minHeight: 360)
                }
            }
            .navigationTitle("New Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.isPresentingAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.saveNewProfile() }
                        .disabled(viewModel.newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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



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
        NavigationView {
            ZStack {
                Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2)
                    .edgesIgnoringSafeArea(.all)

                Group {
                    if viewModel.profiles.isEmpty {
                        ContentUnavailableView("No Profiles", systemImage: "person.3.fill", description: Text("Add a profile to manage selected apps and websites."))
                            .foregroundColor(.white)
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
                .navigationTitle("Profiles")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.beginAdd()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.white)
                        }
                        .accessibilityLabel("Add Profile")
                    }
                }
                .fullScreenCover(isPresented: $viewModel.isPresentingAddSheet) {
                    AddProfileSheet(viewModel: viewModel)
                }
                .sheet(isPresented: $viewModel.isPresentingEditSheet) {
                    EditProfileSheet(viewModel: viewModel)
                }
            }
            .task {
                await viewModel.requestAuthorizationIfNeeded()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().tintColor = .white
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
                    .font(.headline)
                    .foregroundColor(.white)
                if isLocked {
                    Text("In Use")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.25))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                        .accessibilityLabel("Profile in use")
                }
            }

            Text(summary(for: profile))
                .font(.subheadline)
                .foregroundColor(.gray)

            Button {
                NFCWriter.shared.beginWrite(profile: profile)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text("Scan to NFC")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.3))
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.25))
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
                    .foregroundColor(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.lockedProfileId == profile.id)
                .accessibilityLabel("Delete \(profile.name)")
            }
        }
        .padding()
        .background(Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
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
                        .foregroundColor(.gray)
                    TextField("Focus name", text: $viewModel.newProfileName)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25))
                        .cornerRadius(10)
                }
                .padding()

                Divider().background(Color.black)

                FamilyActivityPicker(selection: $viewModel.newSelection)
            }
            .background(Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2))
            .navigationTitle("New Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.isPresentingAddSheet = false }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.saveNewProfile() }
                        .disabled(viewModel.newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .foregroundColor(viewModel.newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .white)
                }
            }
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().tintColor = .white
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
                Section(header: Text("Name").foregroundColor(.gray)) {
                    TextField("Focus name", text: $viewModel.editProfileName)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(.white)
                }

                Section(header: Text("Choose apps and websites").foregroundColor(.gray)) {
                    FamilyActivityPicker(selection: $viewModel.editSelection)
                        .frame(minHeight: 360)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2))
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.isPresentingEditSheet = false }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.saveEditedProfile() }
                        .disabled(viewModel.editProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (viewModel.editProfileId != nil && viewModel.lockedProfileId == viewModel.editProfileId))
                        .foregroundColor((viewModel.editProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (viewModel.editProfileId != nil && viewModel.lockedProfileId == viewModel.editProfileId)) ? .gray : .white)
                }
            }
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().tintColor = .white
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



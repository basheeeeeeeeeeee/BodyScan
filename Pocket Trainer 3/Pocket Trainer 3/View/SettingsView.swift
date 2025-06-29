//
//  SettingsView.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/28/25.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    // List of setting sections
    let sections = [
        "Account and Subscription",
        "Community",
        "Siri Shortcuts",
        "Notifications",
        "Language",
        "Downloads",
        "Apple Health",
        "Accessibility",
        "Support",
        "Terms and Conditions",
        "Privacy Policy",
        "My Data"
    ]
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Main Setting Sections
                ForEach(sections, id: \.self) { section in
                    NavigationLink(destination:
                        SettingsDetailView(sectionName: section)
                    ) {
                        Text(section)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.purple.opacity(0.3)) // Slightly off purple
                }
                
                // MARK: - Version & User Info
                Section {
                    Text("Version: Beta 0.1")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Logged in as: Beta")
                        .foregroundColor(.white.opacity(0.7))
                }
                .listRowBackground(Color.purple.opacity(0.3))
                
                // MARK: - Logout Button
                Section {
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
 // Optionally, navigate back to a login screen or update state
                            print("User signed out successfully.")
                        } catch {
                            print("Error signing out: \(error.localizedDescription)")
                        }
                    }) {
                        Text("Logout")
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(Color.red.opacity(0.8))
                // Add this Section at the end of your List (after the Logout Section)
                Section {
                    Color.clear
                        .frame(height: 100)
                }
                .listRowBackground(Color.clear)
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            // Make the navigation bar title white
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .foregroundColor(.white)
                }
            }
            // Remove default list background
            .scrollContentBackground(.hidden)
            // Use your existing background gradient
            .background(
                backgroundColorGradients.multiStepBackground
                    .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Detail View
struct SettingsDetailView: View {
    var sectionName: String
    
    var body: some View {
        VStack {
            Text(sectionName)
                .font(.largeTitle)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        // A custom background color for detail views
        .background(Color(red: 59/255, green: 38/255, blue: 84/255)
                        .opacity(0.8)
                        .ignoresSafeArea())
        .toolbar {
            // Title in the center, white
            ToolbarItem(placement: .principal) {
                Text(sectionName)
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
        .toolbarBackground(
            Color(red: 59/255, green: 38/255, blue: 84/255).opacity(0.8),
            for: .navigationBar
        )
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

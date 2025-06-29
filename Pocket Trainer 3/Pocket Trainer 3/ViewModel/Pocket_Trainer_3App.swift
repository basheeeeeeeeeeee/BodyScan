//
//  Pocket_Trainer_3App.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/27/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

class OnboardingViewModel: ObservableObject {
@Published var hasCompletedOnboarding: Bool? = nil
private var db = Firestore.firestore()
    func fetchOnboardingStatus(for userId: String) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                DispatchQueue.main.async {
                    self.hasCompletedOnboarding = data?["hasCompletedOnboarding"] as? Bool ?? false
                }
            } else {
                DispatchQueue.main.async {
                    self.hasCompletedOnboarding = false
                }
            }
        }
    }

    init() {
        // Optionally, you could fetch here if you already have a user, but we'll do it in RootView's onAppear.
    }
}

struct LavaLampBackground: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple, Color.indigo]),
                       startPoint: animate ? .topLeading : .bottomTrailing,
                       endPoint: animate ? .bottomTrailing : .topLeading)
            .animation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
            .ignoresSafeArea()
    }
}

struct LoadingView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            LavaLampBackground()
            VStack {
                Text("💪")
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scale)
                    .onAppear {
                        scale = 1.2
                    }
                Text("Coach AI")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
        }
    }
}
/// Root view that chooses which view to display based on auth and onboarding status.
struct RootView: View {
@StateObject var onboardingViewModel = OnboardingViewModel()
@State private var isAuthenticated: Bool = Auth.auth().currentUser != nil

    var body: some View {
        Group {
            if !isAuthenticated {
                // Show sign-in screen if not authenticated
                SignInView()
            } else {
                // User is authenticated; check onboarding status from Firebase
                if let completed = onboardingViewModel.hasCompletedOnboarding {
                    if completed {
                        mainView()
                    } else {
                        InitialSetupView()
                    }
                } else {
                    LoadingView()
                }
            }
        }
        .onAppear {
            // Listen to authentication state changes.
            Auth.auth().addStateDidChangeListener { auth, user in
                isAuthenticated = (user != nil)
                if let user = user {
                    onboardingViewModel.fetchOnboardingStatus(for: user.uid)
                }
            }
        }
    }
}

@main
struct Pocket_Trainer_3App: App {
@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
var body: some Scene {
WindowGroup {
RootView()
}
}
}

//
//  SignInView.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/29/25.
//
import SwiftUI
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

struct SignInView: View {
    @State private var isSignedIn: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient that matches your brand look
                LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Pocket Trainer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Google Sign In Button
                    Button(action: {
                        signInWithGoogle()
                    }) {
                        Text("Sign in with Google")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // NavigationLink to InitialSetupView if signed in
                    NavigationLink(destination: InitialSetupView(), isActive: $isSignedIn) {
                        EmptyView()
                    }
                }
                .padding()
            }
        }
    }
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Missing client ID")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get the root view controller for presentation
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("There is no root view controller!")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Error signing in with Google: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user else {
                print("Missing Google user")
                return
            }
            guard let idToken = user.idToken?.tokenString else {
                print("Missing idToken")
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign in error: \(error.localizedDescription)")
                    return
                }
                print("Signed in with Google")
                DispatchQueue.main.async {
                    isSignedIn = true
                }
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}

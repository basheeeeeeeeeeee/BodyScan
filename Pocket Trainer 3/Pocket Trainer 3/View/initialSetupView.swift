//
//  initialSetupView.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/29/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct InitialSetupView: View {
    @State private var currentStep: Int = 1
    @State private var workoutDays: String = ""
    @State private var weightGoal: String = ""
    @State private var errorMessage: String? = nil
    @State private var goToMainView: Bool = false  // Triggers navigation to MainView
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                VStack {
                    if currentStep == 1 {
                        // Step 1: Ask about workout days
                        Text("How many days do you workout?")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.top, 40)
                        
                        TextField("Enter number", text: $workoutDays)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .frame(height: 60)
                            .padding(.horizontal, 30)
                        
                        if let error = errorMessage, !error.isEmpty {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: {
                            // Validate workoutDays
                            if let days = Int(workoutDays), days > 0 {
                                errorMessage = nil
                                currentStep = 2
                            } else {
                                errorMessage = "Please enter a valid number"
                            }
                        }) {
                            Text("Next")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 30)
                        
                    } else if currentStep == 2 {
                        // Step 2: Ask about weight goal
                        Text("What is your weight goal?")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.top, 40)
                        
                        TextField("Enter weight goal", text: $weightGoal)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .frame(height: 60)
                            .padding(.horizontal, 30)
                        
                        if let error = errorMessage, !error.isEmpty {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: {
                            if !weightGoal.isEmpty {
                                errorMessage = nil
                                currentStep = 3
                            } else {
                                errorMessage = "Please enter your weight goal"
                            }
                        }) {
                            Text("Next")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 30)
                        
                    } else if currentStep == 3 {
                        // Step 3: Subscription options
                        Text("Choose your plan")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.top, 40)
                        
                        Text("Purchase a subscription or start a free trial")
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                        
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Purchase Subscription")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 30)
                        
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Start Free Trial")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    Spacer()
                    
                    // Hidden NavigationLink that triggers navigation when onboarding is complete.
                    NavigationLink(destination: mainView().navigationBarBackButtonHidden(true),
                                   isActive: $goToMainView) {
                        EmptyView()
                    }
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true) // Prevent back navigation from initial setup
        }
    }
    
    func completeOnboarding() {
        guard let user = Auth.auth().currentUser else {
            print("No authenticated user")
            return
        }
        
        // Create the data to store in Firestore.
        let data: [String: Any] = [
            "hasCompletedOnboarding": true,
            "workoutDays": workoutDays,
            "weightGoal": weightGoal,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        Firestore.firestore().collection("users").document(user.uid).setData(data, merge: true) { error in
            if let error = error {
                print("Error saving onboarding data: \(error.localizedDescription)")
            } else {
                print("Onboarding completed. Navigate to main view.")
                DispatchQueue.main.async {
                    goToMainView = true
                }
            }
        }
    }
}

struct InitialSetupView_Previews: PreviewProvider {
static var previews: some View {
InitialSetupView()
}
}

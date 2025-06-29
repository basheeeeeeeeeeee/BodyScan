//
//  WorkoutView.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/28/25.
//

import SwiftUI

// MARK: - Models

struct Exercise: Identifiable {
    let id = UUID()
    var name: String
    var sets: String
}

struct WorkoutDay: Identifiable {
    let id = UUID()
    var dayName: String
    var exercises: [Exercise]
}

// MARK: - WorkoutView

struct WorkoutView: View {
    // Sample workout for demonstration. In production, pass the current workout from HomeView.
    @State private var currentWorkout: WorkoutDay = WorkoutDay(
        dayName: "Monday (Push)",
        exercises: [
            Exercise(name: "Push Ups", sets: "25 x 3"),
            Exercise(name: "Bench Press", sets: "12 x 3")
        ]
    )
    
    // Workout session state variables
    @State private var workoutStarted: Bool = false
    @State private var showCountdown: Bool = false
    @State private var countdownValue: Int = 3
    @State private var paused: Bool = false
    @State private var exerciseCompletion: [UUID: Bool] = [:]
    
    // Timer for workout session
    @State private var workoutStartTime: Date? = nil
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Environment for dismissing view (hides back button)
    @Environment(\.presentationMode) var presentationMode
    
    // Alert to confirm workout start
    @State private var showStartConfirmation: Bool = true
    
    var body: some View {
        ZStack {
            // Background: use your AnimatedBackgroundView (assumed to be defined elsewhere)
            AnimatedBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Display workout timer if the workout is active.
                if workoutStarted {
                    Text("Workout Time: \(formatTime(elapsedTime))")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
                
                // List of exercises
                List {
                    ForEach(currentWorkout.exercises) { exercise in
                        HStack {
                            Text(exercise.name)
                                .foregroundColor(.primary)
                            Spacer()
                            // Checkbox for marking exercise as complete.
                            if let completed = exerciseCompletion[exercise.id], completed {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Button(action: {
                                    exerciseCompletion[exercise.id] = true
                                }) {
                                    Image(systemName: "circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarBackButtonHidden(true)
            
            // Countdown overlay (if active)
            if showCountdown {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    Text("\(countdownValue)")
                        .font(.system(size: 100, weight: .bold))
                        .foregroundColor(.white)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            // Present start confirmation when view appears.
            if showStartConfirmation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showStartConfirmation = false
                    startCountdown()
                }
            }
        }
        .onReceive(timer) { _ in
            if workoutStarted, let start = workoutStartTime, !paused {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $showStartConfirmation) {
            Alert(title: Text("Start Workout?"),
                  message: Text("Do you want to start your workout?"),
                  primaryButton: .default(Text("Yes"), action: {
                      startCountdown()
                  }),
                  secondaryButton: .cancel({
                      presentationMode.wrappedValue.dismiss()
                  }))
        }
    }
    
    private func startCountdown() {
        // Start a 3-2-1 countdown.
        showCountdown = true
        countdownValue = 3
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                timer.invalidate()
                withAnimation {
                    showCountdown = false
                }
                workoutStarted = true
                workoutStartTime = Date()
                elapsedTime = 0
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutView()
        }
    }
}

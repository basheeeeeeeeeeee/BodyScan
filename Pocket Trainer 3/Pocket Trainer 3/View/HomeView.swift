//
//  HomeView.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/28/25.
//

import SwiftUI

// MARK: - Models for Placeholders

struct WhatsNewCard {
    var title: String
    var imageName: String
    var duration: String
    var level: String
}

struct DayWorkout: Identifiable {
    let id = UUID()
    var title: String
    var setsInfo: String
    var estimatedDuration: Int
}

struct WeeklySchedule {
    var monday: [DayWorkout]
    var tuesday: [DayWorkout]
    var wednesday: [DayWorkout]
    var thursday: [DayWorkout]
    var friday: [DayWorkout]
    var saturday: [DayWorkout]
    var sunday: [DayWorkout]
}

// MARK: - HomeView

struct HomeView: View {
    @Binding var selectedTab: Int

    // Slider index for "What's New"
    @State private var whatsNewIndex = 0
    private let sliderTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    // User Data (placeholder: in production, fetch from Firebase)
    @State private var userName: String = "Bashir"
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning 🔥"
        case 12..<17: return "Good Afternoon 🔥"
        default: return "Good Evening 🔥"
        }
    }
    
    // User Level & XP (placeholder)
    @State private var userXP: Int = 0
    @State private var userLevel: Int = 1
    
    // "What's New" data
    let whatsNewData: [WhatsNewCard] = [
        WhatsNewCard(title: "Latest HIIT Program", imageName: "workout_bellyfat", duration: "12 min", level: "Intermediate"),
        WhatsNewCard(title: "New Yoga Routine", imageName: "workout_losefat", duration: "20 min", level: "Beginner")
    ]
    
    // Weekly schedule (placeholder; load from cloud in production)
    @State private var schedule = WeeklySchedule(
        monday: [
            DayWorkout(title: "Push Ups", setsInfo: "25 x 3", estimatedDuration: 15),
            DayWorkout(title: "Bench Press", setsInfo: "12 x 3", estimatedDuration: 15),
            DayWorkout(title: "Chest Flies", setsInfo: "12 x 3", estimatedDuration: 10)
        ],
        tuesday: [
            DayWorkout(title: "Pull Ups", setsInfo: "17 x 3", estimatedDuration: 15),
            DayWorkout(title: "Bicep Curls", setsInfo: "2 x 12", estimatedDuration: 10)
        ],
        wednesday: [],
        thursday: [],
        friday: [],
        saturday: [],
        sunday: []
    )
    
    // Today is tracked as an index (0: Monday, …, 6: Sunday)
    @State private var todayIndex: Int = 0
    
    // XP penalty alert
    @State private var showNegativeXPAlert = false
    
    // Progress for today's workout (0.0 to 1.0)
    @State private var todayProgress: Double = 0.0
    
    // Tracking workout time (in seconds)
    @State private var elapsedTime: TimeInterval = 0
    
    // Computed property: today's workouts from the weekly schedule.
    private var todaysWorkouts: [DayWorkout] {
        switch todayIndex {
        case 0: return schedule.monday
        case 1: return schedule.tuesday
        case 2: return schedule.wednesday
        case 3: return schedule.thursday
        case 4: return schedule.friday
        case 5: return schedule.saturday
        default: return schedule.sunday
        }
    }
    
    // Workout state in HomeView
    @State private var workoutStarted: Bool = false
    @State private var workoutStartTime: Date? = nil
    @State private var paused: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Greeting & Level Badge
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text(userName)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            LevelBadgeView(level: userLevel, xp: userXP)
                        }
                        .padding(.top, 30)
                        .padding(.horizontal)
                        
                        // What's New Section
                        Text("What's New")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        TabView(selection: $whatsNewIndex) {
                            ForEach(whatsNewData.indices, id: \.self) { i in
                                ZStack(alignment: .bottomLeading) {
                                    Image(whatsNewData[i].imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 180)
                                        .cornerRadius(20)
                                        .overlay(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.7)]),
                                                startPoint: .center,
                                                endPoint: .bottom
                                            )
                                            .cornerRadius(20)
                                        )
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(whatsNewData[i].title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(whatsNewData[i].duration)  |  \(whatsNewData[i].level)")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .padding()
                                }
                                .padding(.horizontal)
                                .tag(i)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .frame(height: 180)
                        .onReceive(sliderTimer) { _ in
                            withAnimation {
                                whatsNewIndex = (whatsNewIndex + 1) % whatsNewData.count
                            }
                        }
                        
                        // Today Plan Header
                        HStack {
                            Text("Today Plan")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            if workoutStarted {
                                Text("Time: \(formatTime(elapsedTime))")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                            } else {
                                let totalEst = todaysWorkouts.reduce(0) { $0 + $1.estimatedDuration }
                                Text("Estimated: \(totalEst) min")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Today Plan Card
                        VStack(spacing: 16) {
                            if todaysWorkouts.isEmpty {
                                Text("No workouts for today")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(15)
                            } else {
                                ForEach(todaysWorkouts) { w in
                                    HStack(spacing: 12) {
                                        Image("workout_placeholder")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(10)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(w.title)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .fontWeight(.semibold)
                                            Text(w.setsInfo)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                            Text("Estimated: \(w.estimatedDuration) min")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(15)
                                }
                                
                                // Progress Bar
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Progress: \(Int(todayProgress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .frame(height: 6)
                                            .foregroundColor(Color.white.opacity(0.2))
                                        RoundedRectangle(cornerRadius: 4)
                                            .frame(width: CGFloat(todayProgress) * 120, height: 6)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Buttons – only if workouts exist and not started
                            if !todaysWorkouts.isEmpty && !workoutStarted {
                                HStack(spacing: 8) {
                                    Button(action: {
                                        // Switch tab to workout view and mark as started.
                                        selectedTab = 1
                                        workoutStarted = true
                                        workoutStartTime = Date()
                                    }) {
                                        Text("Start Workout")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                    if todayIndex == 0 {
                                        Button(action: {
                                            moveToTomorrowDay()
                                        }) {
                                            Text("Move to Tomorrow")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.blue)
                                                .cornerRadius(8)
                                        }
                                    } else if todayIndex == 6 {
                                        Button(action: {
                                            applyNegativeXP()
                                        }) {
                                            Text("Skip")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.red)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
                .navigationBarHidden(true)
                .alert(isPresented: $showNegativeXPAlert) {
                    Alert(title: Text("-XP!"), message: Text("You lost some XP."), dismissButton: .default(Text("OK")))
                }
            }
        }
        .onReceive(sliderTimer) { _ in }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if let start = workoutStartTime, workoutStarted, !paused {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }
    
    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func applyNegativeXP() {
        userXP -= 10
        if userXP < 0 { userXP = 0 }
        showNegativeXPAlert = true
    }
    
    private func moveToTomorrowDay() {
        guard todayIndex < 6 else {
            applyNegativeXP()
            return
        }
        switch todayIndex {
        case 0:
            schedule.tuesday.append(contentsOf: schedule.monday)
            schedule.monday.removeAll()
        case 1:
            schedule.wednesday.append(contentsOf: schedule.tuesday)
            schedule.tuesday.removeAll()
        case 2:
            schedule.thursday.append(contentsOf: schedule.wednesday)
            schedule.wednesday.removeAll()
        case 3:
            schedule.friday.append(contentsOf: schedule.thursday)
            schedule.thursday.removeAll()
        case 4:
            schedule.saturday.append(contentsOf: schedule.friday)
            schedule.friday.removeAll()
        case 5:
            schedule.sunday.append(contentsOf: schedule.saturday)
            schedule.saturday.removeAll()
        default:
            applyNegativeXP()
            return
        }
    }
}

// MARK: - LevelBadgeView

struct LevelBadgeView: View {
    var level: Int
    var xp: Int
    
    var body: some View {
        HStack(spacing: 8) {
            }
            Text("Level \(level) | XP: \(xp)")
                .font(.footnote)
                .foregroundColor(.white)
        }
    }


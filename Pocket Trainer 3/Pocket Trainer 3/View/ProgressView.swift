//
//  ProgressView.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/28/25.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
extension Date: Identifiable {
public var id: TimeInterval { self.timeIntervalSince1970 }
}

struct ProgressView: View {
    @State private var currentDate: Date = Date()
    @State private var selectedDate: Date? = nil
    let calendar = Calendar.current
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Use the same linear gradient background as other views
                backgroundColorGradients.multiStepBackground
                    .ignoresSafeArea()
                VStack {
                    // Month header with previous and next buttons.
                    HStack {
                        Button(action: {
                            if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate) {
                                currentDate = previousMonth
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .padding()
                        }
                        Spacer()
                        Text(monthYearString(from: currentDate))
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                                currentDate = nextMonth
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Days of week header.
                    HStack {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar grid.
                    let days = generateDaysInMonth(for: currentDate)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(days, id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                            }) {
                                Text("\(calendar.component(.day, from: date))")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(8)
                                    .background(calendar.isDate(date, inSameDayAs: Date()) ? Color.blue.opacity(0.7) : Color.clear)
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Progress")
            // Present a detail view when a day is tapped.
            .sheet(item: $selectedDate) { date in
                DayDetailView(date: date)
            }
        }
    }
    
    // Helper function to format month and year.
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    // Generate an array of dates to fill the calendar grid (42 days to fill 6 weeks).
    func generateDaysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        var days: [Date] = []
        for offset in 0..<42 {
            if let day = calendar.date(byAdding: .day, value: offset, to: firstWeek.start) {
                days.append(day)
            }
        }
        return days
    }
}

struct DayDetailView: View {
    let date: Date
    @State private var progressData: [String: Any]? = nil
    @State private var isLoading: Bool = true
    let calendar = Calendar.current
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                } else if let data = progressData {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Progress for \(formattedDate(date))")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                            
                            if let height = data["height"] as? Int {
                                Text("Height: \(height) inches")
                                    .foregroundColor(.white)
                            }
                            if let weight = data["weight"] as? Int {
                                Text("Weight: \(weight) lbs")
                                    .foregroundColor(.white)
                            }
                            if let chest = data["chest"] as? Int {
                                Text("Chest: \(chest) inches")
                                    .foregroundColor(.white)
                            }
                            if let waist = data["waist"] as? Int {
                                Text("Waist: \(waist) inches")
                                    .foregroundColor(.white)
                            }
                            if let arm = data["arm"] as? Int {
                                Text("Arm: \(arm) inches")
                                    .foregroundColor(.white)
                            }
                            if let leg = data["leg"] as? Int {
                                Text("Leg: \(leg) inches")
                                    .foregroundColor(.white)
                            }
                            if let calf = data["calf"] as? Int {
                                Text("Calf: \(calf) inches")
                                    .foregroundColor(.white)
                            }
                            if let routine = data["workoutRoutine"] as? String {
                                Text("Workout Routine:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(routine)
                                    .foregroundColor(.white)
                            }
                            // Placeholder for photos.
                            Text("Photos: [Placeholder for day’s photos]")
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                } else {
                    Text("No progress data found for this day.")
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
            )
            .navigationTitle("Day Details")
            .onAppear {
                fetchProgressData()
            }
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    // Fetch the stored progress data from Firestore for the given date.
    func fetchProgressData() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        let db = Firestore.firestore()
        // Assume progress data is stored under a document with key formatted as "yyyy-MM-dd"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)
        
        db.collection("users").document(user.uid).collection("progress").document(dateKey).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching progress data: \(error.localizedDescription)")
            }
            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data() {
                progressData = data
            }
            isLoading = false
        }
    }
}

struct ProgressView_Previews: PreviewProvider {
static var previews: some View {
ProgressView()
}
}

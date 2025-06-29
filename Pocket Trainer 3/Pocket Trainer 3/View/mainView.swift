//  mainView.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/27/25.

import SwiftUI

struct mainView: View {
    @State private var selectedTab: Int

    // Added initializer so that we can set the initial tab.
    init(initialSelectedTab: Int = 0) {
        _selectedTab = State(initialValue: initialSelectedTab)
    }
    
    @State private var showScanIntro = false
    @State private var showScanView = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                
                // Main Content (switches based on selectedTab; note: we remove ScanView here)
                Group {
                    switch selectedTab {
                    case 0: HomeView(selectedTab: $selectedTab)
                    case 1: WorkoutView()
                    case 3: ProgressView()
                    case 4: SettingsView()
                    default: HomeView(selectedTab: $selectedTab)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: [.horizontal])
            }
            
            // Bottom Tab Bar – visible only when not scanning.
            TabBarView(selectedTab: $selectedTab, showScanIntro: $showScanIntro)
        }
        .ignoresSafeArea()
        .background(Color.black)
        // Present the ScanIntroView modally when triggered.
        .fullScreenCover(isPresented: $showScanIntro) {
            ScanIntroView(selectedTab: $selectedTab,
                          showScanIntro: $showScanIntro,
                          showScanView: $showScanView)
        }
        // Once ScanIntroView finishes, present ScanView modally.
        .fullScreenCover(isPresented: $showScanView) {
            ScanView()
        }
    }
}

struct TabBarView: View {
    @Binding var selectedTab: Int
    @Binding var showScanIntro: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 59/255, green: 38/255, blue: 84/255).opacity(0.9),
                            Color(red: 59/255, green: 38/255, blue: 84/255)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 120)
                .shadow(radius: 5)
            
            HStack {
                Button(action: { selectedTab = 0 }) {
                    TabButton(image: "square.grid.2x2", isSelected: selectedTab == 0)
                }
                Spacer()
                Button(action: { selectedTab = 1 }) {
                    TabButton(image: "dumbbell", isSelected: selectedTab == 1)
                }
                Spacer()
                // Center Floating Button triggers the Scan Intro flow.
                Button(action: { showScanIntro = true }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.pink, Color.purple]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 65, height: 65)
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .light))
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                Button(action: { selectedTab = 3 }) {
                    TabButton(image: "chart.bar", isSelected: selectedTab == 3)
                }
                Spacer()
                Button(action: { selectedTab = 4 }) {
                    TabButton(image: "gearshape", isSelected: selectedTab == 4)
                }
            }
            .padding(.horizontal, 30)
            .frame(height: 90)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct mainView_Previews: PreviewProvider {
    static var previews: some View {
        mainView(initialSelectedTab: 0)
    }
}

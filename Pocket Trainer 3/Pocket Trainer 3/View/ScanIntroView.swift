//
//  ScanIntroView.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/29/25.
//
import SwiftUI

struct ScanIntroView: View {
    @Binding var selectedTab: Int
    @Binding var showScanIntro: Bool
    @Binding var showScanView: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColorGradients.multiStepBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Body Scan")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Ready to scan your body? Position yourself so that your front, left, right, and back are visible. We'll automatically capture the photos.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        // Dismiss the intro and then show ScanView.
                        showScanIntro = false
                        showScanView = true
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

struct ScanIntroView_Previews: PreviewProvider {
    static var previews: some View {
        ScanIntroView(selectedTab: .constant(0),
                      showScanIntro: .constant(true),
                      showScanView: .constant(false))
    }
}

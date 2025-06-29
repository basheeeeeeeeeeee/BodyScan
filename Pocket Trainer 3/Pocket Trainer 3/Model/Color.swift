//
//  Color.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/28/25.
//

import SwiftUI

struct backgroundColor {
    static let pinkLessBrightTop = Color(red: 155/255, green: 37/255, blue: 99/255).opacity(0.7)
    static let midMagenta        = Color(red: 110/255, green: 31/255, blue: 102/255)
    static let darkPurple        = Color(red: 49/255, green: 28/255, blue: 74/255)
    static let deepDark          = Color(red: 32/255, green: 30/255, blue: 50/255)
}

struct backgroundColorGradients {
    // Use the animated background view as the multiStepBackground
    static let multiStepBackground = AnimatedBackgroundView()
}

struct AnimatedBackgroundView: View {
    @State private var animate1 = false
    @State private var animate2 = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base background color
                backgroundColor.deepDark
                    .ignoresSafeArea()
                
                // First animated blob
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [backgroundColor.pinkLessBrightTop, backgroundColor.midMagenta]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                    .blur(radius: 50)
                    .offset(x: animate1 ? -geometry.size.width * 0.25 : geometry.size.width * 0.25,
                            y: animate1 ? -geometry.size.height * 0.25 : geometry.size.height * 0.25)
                    .animation(Animation.easeInOut(duration: 20).repeatForever(autoreverses: true), value: animate1)
                
                // Second animated blob
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [backgroundColor.darkPurple, backgroundColor.deepDark]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.9)
                    .blur(radius: 50)
                    .offset(x: animate2 ? geometry.size.width * 0.3 : -geometry.size.width * 0.3,
                            y: animate2 ? geometry.size.height * 0.3 : -geometry.size.height * 0.3)
                    .animation(Animation.easeInOut(duration: 25).repeatForever(autoreverses: true), value: animate2)
            }
            .onAppear {
                animate1 = true
                animate2 = true
            }
        }
    }
}

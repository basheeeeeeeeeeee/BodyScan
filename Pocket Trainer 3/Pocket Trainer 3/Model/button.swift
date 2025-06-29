//
//  Untitled.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/28/25.
//
import SwiftUI

public struct plusButton: View {
    public var body: some View {
        
        ZStack {
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.pink, Color.purple]), startPoint: .top, endPoint: .bottom))
                .frame(width: 65, height: 65)
                .shadow(color: Color.pink.opacity(0.8), radius: 10, x: 0, y: 5)
            
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

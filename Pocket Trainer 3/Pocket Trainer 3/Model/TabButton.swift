//
//  TabButton.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/28/25.
//
import SwiftUI

struct TabButton: View {
    var image: String
    var isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: image)
                .font(.system(size: 18))
                .foregroundColor(isSelected ? Color.pink : Color.gray)
        }
        .frame(width: 40, height: 40)
        .background(isSelected ? Color.pink.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

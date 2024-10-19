//
//  OButton.swift
//  Muwaqqit
//
//  Created by Human on 19/10/2024.
//

import SwiftUI

struct OButton: View {
    private var label: String
    private var icon: Icons?
    private var action: () -> Void
    
    @State private var buttonClickCounter: Int = 0
    
    init(label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }
    
    init(icon: Icons, label: String, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            buttonClickCounter += 1
            action()
        }) {
            HStack {
                if (icon != nil) {
                    Image(icon!.rawValue)
                }
                Text(label)
            }
            .foregroundStyle(.background)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.accent)
            .cornerRadius(999)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact, trigger: buttonClickCounter)
    }
}

#Preview {
    OButton(icon: .brandGoogle, label: "Continue with Google") {
        print("button clicked")
    }
}

//
//  OButton.swift
//  Muwaqqit
//
//  Created by Yazeed AlKhalaf on 29/09/2024.
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
    
    init(label: String, icon: Icons, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
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
                .foregroundStyle(.primary)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.onPrimary)
                .cornerRadius(999)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact, trigger: buttonClickCounter)
    }
}

#Preview {
    OButton(label: "Continue with Google") {
        print("button clicked")
    }
}

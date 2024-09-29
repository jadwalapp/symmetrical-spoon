//
//  OButton.swift
//  Muwaqqit
//
//  Created by Yazeed AlKhalaf on 29/09/2024.
//

import SwiftUI

struct OButton: View {
    private var label: String
    private var action: () -> Void
    
    init(label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .foregroundStyle(.primary)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.onPrimary)
                .cornerRadius(999)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OButton(label: "Continue with Google") {
        print("button clicked")
    }
}

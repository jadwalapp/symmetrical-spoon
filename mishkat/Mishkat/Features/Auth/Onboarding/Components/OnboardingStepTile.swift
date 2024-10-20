//
//  OnboardingStepTile.swift
//  Muwaqqit
//
//  Created by Human on 19/10/2024.
//

import SwiftUI

struct OnboardingStepTile: View {
    private var number: String
    private var title: String
    
    init(number: String, title: String) {
        self.number = number
        self.title = title
    }
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(.accent)
                    .frame(width: 40, height: 40)
                Text(number)
                    .foregroundStyle(.background)
                    .fontWeight(.bold)
                    .font(.title)
            }
            .padding(.trailing, 8)
            Text(title)
                .foregroundStyle(.primary)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    OnboardingStepTile(
        number: "1",
        title: "Create Account/Login"
    )
}

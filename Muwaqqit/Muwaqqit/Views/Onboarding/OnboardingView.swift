//
//  OnboardingView.swift
//  Muwaqqit
//
//  Created by Yazeed AlKhalaf on 29/09/2024.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            Image("AppIcon")
                .resizable()
                .frame(width: 160*1.5, height: 160*1.5)
                .padding(.bottom, 64)
            VStack(alignment: .leading) {
                OnboardingStepTile(
                    number: "1",
                    title: "Create Account/Login"
                )
                OnboardingStepTile(
                    number: "2",
                    title: "Connect WhatsApp"
                )
                OnboardingStepTile(
                    number: "3",
                    title: "Manage Calendars"
                )
            }
            Spacer()
            OButton(
                label: "Continue with Google",
                icon: .brandGoogle
            ) {
                print("Continue with Google")
            }
            .padding(.bottom, 8)
            OButton(
                label: "Continue with Email",
                icon: .mail
            ) {
                print("Continue with Email")
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    OnboardingView()
}
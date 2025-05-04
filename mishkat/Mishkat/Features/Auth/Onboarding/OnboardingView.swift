//
//  OnboardingView.swift
//  Muwaqqit
//
//  Created by Human on 19/10/2024.
//


import SwiftUI
import GoogleSignInSwift
import GoogleSignIn

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isAnimating = false
    
    let innerRadius: CGFloat = 120
    let outerRadius: CGFloat = 200
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.15),
                    Color(uiColor: .systemBackground),
                    Color.accentColor.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(uiColor: .systemGray3),
                                    Color(uiColor: .systemGray5),
                                    Color(uiColor: .systemGray3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                        .frame(
                            width: innerRadius * 2,
                            height: innerRadius * 2
                        )
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(uiColor: .systemGray4),
                                    Color(uiColor: .systemGray6),
                                    Color(uiColor: .systemGray4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: outerRadius * 2, height: outerRadius * 2)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)

                    Image("LogoMinimal")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(Color(uiColor: .label))
                }
                .frame(height: 400)
                
                Spacer()
                
                VStack(spacing: 16) {
                    VStack {
                        Text("Jadwal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("Intelligent Calendar")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        PresenterResolverWrapper { controller in
                            OButton(
                                icon: .brandGoogle,
                                label: "Continue with Google"
                            ) {
                                Task {
                                    let googleResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: controller)
                                    
                                    authViewModel.useGoogle(googleToken: googleResult.user.idToken?.tokenString ?? "")
                                }
                            }
                        }
                        
                        OButton(
                            icon: .mail,
                            label: "Continue with Email"
                        ) {
                            authViewModel.continueWithEmail()
                        }
                    }
                    .padding(.top, 24)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    Group {
        OnboardingView()
    }
}

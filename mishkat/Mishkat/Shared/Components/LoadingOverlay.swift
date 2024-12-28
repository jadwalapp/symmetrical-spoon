//
//  LoadingOverlay.swift
//  Mishkat
//
//  Created by Human on 28/12/2024.
//

import SwiftUI

struct LoadingOverlay: View {
    let message: String
    @State private var rotation = 0.0
    @State private var trimEnd = 0.6
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 3)
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .trim(from: 0, to: trimEnd)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .accentColor.opacity(0),
                                    .accentColor
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(
                                lineWidth: 3,
                                lineCap: .round
                            )
                        )
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(rotation))
                }
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
                
                Text(message)
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
    }
}

#Preview {
    ZStack {
        VStack {
            Text("some stuff to preview")
            Text("some stuff to preview")
            Text("some stuff to preview")
            Text("some stuff to preview")
            Text("some stuff to preview")
            Text("some stuff to preview")
            Text("some stuff to preview")
        }
        LoadingOverlay(message: "we are doing stuff in the bg :D")
    }
}

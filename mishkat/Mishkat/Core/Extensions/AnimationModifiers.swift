//
//  AnimationModifiers.swift
//  Mishkat
//
//  Created by Human on 28/12/2024.
//

import SwiftUI

/// A modifier that animates a view's entrance with a fade and slide effect
struct EntranceAnimationModifier: ViewModifier {
    @State private var showContent = false
    let delay: Double
    let offsetY: Double
    
    init(delay: Double = 0, offsetY: Double = 20) {
        self.delay = delay
        self.offsetY = offsetY
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : offsetY)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    showContent = true
                }
            }
    }
}

/// A modifier that creates a continuous pulsing animation
struct PulsingAnimationModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

/// A modifier that animates a view's entrance with a horizontal slide effect
struct HorizontalEntranceModifier: ViewModifier {
    @State private var showContent = false
    let delay: Double
    let offsetX: Double
    
    init(delay: Double = 0, offsetX: Double = 20) {
        self.delay = delay
        self.offsetX = offsetX
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(showContent ? 1 : 0)
            .offset(x: showContent ? 0 : offsetX)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    showContent = true
                }
            }
    }
}

//
//  View+Animations.swift
//  Mishkat
//
//  Created by Human on 28/12/2024.
//

import SwiftUI

extension View {
    /// Applies an entrance animation that fades in and slides up
    /// - Parameters:
    ///   - delay: Time to wait before starting the animation
    ///   - offsetY: Distance to slide from
    func entranceAnimation(delay: Double = 0, offsetY: Double = 20) -> some View {
        modifier(EntranceAnimationModifier(delay: delay, offsetY: offsetY))
    }
    
    /// Applies a continuous pulsing animation
    func pulsingAnimation() -> some View {
        modifier(PulsingAnimationModifier())
    }
    
    /// Applies an entrance animation that fades in and slides horizontally
    /// - Parameters:
    ///   - delay: Time to wait before starting the animation
    ///   - offsetX: Distance to slide from
    func horizontalEntrance(delay: Double = 0, offsetX: Double = 20) -> some View {
        modifier(HorizontalEntranceModifier(delay: delay, offsetX: offsetX))
    }
}

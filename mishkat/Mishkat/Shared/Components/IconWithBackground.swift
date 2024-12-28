//
//  IconWithBackground.swift
//  Mishkat
//
//  Created by Human on 28/12/2024.
//

import SwiftUI

struct IconWithBackground: View {
    private let icon: Icons
    private let iconColor: Color?
    private let backgroundColor: Color?
    private let size: CGFloat
    
    init(icon: Icons, size: CGFloat = 60, iconColor: Color? = nil, backgroundColor: Color? = nil) {
        self.icon = icon
        self.size = size
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: size)
                .foregroundStyle(backgroundColor ?? .lightGray)
            Image(icon)
                .resizable()
                .frame(width: size / 2, height: size / 2)
                .foregroundStyle(iconColor ?? .secondary)
        }
    }
}

//
//  DayButton.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import SwiftUI

struct DayButton: View {
    let date: Date
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayOfWeek(from: date))
                .font(.system(size: 12))
            Text(dayOfMonth(from: date))
                .font(.system(size: 20, weight: .medium))
        }
        .foregroundColor(isSelected ? .white : .primary)
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayOfMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

#Preview {
    DayButton(date: Date(), isSelected: true)
}

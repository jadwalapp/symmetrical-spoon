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
                .overlay(
                    Circle()
                        .stroke(isToday(date) && !isSelected ? .green : .clear, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                )
        }
        .foregroundColor(isSelected ? .white : (isToday(date) ? .green : .primary))
    }
    
    private func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
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
    HStack {
        DayButton(date: Date(), isSelected: false)
        DayButton(date: Date(), isSelected: true)
        DayButton(date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, isSelected: false)
    }
}

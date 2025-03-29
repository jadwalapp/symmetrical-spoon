//
//  DaySelector.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import SwiftUI

struct DaySelector: View {
    @Binding var selectedDate: Date
    let dateRange: [Date]
    @State private var dragOffset: CGFloat = 0
    @State private var currentDateRange: [Date]
    
    init(selectedDate: Binding<Date>, dateRange: [Date]) {
        self._selectedDate = selectedDate
        self.dateRange = dateRange
        self._currentDateRange = State(initialValue: dateRange)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let itemWidth = geometry.size.width / 7
            
            ZStack {
                // Background highlight circle
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: itemWidth - 8, height: itemWidth - 8)
                    .offset(x: CGFloat(currentDateRange.firstIndex(of: selectedDate) ?? 0) * itemWidth - geometry.size.width / 2 + itemWidth / 2)
                
                HStack(spacing: 0) {
                    ForEach(currentDateRange, id: \.self) { date in
                        DayButton(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                            .frame(width: itemWidth)
                            .onTapGesture {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                withAnimation(.spring()) {
                                    selectedDate = date
                                }
                            }
                    }
                }
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            dragOffset = 0
                            
                            if value.translation.width > threshold {
                                // Swipe right - go to previous week
                                withAnimation {
                                    if let firstDate = currentDateRange.first {
                                        let calendar = Calendar.current
                                        let newStartDate = calendar.date(byAdding: .day, value: -7, to: firstDate) ?? firstDate
                                        currentDateRange = (-3...3).compactMap { offset in
                                            calendar.date(byAdding: .day, value: offset, to: newStartDate)
                                        }
                                        selectedDate = newStartDate
                                    }
                                }
                            } else if value.translation.width < -threshold {
                                // Swipe left - go to next week
                                withAnimation {
                                    if let lastDate = currentDateRange.last {
                                        let calendar = Calendar.current
                                        let newEndDate = calendar.date(byAdding: .day, value: 7, to: lastDate) ?? lastDate
                                        let newStartDate = calendar.date(byAdding: .day, value: -6, to: newEndDate) ?? newEndDate
                                        currentDateRange = (-3...3).compactMap { offset in
                                            calendar.date(byAdding: .day, value: offset, to: newStartDate)
                                        }
                                        selectedDate = newStartDate
                                    }
                                }
                            }
                        }
                )
            }
        }
        .frame(height: 70)
        .clipped()
    }
}

#Preview {
    DaySelector(selectedDate: .constant(Date()), dateRange: Array(0..<7).map { _ in Date() })
}

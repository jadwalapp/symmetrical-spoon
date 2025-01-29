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
    
    var body: some View {
        GeometryReader { geometry in
            let itemWidth = geometry.size.width / 7
            
            ZStack {
                // Background highlight circle
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: itemWidth - 8, height: itemWidth - 8)
                    .offset(x: CGFloat(dateRange.firstIndex(of: selectedDate)!) * itemWidth - geometry.size.width / 2 + itemWidth / 2)
                
                HStack(spacing: 0) {
                    ForEach(dateRange, id: \.self) { date in
                        DayButton(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                            .frame(width: itemWidth)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedDate = date
                                }
                            }
                    }
                }
            }
        }
        .frame(height: 70)
        .clipped()
    }
}

#Preview {
    DaySelector(selectedDate: .constant(Date()), dateRange: Array(0..<7).map { _ in Date() })
}

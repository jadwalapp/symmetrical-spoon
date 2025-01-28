//
//  DayView.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import SwiftUI

/// View for displaying the daily events.
struct DayView: View {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var isMonthView: Bool
    var animation: Namespace.ID
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            DaySelector(selectedDate: $selectedDate, dateRange: generateDateRange())
                .matchedGeometryEffect(id: "calendar", in: animation)
                .padding(.vertical, 8)
            
            List {
                ForEach(viewModel.dailyEvents, id: \.eventIdentifier) { event in
                    EventRow(event: event)
                }
            }
            .listStyle(PlainListStyle())
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                    } else if value.translation.width < -threshold {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                    }
                    dragOffset = 0
                }
        )
        .animation(.spring(), value: selectedDate)
        .onChange(of: selectedDate) { newDate in
            viewModel.fetchDailyEvents(for: newDate)
        }
    }
    
    private func generateDateRange() -> [Date] {
        let calendar = Calendar.current
        return (-3...3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: selectedDate)
        }
    }
}

#Preview {
    DayView(selectedDate: .constant(Date()), viewModel: CalendarViewModel(), isMonthView: .constant(false), animation: Namespace().wrappedValue)
}

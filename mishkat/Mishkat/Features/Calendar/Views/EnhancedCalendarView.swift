//
//  EnhancedCalendarView.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import SwiftUI

struct EnhancedCalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Binding var isMonthView: Bool
    @Namespace private var animation
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            if isMonthView {
                MonthView(selectedDate: $viewModel.selectedDate, viewModel: viewModel, isMonthView: $isMonthView, animation: animation)
                    .onChange(of: currentMonth) { newMonth in
                        viewModel.fetchMonthlyEvents(for: newMonth, forceRefresh: true)
                    }
                    .onChange(of: viewModel.monthlyEvents) { _ in
                        // Trigger a notification to update decorations when events change
                        NotificationCenter.default.post(name: NSNotification.Name("MonthlyEventsUpdated"), object: nil)
                    }
                    .onAppear {
                        viewModel.fetchMonthlyEvents(for: currentMonth, forceRefresh: true)
                    }
                    .transition(
                        AnyTransition.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.05)).animation(.spring(response: 0.3, dampingFraction: 0.7)),
                            removal: .opacity.animation(.easeOut(duration: 0.2))
                        )
                    )
            } else {
                DayView(selectedDate: $viewModel.selectedDate, viewModel: viewModel, isMonthView: $isMonthView, animation: animation)
                    .transition(
                        AnyTransition.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).animation(.spring(response: 0.3, dampingFraction: 0.7)),
                            removal: .opacity.animation(.easeOut(duration: 0.2))
                        )
                    )
            }
        }
        .onChange(of: viewModel.selectedDate) { newDate in
            let calendar = Calendar.current
            let selectedMonth = calendar.startOfMonth(for: newDate)
            if !calendar.isDate(currentMonth, equalTo: selectedMonth, toGranularity: .month) {
                currentMonth = selectedMonth
            }
            
            if isMonthView {
                viewModel.fetchMonthlyEvents(for: newDate)
            } else {
                viewModel.fetchDailyEvents(for: newDate)
            }
        }
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview {
    EnhancedCalendarView(isMonthView: .constant(true))
        .environmentObject(CalendarViewModel())
}

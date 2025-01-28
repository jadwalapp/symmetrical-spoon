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
    
    var body: some View {
        VStack(spacing: 0) {
            if isMonthView {
                MonthView(selectedDate: $viewModel.selectedDate, viewModel: viewModel, isMonthView: $isMonthView, animation: animation)
                    .onAppear {
                        viewModel.fetchMonthlyEvents(for: viewModel.selectedDate)
                    }
                    .transition(.opacity)
            } else {
                DayView(selectedDate: $viewModel.selectedDate, viewModel: viewModel, isMonthView: $isMonthView, animation: animation)
                    .transition(.opacity)
            }
        }
        .onChange(of: viewModel.selectedDate) { newDate in
            if isMonthView {
                viewModel.fetchMonthlyEvents(for: newDate)
            } else {
                viewModel.fetchDailyEvents(for: newDate)
            }
        }
    }
}

#Preview {
    EnhancedCalendarView(isMonthView: .constant(true))
        .environmentObject(CalendarViewModel())
}

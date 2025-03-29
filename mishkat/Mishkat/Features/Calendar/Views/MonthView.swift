//
//  MonthView.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import SwiftUI

struct MonthView: View {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var isMonthView: Bool
    var animation: Namespace.ID
    
    var body: some View {
        MonthCalendar(selectedDate: $selectedDate, viewModel: viewModel, isMonthView: $isMonthView, animation: animation)
            .matchedGeometryEffect(id: "calendar", in: animation)
    }
}

#Preview {
    MonthView(selectedDate: .constant(Date()), viewModel: CalendarViewModel(), isMonthView: .constant(true), animation: Namespace().wrappedValue)
}

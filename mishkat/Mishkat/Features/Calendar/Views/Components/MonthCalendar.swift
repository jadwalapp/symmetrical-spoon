//
//  MonthCalendar.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import SwiftUI
import EventKit

struct MonthCalendar: UIViewRepresentable {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var isMonthView: Bool
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar(identifier: .gregorian)
        calendarView.availableDateRange = DateInterval(start: .distantPast, end: .distantFuture)
        calendarView.delegate = context.coordinator
        
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = dateSelection
        
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.updateEvents(viewModel.monthlyEvents)
        uiView.reloadDecorations(forDateComponents: [], animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: MonthCalendar
        var events: [EKEvent] = []
        
        init(_ parent: MonthCalendar) {
            self.parent = parent
        }
        
        func updateEvents(_ newEvents: [EKEvent]) {
            self.events = newEvents
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents = dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            parent.selectedDate = date
            withAnimation(.easeInOut(duration: 0.3)) {
                parent.isMonthView = false
            }
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            let eventsForDate = events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
            if !eventsForDate.isEmpty {
                return .customView {
                    let view = UILabel()
                    view.text = "🟢"
                    return view
                }
            }
            return nil
        }
    }
}

#Preview {
    MonthCalendar(selectedDate: .constant(Date()), viewModel: CalendarViewModel(), isMonthView: .constant(true))
}

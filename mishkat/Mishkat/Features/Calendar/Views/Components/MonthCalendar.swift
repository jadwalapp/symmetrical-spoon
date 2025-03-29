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
    var animation: Namespace.ID
    
    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.delegate = context.coordinator
        view.calendar = Calendar.current
        view.locale = .current
        view.fontDesign = .rounded
        view.backgroundColor = .clear
        
        // Configure selection behavior
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = dateSelection
        
        return view
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // Update visible date range
        let calendar = Calendar.current
        let visibleDateComponents = calendar.dateComponents([.year, .month], from: selectedDate)
        uiView.visibleDateComponents = visibleDateComponents
        
        // Update event decorations
        context.coordinator.updateDecorations(for: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: MonthCalendar
        private var decoratedDates: Set<DateComponents> = []
        
        init(_ parent: MonthCalendar) {
            self.parent = parent
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard decoratedDates.contains(dateComponents) else { return nil }
            
            // Create a custom view decoration
            return .customView { [weak self] in
                let view = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 4))
                view.backgroundColor = .systemGreen
                view.layer.cornerRadius = 2
                return view
            }
        }
        
        func updateDecorations(for calendarView: UICalendarView) {
            let calendar = Calendar.current
            guard let visibleMonth = calendar.date(from: calendarView.visibleDateComponents),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth)),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                return
            }
            
            // Get all dates with events
            let datesWithEvents = parent.viewModel.monthlyEvents.compactMap { event -> DateComponents? in
                let date = event.startDate ?? Date()
                guard date >= startOfMonth && date <= endOfMonth else { return nil }
                return calendar.dateComponents([.year, .month, .day], from: date)
            }
            
            decoratedDates = Set(datesWithEvents)
            calendarView.reloadDecorations(forDateComponents: Array(decoratedDates), animated: true)
        }
        
        // UICalendarSelectionSingleDateDelegate
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents = dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            
            withAnimation {
                parent.selectedDate = date
                parent.isMonthView = false
            }
        }
        
        // UICalendarViewDelegate
        func calendarView(_ calendarView: UICalendarView, didChangeVisibleDateComponentsFrom previousDateComponents: DateComponents) {
            guard let date = Calendar.current.date(from: calendarView.visibleDateComponents) else { return }
            parent.viewModel.fetchMonthlyEvents(for: date)
        }
    }
}

struct MonthCalendarPreview: View {
    @Namespace var animation
    
    var body: some View {
        MonthCalendar(
            selectedDate: .constant(Date()),
            viewModel: CalendarViewModel(),
            isMonthView: .constant(true),
            animation: animation
        )
    }
}

#Preview {
    MonthCalendarPreview()
}

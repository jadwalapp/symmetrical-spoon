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
        
        // Initial decoration update
        context.coordinator.updateDecorations(for: view)
        
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
        private var calendarReference: UICalendarView?
        
        init(_ parent: MonthCalendar) {
            self.parent = parent
            super.init()
            
            // Listen for event updates
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleEventsUpdated),
                name: NSNotification.Name("MonthlyEventsUpdated"),
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func handleEventsUpdated() {
            if let calendarView = calendarReference {
                updateDecorations(for: calendarView)
            }
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            // Check if there's an event on this date by comparing only year, month, day components
            let exists = decoratedDates.contains { components in
                return components.year == dateComponents.year &&
                       components.month == dateComponents.month &&
                       components.day == dateComponents.day
            }
            
            if exists {
                return .customView {
                    let view = UILabel()
                    view.text = "🟢"
                    return view
                }
            }
            
            return nil
        }
        
        func updateDecorations(for calendarView: UICalendarView) {
            // Store reference to calendar view for later updates
            calendarReference = calendarView
            
            let calendar = Calendar.current
            guard let visibleMonth = calendar.date(from: calendarView.visibleDateComponents),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth)),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                print("⚠️ Calendar: Failed to calculate month range")
                return
            }
            
            // Get all dates with events
            let datesWithEvents = parent.viewModel.monthlyEvents.compactMap { event -> DateComponents? in
                guard let startDate = event.startDate else {
                    print("⚠️ Calendar: Event without start date:", event.title ?? "Untitled")
                    return nil
                }
                
                guard startDate >= startOfMonth && startDate <= endOfMonth else { return nil }
                // Only include year, month, day components for consistent comparison
                return calendar.dateComponents([.year, .month, .day], from: startDate)
            }
            
            if datesWithEvents.isEmpty {
                print("ℹ️ Calendar: No events found for month:", calendar.component(.month, from: visibleMonth))
            } else {
                print("✅ Calendar: Found \(datesWithEvents.count) events for month:", calendar.component(.month, from: visibleMonth))
                // Debug to make sure we're getting proper components
                datesWithEvents.forEach { components in
                    print("📆 Event on: \(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)")
                }
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
            
            // Update the selectedDate to the first day of the newly visible month
            let calendar = Calendar.current
            if let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) {
                // Only update if we're actually changing months to avoid disrupting day selection
                if !calendar.isDate(parent.selectedDate, equalTo: date, toGranularity: .month) {
                    withAnimation {
                        parent.selectedDate = firstDayOfMonth
                    }
                }
            }
            
            // Force refresh when changing months
            parent.viewModel.fetchMonthlyEvents(for: date, forceRefresh: true)
            
            // Update decorations after a short delay to ensure events have been fetched
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.updateDecorations(for: calendarView)
            }
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

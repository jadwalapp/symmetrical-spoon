//
//  EnhancedCalendarView.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import SwiftUI
import EventKit

struct EnhancedCalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var isMonthView = true
    
    var body: some View {
        VStack(spacing: 0) {
            if isMonthView {
                MonthView(selectedDate: $viewModel.selectedDate, viewModel: viewModel, isMonthView: $isMonthView)
            } else {
                DayView(selectedDate: $viewModel.selectedDate, events: viewModel.events, isMonthView: $isMonthView)
            }
        }
        .onChange(of: viewModel.selectedDate) { newDate in
            viewModel.fetchEvents(for: newDate)
        }
    }
}

struct MonthView: View {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var isMonthView: Bool
    
    var body: some View {
        VStack {
            MonthCalendar(selectedDate: $selectedDate, viewModel: viewModel)
                .frame(height: UIScreen.main.bounds.height * 0.7)
            
            Button("View Day") {
                isMonthView = false
            }
            .padding()
        }
    }
}

struct DayView: View {
    @Binding var selectedDate: Date
    let events: [EKEvent]
    @Binding var isMonthView: Bool
    
    var body: some View {
        VStack {
            WeekdayHeader(selectedDate: $selectedDate)
            
            List {
                ForEach(events, id: \.eventIdentifier) { event in
                    EventRow(event: event)
                }
            }
        }
        .navigationBarItems(trailing: Button("Month") {
            isMonthView = true
        })
    }
}

struct WeekdayHeader: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack {
            ForEach(-3...3, id: \.self) { offset in
                let date = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate)!
                VStack {
                    Text(dayOfWeek(for: date))
                        .font(.caption)
                    Text(String(Calendar.current.component(.day, from: date)))
                        .font(.headline)
                        .foregroundColor(offset == 0 ? .accentColor : .primary)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    selectedDate = date
                }
            }
        }
        .padding()
    }
    
    func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(event.calendar.cgColor))
                .frame(width: 4)
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                Text(timeRangeString(for: event))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    func timeRangeString(for event: EKEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
}

struct MonthCalendar: UIViewRepresentable {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: CalendarViewModel
    
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
        context.coordinator.updateEvents(viewModel.events)
        uiView.reloadDecorations(forDateComponents: [], animated: false)
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
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            
            let eventsForDate = events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
            
            if !eventsForDate.isEmpty {
                return .customView {
                    let view = UIView()
                    view.backgroundColor = .clear
                    
                    let stackView = UIStackView()
                    stackView.axis = .horizontal
                    stackView.distribution = .fillEqually
                    stackView.spacing = 2
                    stackView.translatesAutoresizingMaskIntoConstraints = false
                    view.addSubview(stackView)
                    
                    NSLayoutConstraint.activate([
                        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                        stackView.heightAnchor.constraint(equalToConstant: 4)
                    ])
                    
                    for event in eventsForDate.prefix(3) {
                        let dot = UIView()
                        dot.backgroundColor = UIColor(cgColor: event.calendar.cgColor)
                        dot.layer.cornerRadius = 2
                        stackView.addArrangedSubview(dot)
                    }
                    
                    return view
                }
            }
            
            return nil
        }
    }
}



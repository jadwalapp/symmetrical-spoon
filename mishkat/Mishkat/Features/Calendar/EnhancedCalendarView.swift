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
    @Binding var isMonthView: Bool
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 0) {
            if isMonthView {
                MonthView(selectedDate: $viewModel.selectedDate, viewModel: viewModel, isMonthView: $isMonthView, animation: animation)
                    .transition(.opacity)
            } else {
                DayView(selectedDate: $viewModel.selectedDate, viewModel: viewModel, isMonthView: $isMonthView, animation: animation)
                    .transition(.opacity)
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
    var animation: Namespace.ID
    
    var body: some View {
        MonthCalendar(selectedDate: $selectedDate, viewModel: viewModel, isMonthView: $isMonthView)
            .matchedGeometryEffect(id: "calendar", in: animation)
    }
}

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
                ForEach(viewModel.events, id: \.eventIdentifier) { event in
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
            viewModel.fetchEvents(for: newDate)
        }
    }
    
    private func generateDateRange() -> [Date] {
        let calendar = Calendar.current
        return (-3...3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: selectedDate)
        }
    }
}


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


struct DayButton: View {
    let date: Date
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayOfWeek(from: date))
                .font(.system(size: 12))
            Text(dayOfMonth(from: date))
                .font(.system(size: 20, weight: .medium))
        }
        .foregroundColor(isSelected ? .white : .primary)
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayOfMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
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
            withAnimation(.easeInOut(duration: 0.3)) {
                parent.isMonthView = false
            }
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

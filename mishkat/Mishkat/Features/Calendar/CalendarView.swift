//
//  CalendarView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import EventKit

struct CalendarView: View {
    @State private var selectedDate: DateComponents?
    @State private var displayEvents = false
    @State private var showingAddEventSheet = false
    @State private var showingCalendarsSheet = false
    @EnvironmentObject var calendarViewModel: CalendarViewModel

    var body: some View {
        NavigationStack {
            VStack {
                CalendarViewRepresentable(
                    selectedDate: $selectedDate,
                    displayEvents: $displayEvents
                )
                
                if displayEvents, let date = selectedDate?.date {
                    EventsListView(events: calendarViewModel.fetchEvents(for: date))
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingCalendarsSheet.toggle()
                        } label: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.primary)
                        }
                        
                        Button {
                            showingAddEventSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventView(
                    isPresented: $showingAddEventSheet,
                    selectedDate: selectedDate
                ).environmentObject(calendarViewModel)
            }
            .sheet(isPresented: $showingCalendarsSheet) {
                CalendarsListView(sources: calendarViewModel.fetchCalendarSources())
            }
            .onAppear {
                calendarViewModel.requestAccess()
            }
        }
    }
}

struct EventsListView: View {
    let events: [EKEvent]
    
    var body: some View {
        List(events, id: \.eventIdentifier) { event in
            VStack(alignment: .leading) {
                Text(event.title)
                Text("\(event.startDate, formatter: dateFormatter) - \(event.endDate, formatter: dateFormatter)")
                    .font(.caption)
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct CalendarsListView: View {
    let sources: [EKSource]
    
    var body: some View {
        NavigationView {
            List(sources, id: \.sourceIdentifier) { source in
                Section(header: Text(source.title)) {
                    ForEach(Array(source.calendars(for: .event)), id: \.calendarIdentifier) { calendar in
                        Text(calendar.title)
                    }
                }
            }
            .navigationTitle("Calendars")
        }
    }
}

struct CalendarViewRepresentable: UIViewRepresentable {
    @Binding var selectedDate: DateComponents?
    @Binding var displayEvents: Bool
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.delegate = context.coordinator
        calendarView.calendar = Calendar(identifier: .gregorian)
        
        calendarView.tintColor = .accent
        calendarView.availableDateRange = DateInterval(start: .distantPast, end: .distantFuture)
        
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = dateSelection
        
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarViewRepresentable
        
        init(parent: CalendarViewRepresentable) {
            self.parent = parent
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            parent.selectedDate = dateComponents
            parent.displayEvents = true
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            return nil
        }
    }
}

#Preview {
    CalendarView()
}

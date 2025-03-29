//
//  DayView.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import SwiftUI
import EventKit
import EventKitUI

/// View for displaying the daily events.
struct DayView: View {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var isMonthView: Bool
    var animation: Namespace.ID
    @State private var dragOffset: CGFloat = 0
    @State private var selectedEvent: EKEvent?
    @State private var showingEventEditor = false
    
    private var allDayEvents: [EKEvent] {
        viewModel.dailyEvents.filter { $0.isAllDay }
    }
    
    private var timedEvents: [EKEvent] {
        viewModel.dailyEvents.filter { !$0.isAllDay }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DaySelector(selectedDate: $selectedDate, dateRange: generateDateRange())
                .matchedGeometryEffect(id: "calendar", in: animation)
                .padding(.vertical, 8)
            
            ScrollView {
                VStack(spacing: 0) {
                    if !allDayEvents.isEmpty {
                        AllDayEventsSection(events: allDayEvents) { event in
                            selectedEvent = event
                            showingEventEditor = true
                        }
                    }
                    
                    TimelineView(events: timedEvents) { event in
                        selectedEvent = event
                        showingEventEditor = true
                    }
                }
                .padding(.horizontal)
            }
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
        .sheet(isPresented: $showingEventEditor) {
            if let event = selectedEvent {
                AddEventView(isPresented: $showingEventEditor, event: event)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    private func generateDateRange() -> [Date] {
        let calendar = Calendar.current
        return (-3...3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: selectedDate)
        }
    }
}

struct AllDayEventsSection: View {
    let events: [EKEvent]
    let onEventTap: (EKEvent) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All-Day")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 50)
            
            ForEach(events, id: \.eventIdentifier) { event in
                Button {
                    onEventTap(event)
                } label: {
                    HStack {
                        Rectangle()
                            .fill(Color(event.calendar.cgColor))
                            .frame(width: 4)
                        
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let location = event.location, !location.isEmpty {
                                Text(location)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(event.calendar.cgColor).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 16)
    }
}

struct TimelineView: View {
    let events: [EKEvent]
    let onEventTap: (EKEvent) -> Void
    private let hourHeight: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hour lines
            VStack(spacing: 0) {
                ForEach(0..<24) { hour in
                    HourRow(hour: hour, height: hourHeight)
                }
            }
            
            // Events
            ForEach(groupedEvents.keys.sorted(), id: \.self) { hour in
                if let hourEvents = groupedEvents[hour] {
                    EventsRow(
                        hour: hour,
                        events: hourEvents,
                        hourHeight: hourHeight,
                        onEventTap: onEventTap
                    )
                }
            }
        }
    }
    
    private var groupedEvents: [Int: [EKEvent]] {
        Dictionary(grouping: events) { event in
            Calendar.current.component(.hour, from: event.startDate)
        }
    }
}

struct HourRow: View {
    let hour: Int
    let height: CGFloat
    
    var body: some View {
        HStack(spacing: 8) {
            Text(timeString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
        }
        .frame(height: height)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(from: DateComponents(hour: hour)) ?? Date()
        return formatter.string(from: date)
    }
}

struct EventsRow: View {
    let hour: Int
    let events: [EKEvent]
    let hourHeight: CGFloat
    let onEventTap: (EKEvent) -> Void
    
    var body: some View {
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        let groups = calculateOverlappingGroups(sortedEvents)
        
        ForEach(groups.indices, id: \.self) { groupIndex in
            let group = groups[groupIndex]
            HStack(spacing: 2) {
                ForEach(group, id: \.eventIdentifier) { event in
                    EventView(event: event, hourHeight: hourHeight)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            onEventTap(event)
                        }
                }
            }
            .padding(.leading, 50)  // Space for time labels
        }
    }
    
    private func calculateOverlappingGroups(_ events: [EKEvent]) -> [[EKEvent]] {
        var groups: [[EKEvent]] = []
        var currentGroup: [EKEvent] = []
        
        for event in events {
            if currentGroup.isEmpty {
                currentGroup.append(event)
            } else if eventsOverlap(currentGroup.last!, event) {
                currentGroup.append(event)
            } else {
                groups.append(currentGroup)
                currentGroup = [event]
            }
        }
        
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    private func eventsOverlap(_ event1: EKEvent, _ event2: EKEvent) -> Bool {
        event1.endDate > event2.startDate && event2.endDate > event1.startDate
    }
}

struct EventView: View {
    let event: EKEvent
    let hourHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.caption)
                .bold()
                .lineLimit(1)
            
            if let location = event.location, !location.isEmpty {
                Text(location)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(event.calendar.cgColor).opacity(0.2))
        .overlay(
            Rectangle()
                .fill(Color(event.calendar.cgColor))
                .frame(width: 4)
                .clipped(),
            alignment: .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .frame(height: eventHeight)
        .offset(y: yOffset)
    }
    
    private var eventHeight: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        return max(hourHeight * CGFloat(duration / 3600), 30)
    }
    
    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: event.startDate)
        let startMinute = calendar.component(.minute, from: event.startDate)
        return CGFloat(startMinute) / 60.0 * hourHeight + CGFloat(startHour) * hourHeight
    }
}

#Preview {
    DayView(selectedDate: .constant(Date()), viewModel: CalendarViewModel(), isMonthView: .constant(false), animation: Namespace().wrappedValue)
}

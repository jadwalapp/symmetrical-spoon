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
                    
                    if timedEvents.isEmpty && allDayEvents.isEmpty {
                        VStack(spacing: 20) {
                            Spacer(minLength: 100)
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary.opacity(0.7))
                            
                            Text("No Events")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            Button {
                                showingEventEditor = true
                                selectedEvent = nil  // Ensure we're creating a new event, not editing
                            } label: {
                                Text("Add Event")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        TimelineView(eventWrappers: generateEventWrappers(timedEvents), onEventTap: { event in
                            selectedEvent = event
                            showingEventEditor = true
                        })
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
            } else {
                AddEventView(isPresented: $showingEventEditor)
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
    
    private func generateEventWrappers(_ events: [EKEvent]) -> [EventWrapper] {
        events.map { EventWrapper(event: $0) }
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
    let eventWrappers: [EventWrapper]
    let onEventTap: (EKEvent) -> Void
    private let hourHeight: CGFloat = 60
    
    private var events: [EKEvent] {
        eventWrappers.map { $0.event }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hour lines
            VStack(spacing: 0) {
                ForEach(0..<24) { hour in
                    HourRow(hour: hour, height: hourHeight)
                }
            }
            
            // Events
            ForEach(groupedEventWrappers.keys.sorted(), id: \.self) { hour in
                if let hourWrappers = groupedEventWrappers[hour] {
                    EventsRow(
                        hour: hour,
                        eventWrappers: hourWrappers,
                        hourHeight: hourHeight,
                        onEventTap: onEventTap
                    )
                }
            }
        }
    }
    
    private var groupedEventWrappers: [Int: [EventWrapper]] {
        Dictionary(grouping: eventWrappers) { wrapper in
            Calendar.current.component(.hour, from: wrapper.event.startDate)
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
    let eventWrappers: [EventWrapper]
    let hourHeight: CGFloat
    let onEventTap: (EKEvent) -> Void
    
    private var events: [EKEvent] {
        eventWrappers.map { $0.event }
    }
    
    var body: some View {
        let sortedWrappers = eventWrappers.sorted { $0.event.startDate < $1.event.startDate }
        let groups = calculateOverlappingGroups(sortedWrappers)
        
        ForEach(groups.indices, id: \.self) { groupIndex in
            let group = groups[groupIndex]
            HStack(spacing: 2) {
                ForEach(group, id: \.id) { wrapper in
                    EventView(eventWrapper: wrapper, hourHeight: hourHeight)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            onEventTap(wrapper.event)
                        }
                }
            }
            .padding(.leading, 50)  // Space for time labels
        }
    }
    
    private func calculateOverlappingGroups(_ wrappers: [EventWrapper]) -> [[EventWrapper]] {
        var groups: [[EventWrapper]] = []
        var currentGroup: [EventWrapper] = []
        
        for wrapper in wrappers {
            if currentGroup.isEmpty {
                currentGroup.append(wrapper)
            } else if eventsOverlap(currentGroup.last!.event, wrapper.event) {
                currentGroup.append(wrapper)
            } else {
                groups.append(currentGroup)
                currentGroup = [wrapper]
            }
        }
        
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    private func eventsOverlap(_ event1: EKEvent, _ event2: EKEvent) -> Bool {
        guard let start1 = event1.startDate, let end1 = event1.endDate,
              let start2 = event2.startDate, let end2 = event2.endDate else {
            return false // Cannot determine overlap if dates are missing
        }
        // Standard overlap logic: (StartA < EndB) and (StartB < EndA)
        return start1 < end2 && start2 < end1
    }
}

struct EventView: View {
    let eventWrapper: EventWrapper
    let hourHeight: CGFloat
    
    private var event: EKEvent { eventWrapper.event }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title ?? "Untitled Event")
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
        .background((event.calendar != nil ? Color(event.calendar.cgColor) : Color.gray).opacity(0.2))
        .overlay(
            Rectangle()
                .fill(event.calendar != nil ? Color(event.calendar.cgColor) : Color.gray)
                .frame(width: 4)
                .clipped(),
            alignment: .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .frame(height: eventHeight)
        .offset(y: yOffset)
    }
    
    private var eventHeight: CGFloat {
        guard let startDate = event.startDate, let endDate = event.endDate else { return 30 } // Default height
        let duration = endDate.timeIntervalSince(startDate)
        // Ensure non-negative duration for height calculation
        return max(hourHeight * CGFloat(max(0, duration) / 3600), 30) // Minimum height 30
    }
    
    private var yOffset: CGFloat {
        guard let startDate = event.startDate else { return 0 } // Default offset
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startDate)
        let startMinute = calendar.component(.minute, from: startDate)
        // Calculate offset based on the start time within the day
        return CGFloat(startMinute) / 60.0 * hourHeight + CGFloat(startHour) * hourHeight
    }
}

#Preview {
    DayView(selectedDate: .constant(Date()), viewModel: CalendarViewModel(), isMonthView: .constant(false), animation: Namespace().wrappedValue)
}

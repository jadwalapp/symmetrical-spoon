//
//  ConflictTimelineView.swift
//  Mishkat
//
//  Created by Human on 01/10/2024.
//

import SwiftUI
import EventKit

// Wrapper to provide a stable ID for EKEvent instances, especially temporary ones
struct EventWrapper: Identifiable {
    let id = UUID()
    let event: EKEvent
}

/// A timeline view specifically for displaying conflicts between calendar events
/// This component leverages existing calendar UI components for consistency
struct ConflictTimelineView: View {
    let newEventInfo: Conflict.EventInfo
    let existingEventsInfo: [Conflict.EventInfo]
    @Binding var proposedNewDate: Date
    let isMovingEvent: Bool
    let selectedResolution: Conflict.ConflictResolution?
    @EnvironmentObject var viewModel: CalendarViewModel
    
    // Convert Conflict.EventInfo to EventWrapper for the timeline view
    func convertToEventWrappers(_ eventInfos: [Conflict.EventInfo], shouldIncludeNew: Bool) -> [EventWrapper] {
        let filteredInfos = eventInfos.filter { info in
            // Filter out the "new" event if it should be hidden
            if case .deleteEvent = selectedResolution, info.isNew {
                return false
            }
            // In the original day preview when moving, remove the original event
            if isMovingEvent && info.isNew && !shouldIncludeNew {
                return false
            }
            return true
        }
        
        return filteredInfos.compactMap { info -> EventWrapper? in
            let event = EKEvent(eventStore: viewModel.eventStore)
            event.title = info.title
            
            // Determine start date: Use proposed date if moving the new event AND we should include it in this view
            let useProposedDate = info.isNew && isMovingEvent && shouldIncludeNew
            event.startDate = useProposedDate ? proposedNewDate : info.startDate
            
            // Calculate end date based on original duration if we're moving the event
            if useProposedDate {
                let originalDuration = info.endDate.timeIntervalSince(info.startDate)
                event.endDate = proposedNewDate.addingTimeInterval(originalDuration)
            } else {
                event.endDate = info.endDate
            }
            
            // Try to find a matching calendar or use default
            if let calendarName = info.calendarName {
                let allCalendars = viewModel.eventStore.calendars(for: .event)
                event.calendar = allCalendars.first(where: { $0.title == calendarName }) ?? 
                                viewModel.eventStore.defaultCalendarForNewEvents ?? allCalendars.first!
            } else {
                event.calendar = viewModel.eventStore.defaultCalendarForNewEvents ?? 
                                viewModel.eventStore.calendars(for: .event).first!
            }
            
            // Mark "new" events with a special color for clarity
            if info.isNew {
                // Use a bright or highlighted color different from existing colors
                event.calendar = createHighlightCalendar(isProposed: useProposedDate)
            }
            
            // If calendar assignment failed (shouldn't happen if store access granted)
            guard event.calendar != nil else {
                print("Warning: Could not assign a calendar to event '\(event.title ?? "Untitled")'. EventKit might not have default calendars.")
                return nil // Skip events without a calendar
            }
            
            return EventWrapper(event: event)
        }
    }
    
    // Create a special calendar for highlighting the new/proposed event
    private func createHighlightCalendar(isProposed: Bool) -> EKCalendar {
        let calendar = EKCalendar(for: .event, eventStore: viewModel.eventStore)
        calendar.title = isProposed ? "Proposed Event Time" : "New Event"
        // Use distinct system colors
        calendar.cgColor = isProposed ? UIColor.systemTeal.cgColor : UIColor.systemGreen.cgColor
        return calendar
    }
    
    // Check if the proposed date is on a different day
    private var isDifferentDay: Bool {
        !Calendar.current.isDate(proposedNewDate, inSameDayAs: newEventInfo.startDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isMovingEvent && isDifferentDay {
                // Split view for different day
                VStack(alignment: .leading, spacing: 4) {
                    Text("Comparing Original Day vs Proposed Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 2)
                    
                    HStack(spacing: 0) {
                        // Original day
                        VStack(spacing: 4) {
                            Text(formatDateHeader(newEventInfo.startDate))
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 4)
                            
                            CompactDayTimeline(
                                date: newEventInfo.startDate,
                                eventWrappers: convertToEventWrappers(existingEventsInfo + [newEventInfo], shouldIncludeNew: false)
                            )
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                        
                        // Proposed day
                        VStack(spacing: 4) {
                            Text(formatDateHeader(proposedNewDate))
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 4)
                            
                            CompactDayTimeline(
                                date: proposedNewDate,
                                // Only show the (potentially moved) new event on the proposed day
                                eventWrappers: convertToEventWrappers([newEventInfo], shouldIncludeNew: true)
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                // Single day view
                VStack(spacing: 4) {
                    Text(formatDateHeader(isMovingEvent ? proposedNewDate : newEventInfo.startDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.bottom, 4)
                    
                    CompactDayTimeline(
                        date: isMovingEvent ? proposedNewDate : newEventInfo.startDate,
                        eventWrappers: convertToEventWrappers(existingEventsInfo + [newEventInfo], shouldIncludeNew: true)
                    )
                }
            }
        }
        .padding(.vertical, 8)
        .animation(.default, value: isMovingEvent) // Animate layout changes
        .animation(.default, value: selectedResolution)
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d" // e.g., "Wed, Mar 30"
        return formatter.string(from: date)
    }
}

// A compact version of the day timeline that reuses existing timeline components
struct CompactDayTimeline: View {
    let date: Date
    let eventWrappers: [EventWrapper]
    
    // Extract EKEvents for TimelineView
    private var events: [EKEvent] {
        eventWrappers.map { $0.event }
    }
    
    // Determine visible time range based on events
    private var visibleHourRange: ClosedRange<Int> {
        guard !events.isEmpty else { return 8...17 } // Default 8am-5pm if no events
        
        let calendar = Calendar.current
        let allHours = events.flatMap { event -> [Int] in
            guard let startDate = event.startDate, let endDate = event.endDate else { return [] }
            // Consider event duration for range calculation
            let startHour = calendar.component(.hour, from: startDate)
             // If end date is exactly on the hour, use hour - 1 unless duration is 0
            let endHourComponent = calendar.component(.hour, from: endDate)
            let endMinuteComponent = calendar.component(.minute, from: endDate)
            let endSecondComponent = calendar.component(.second, from: endDate)
            let endIsExactlyOnHour = endMinuteComponent == 0 && endSecondComponent == 0
            let endHour = (endIsExactlyOnHour && startDate != endDate) ? max(0, endHourComponent - 1) : endHourComponent
            
            return [startHour, endHour]
        }
        
        let minHour = max(0, (allHours.min() ?? 8) - 1) // One hour before earliest start
        let maxHour = min(23, (allHours.max() ?? 17) + 1) // One hour after latest end
        
        // Ensure range is valid (at least one hour)
        return minHour > maxHour ? (minHour...minHour) : (minHour...maxHour)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    // Pass the EventWrappers to TimelineView (assuming it's adapted)
                    // If TimelineView still expects [EKEvent], we pass `events` computed property
                    // We'll assume TimelineView needs adapting to EventWrapper first.
                    TimelineView(eventWrappers: eventWrappers, onEventTap: { _ in })
                        .frame(width: geometry.size.width)
                        .frame(minHeight: geometry.size.height)
                }
                .onAppear {
                    // Scroll to the first event start hour or middle of range if no events
                    let firstEventStartHour = events.first.flatMap { $0.startDate }.map { Calendar.current.component(.hour, from: $0) }
                    let targetHour = firstEventStartHour ?? (visibleHourRange.lowerBound + visibleHourRange.upperBound) / 2
                    
                    // Ensure targetHour is within the visible range before scrolling
                    let clampedTargetHour = max(visibleHourRange.lowerBound, min(visibleHourRange.upperBound, targetHour))
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Short delay for layout
                        withAnimation { // Smooth scroll
                            proxy.scrollTo(max(visibleHourRange.lowerBound, clampedTargetHour - 1), anchor: .top) // Scroll slightly above target
                        }
                    }
                }
            }
        }
    }
} 
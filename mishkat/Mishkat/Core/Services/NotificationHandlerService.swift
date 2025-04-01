//
//  NotificationHandlerService.swift
//  Mishkat
//
//  Created by Human on 01/04/2025.
//

import EventKit
import UserNotifications
import UIKit

// Placeholder for where conflict data will be managed/stored
protocol ConflictManaging {
    // Records a detected conflict.
    func recordConflict(originalEvent: EKEvent, conflictingEvents: [EKEvent]) async
    // TODO: Add methods later for retrieving/resolving conflicts (e.g., getConflicts, resolveConflict)
}

// Simple mock implementation for demonstration and initial wiring.
// Replace with your actual storage mechanism later.
class MockConflictManager: ConflictManaging {
    func recordConflict(originalEvent: EKEvent, conflictingEvents: [EKEvent]) async {
        // In a real implementation, save this info persistently (UserDefaults, CoreData, etc.)
        // and potentially update UI state or badges.
        print("--- Conflict Recorded (Mock) ---")
        print("Original Event: \(originalEvent.title ?? "N/A") (EKID: \(originalEvent.eventIdentifier ?? "N/A"))")
        conflictingEvents.forEach {
            print("  Conflicts With: \($0.title ?? "N/A") (EKID: \($0.eventIdentifier ?? "N/A"))")
        }
        print("------------------------------")

        // TODO: Implement actual storage mechanism.
        // TODO: Trigger a local notification to alert the user about the new conflict.
        //       (Use UNUserNotificationCenter to schedule a local notification)
    }
}


/// Service responsible for handling background push notifications related to calendar events,
/// finding the corresponding event in EventKit, checking for conflicts, and initiating
/// conflict recording.
@MainActor
class NotificationHandlerService {

    private let eventStore: EKEventStore
    private let conflictManager: ConflictManaging

    // Dependency Injection allows for easier testing by providing mock objects.
    init(eventStore: EKEventStore = EKEventStore(), conflictManager: ConflictManaging = MockConflictManager()) {
        self.eventStore = eventStore
        self.conflictManager = conflictManager
    }

    /// Entry point for handling a received remote notification in the background.
    /// - Parameter userInfo: The dictionary received from the push notification.
    /// - Returns: The result indicating whether new data was processed.
    func handleBackgroundNotification(_ userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        // 1. Parse and validate the incoming payload
        guard let parsedInfo = parseUserInfo(userInfo) else {
            // Logging handled within parseUserInfo
            return .failed
        }

        log(.info, "Handling background notification for event UID: \(parsedInfo.uid)")
        log(.debug, "  Title: \(parsedInfo.title)")
        log(.debug, "  Start: \(parsedInfo.startDate)")
        log(.debug, "  End: \(parsedInfo.endDate)")
        if let name = parsedInfo.calendarName { log(.debug, "  Calendar Name Hint: \(name)") }

        // 2. Ensure we have calendar access permission
        guard await checkCalendarAuthorization() else {
            // Logging handled within checkCalendarAuthorization
            return .failed // Cannot proceed without authorization
        }

        // 3. Find the specific EKEvent corresponding to the notification details
        guard let foundEvent = await findMatchingEvent(using: parsedInfo) else {
            // Logging handled within findMatchingEvent
            // Event not found or ambiguity detected. Treat as no new data to process for *this* event.
            return .noData
        }

        // 4. Perform the conflict check using the reliably identified EKEvent
        let conflicts = findConflicts(for: foundEvent)

        if conflicts.isEmpty {
            log(.info, "No conflicts found for event '\(foundEvent.title ?? "N/A")' (EKID: \(foundEvent.eventIdentifier ?? "N/A")).")
            // Optional: Could clear any previously stored conflict state for this event UID/EKID here.
            return .newData // Processed successfully, no conflicts found
        } else {
            log(.warn, "Conflict detected for event '\(foundEvent.title ?? "N/A")' (EKID: \(foundEvent.eventIdentifier ?? "N/A"))!")

            // Record the conflict details using the injected ConflictManager
            await conflictManager.recordConflict(originalEvent: foundEvent, conflictingEvents: conflicts)

            // TODO: Trigger a user-visible local notification to inform about the new conflict.
            // This makes the background work actionable for the user.

            return .newData // Processed successfully, conflicts found and recorded
        }
    }

    // MARK: - Private Helper Methods

    /// Parses the userInfo dictionary, extracting and validating required event details.
    private func parseUserInfo(_ userInfo: [AnyHashable: Any]) -> ParsedEventInfo? {
        guard let eventUID = userInfo["event_uid"] as? String,
              let eventTitle = userInfo["event_title"] as? String,
              let eventStartString = userInfo["event_start"] as? String,
              let eventEndString = userInfo["event_end"] as? String
        else {
            log(.error, "Received background notification without required event details (uid, title, start, end). Payload: \(userInfo)")
            return nil
        }

        let calendarName = userInfo["calendar_name"] as? String

        // Use a helper for robust date parsing from ISO8601 strings
        guard let startDate = parseDate(from: eventStartString),
              let endDate = parseDate(from: eventEndString) else {
            log(.error, "Failed to parse event dates. Start: '\(eventStartString)', End: '\(eventEndString)'")
            return nil
        }

        // Basic validation: end date should not be before start date
        guard startDate <= endDate else {
             log(.error, "Parsed end date is before start date. Start: \(startDate), End: \(endDate)")
             return nil
        }

        return ParsedEventInfo(uid: eventUID,
                               title: eventTitle,
                               startDate: startDate,
                               endDate: endDate,
                               calendarName: calendarName)
    }

    /// Parses an ISO8601 date string, trying formats with and without fractional seconds.
    private func parseDate(from dateString: String) -> Date? {
        let dateFormatter = ISO8601DateFormatter()

        // Define potential formats
        let formats: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone],
            [.withInternetDateTime, .withColonSeparatorInTimeZone] // Without fractional seconds
        ]

        for format in formats {
            dateFormatter.formatOptions = format
            if let date = dateFormatter.date(from: dateString) {
                // log(.debug, "Parsed date '\(dateString)' using format options: \(format)")
                return date
            }
        }

        log(.warn, "Failed to parse date string '\(dateString)' with supported ISO8601 formats.")
        return nil // Failed all attempts
    }

    /// Checks the current calendar authorization status. Does not request permission.
    private func checkCalendarAuthorization() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            log(.debug, "Calendar access authorized.")
            return true
        case .notDetermined:
            // We cannot request authorization from a background notification handler.
            log(.warn, "Calendar access not determined. Cannot proceed in background. User must grant access from app.")
            return false
        case .denied:
            log(.error, "Calendar access denied by user.")
            return false
        case .restricted:
            log(.error, "Calendar access restricted (e.g., by parental controls).")
            return false
        @unknown default:
            log(.error, "Unknown calendar authorization status: \(status).")
            return false
        }
    }

    /// Finds the single EKEvent that matches the details parsed from the notification payload.
    private func findMatchingEvent(using eventInfo: ParsedEventInfo) async -> EKEvent? {
        let calendar = Calendar.current

        // Define search range based on the event's dates (start of day to end of day)
        // This provides a reasonable window for finding the event.
        let searchStartDate = calendar.startOfDay(for: eventInfo.startDate)
        let dayAfterEventEnd = calendar.date(byAdding: .day, value: 1, to: eventInfo.endDate) ?? eventInfo.endDate
        let searchEndDate = calendar.startOfDay(for: dayAfterEventEnd)

        log(.debug, "Defining search range from \(searchStartDate) to \(searchEndDate).")

        // Attempt to narrow search by calendar name if provided
        var calendarsToSearch: [EKCalendar]? = nil
        if let targetName = eventInfo.calendarName {
            let allCalendars = eventStore.calendars(for: .event)
            calendarsToSearch = allCalendars.filter { $0.title == targetName }
            if calendarsToSearch?.isEmpty ?? true {
                log(.warn, "Calendar named '\(targetName)' not found, searching all calendars.")
                calendarsToSearch = nil // Fallback to searching all accessible calendars
            } else {
                 log(.info, "Found \(calendarsToSearch?.count ?? 0) specific calendar(s) named '\(targetName)' to search.")
            }
        } else {
            log(.info, "No calendar name hint provided, searching all accessible calendars.")
            calendarsToSearch = eventStore.calendars(for: .event) // Explicitly search all if no name hint
        }
        
        guard calendarsToSearch != nil && !calendarsToSearch!.isEmpty else {
            log(.warn, "No calendars available to search.")
            return nil
        }


        // Create the predicate for EventKit
        let predicate = eventStore.predicateForEvents(withStart: searchStartDate,
                                                      end: searchEndDate,
                                                      calendars: calendarsToSearch)

        log(.info, "Fetching events matching predicate...")
        // Note: events(matching:) is synchronous. If this becomes a performance bottleneck
        // in the background, consider wrapping it in a Task, but be mindful of background execution limits.
        let eventsInRange = eventStore.events(matching: predicate)
        log(.info, "Found \(eventsInRange.count) events in range to filter.")

        // Filter the fetched events in memory for an exact match
        let tolerance: TimeInterval = 2.0 // Allow a small tolerance (in seconds) for date comparisons
        let potentialMatches = eventsInRange.filter { event in
            guard event.title == eventInfo.title else { return false }

            let startDiff = abs(event.startDate.timeIntervalSince(eventInfo.startDate))
            let endDiff = abs(event.endDate.timeIntervalSince(eventInfo.endDate))

            // Use tolerance for date matching
            let datesMatch = startDiff < tolerance && endDiff < tolerance
            // log(.debug, "Comparing event ID \(event.eventIdentifier ?? "N/A"): Title match: \(event.title == eventInfo.title), Dates match: \(datesMatch) (Diffs: \(startDiff), \(endDiff))")

            return datesMatch
        }

        // Evaluate the matches
        if potentialMatches.count == 1 {
            let matchedEvent = potentialMatches[0]
            log(.info, "Successfully matched event: '\(matchedEvent.title ?? "N/A")' (EKID: \(matchedEvent.eventIdentifier ?? "N/A"))")
            return matchedEvent
        } else if potentialMatches.isEmpty {
            log(.error, "Could not find specific event matching Title/Start/End in the fetched range. UID: \(eventInfo.uid)")
            // This could happen if the event was deleted, moved significantly, or its details changed post-notification.
            return nil
        } else {
            // Ambiguity: Multiple events match perfectly. This shouldn't happen often but is possible.
            log(.warn, "Found multiple (\(potentialMatches.count)) events matching Title/Start/End in the range. Cannot reliably identify the correct event. UID: \(eventInfo.uid)")
            // Log details of ambiguous events for debugging if necessary
            potentialMatches.forEach { event in
                log(.warn, "  Ambiguous Match: \(event.title ?? "N/A"), Start: \(String(describing: event.startDate)), End: \(String(describing: event.endDate)), EKID: \(event.eventIdentifier ?? "N/A")")
            }
            return nil // Treat ambiguity as failure to ensure we don't process the wrong event
        }
    }

    /// Finds events that conflict with the given event's time range.
    private func findConflicts(for event: EKEvent) -> [EKEvent] {
        guard let startDate = event.startDate, let endDate = event.endDate else {
            log(.warn, "Cannot find conflicts for event without start or end date: \(event.title ?? "N/A")")
            return [] // Cannot check conflicts without valid dates
        }

        // Fetch events overlapping the target event's time range across all calendars
        let calendarsToCheck = eventStore.calendars(for: .event)
        guard !calendarsToCheck.isEmpty else {
             log(.warn, "No calendars available to check for conflicts.")
             return []
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendarsToCheck)
        let overlappingEvents = eventStore.events(matching: predicate)

        // Filter out the original event itself using its unique EKEventIdentifier
        let conflictingEvents = overlappingEvents.filter { $0.eventIdentifier != event.eventIdentifier && !$0.isAllDay }

        log(.debug, "Found \(conflictingEvents.count) conflicting events for event EKID: \(event.eventIdentifier ?? "N/A")")
        return conflictingEvents
    }

    // Simple logging helper (replace with a more robust logger if needed)
    private func log(_ level: LogLevel, _ message: String) {
        #if DEBUG // Only print logs in DEBUG builds
        print("[\(level.rawValue.uppercased())] [NotificationHandlerService] \(message)")
        #endif
    }

    private enum LogLevel: String {
        case debug, info, warn, error
    }
}

// Helper struct to hold parsed info, making function signatures cleaner
private struct ParsedEventInfo {
    let uid: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarName: String?
}

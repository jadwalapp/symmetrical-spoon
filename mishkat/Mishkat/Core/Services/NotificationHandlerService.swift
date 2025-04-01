//
//  NotificationHandlerService.swift
//  Mishkat
//
//  Created by Human on 01/04/2025.
//

import EventKit
import UserNotifications
import UIKit

@MainActor
class NotificationHandlerService: NSObject {
    private let eventStore: EKEventStore
    private let conflictManager: ConflictManager
    
    init(eventStore: EKEventStore = EKEventStore(), conflictManager: ConflictManager = .shared) {
        self.eventStore = eventStore
        self.conflictManager = conflictManager
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Handle notification from backend asking to check for conflicts
    func handleBackgroundNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let parsedInfo = parseUserInfo(userInfo) else {
            return .failed
        }
        
        log(.info, "Handling background notification for event UID: \(parsedInfo.uid)")
        log(.debug, "  Title: \(parsedInfo.title)")
        log(.debug, "  Start: \(parsedInfo.startDate)")
        log(.debug, "  End: \(parsedInfo.endDate)")
        if let name = parsedInfo.calendarName { log(.debug, "  Calendar Name Hint: \(name)") }
        
        guard await checkCalendarAuthorization() else {
            return .failed
        }
        
        guard let foundEvent = await findMatchingEvent(using: parsedInfo) else {
            return .noData
        }
        
        let conflicts = findConflicts(for: foundEvent)
        
        if conflicts.isEmpty {
            log(.info, "No conflicts found for event '\(foundEvent.title ?? "N/A")' (EKID: \(foundEvent.eventIdentifier ?? "N/A")).")
            return .newData
        } else {
            log(.warn, "Conflict detected for event '\(foundEvent.title ?? "N/A")' (EKID: \(foundEvent.eventIdentifier ?? "N/A"))!")
            await conflictManager.recordConflict(originalEvent: foundEvent, conflictingEvents: conflicts)
            return .newData
        }
    }
    
    // Handle local notification tap to show conflict resolution
    func handleLocalNotification(_ notification: UNNotification) async {
        guard let userInfo = notification.request.content.userInfo as? [String: Any] else {
            print("Invalid notification user info")
            return
        }
        
        guard let type = userInfo["type"] as? String else {
            print("Missing notification type")
            return
        }
        
        switch type {
        case "conflict":
            if let conflictIdString = userInfo["conflict_id"] as? String,
               let conflictId = UUID(uuidString: conflictIdString) {
                await MainActor.run {
                    conflictManager.showConflict(conflictId)
                }
            }
        default:
            print("Unknown notification type: \(type)")
        }
    }
    
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
        
        guard let startDate = parseDate(from: eventStartString),
              let endDate = parseDate(from: eventEndString) else {
            log(.error, "Failed to parse event dates. Start: '\(eventStartString)', End: '\(eventEndString)'")
            return nil
        }
        
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
    
    private func parseDate(from dateString: String) -> Date? {
        let dateFormatter = ISO8601DateFormatter()
        
        let formats: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone],
            [.withInternetDateTime, .withColonSeparatorInTimeZone]
        ]
        
        for format in formats {
            dateFormatter.formatOptions = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        log(.warn, "Failed to parse date string '\(dateString)' with supported ISO8601 formats.")
        return nil
    }
    
    private func checkCalendarAuthorization() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            log(.debug, "Calendar access authorized.")
            return true
        case .notDetermined:
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
    
    private func findMatchingEvent(using eventInfo: ParsedEventInfo) async -> EKEvent? {
        let calendar = Calendar.current
        let searchStartDate = calendar.startOfDay(for: eventInfo.startDate)
        let dayAfterEventEnd = calendar.date(byAdding: .day, value: 1, to: eventInfo.endDate) ?? eventInfo.endDate
        let searchEndDate = calendar.startOfDay(for: dayAfterEventEnd)
        
        log(.debug, "Defining search range from \(searchStartDate) to \(searchEndDate).")
        
        var calendarsToSearch: [EKCalendar]? = nil
        if let targetName = eventInfo.calendarName {
            let allCalendars = eventStore.calendars(for: .event)
            calendarsToSearch = allCalendars.filter { $0.title == targetName }
            if calendarsToSearch?.isEmpty ?? true {
                log(.warn, "Calendar named '\(targetName)' not found, searching all calendars.")
                calendarsToSearch = nil
            } else {
                log(.info, "Found \(calendarsToSearch?.count ?? 0) specific calendar(s) named '\(targetName)' to search.")
            }
        } else {
            log(.info, "No calendar name hint provided, searching all accessible calendars.")
            calendarsToSearch = eventStore.calendars(for: .event)
        }
        
        guard calendarsToSearch != nil && !calendarsToSearch!.isEmpty else {
            log(.warn, "No calendars available to search.")
            return nil
        }
        
        let predicate = eventStore.predicateForEvents(withStart: searchStartDate,
                                                   end: searchEndDate,
                                                   calendars: calendarsToSearch)
        
        log(.info, "Fetching events matching predicate...")
        let eventsInRange = eventStore.events(matching: predicate)
        log(.info, "Found \(eventsInRange.count) events in range to filter.")
        
        let tolerance: TimeInterval = 2.0
        let potentialMatches = eventsInRange.filter { event in
            guard event.title == eventInfo.title else { return false }
            
            let startDiff = abs(event.startDate.timeIntervalSince(eventInfo.startDate))
            let endDiff = abs(event.endDate.timeIntervalSince(eventInfo.endDate))
            
            let datesMatch = startDiff < tolerance && endDiff < tolerance
            return datesMatch
        }
        
        if potentialMatches.count == 1 {
            let matchedEvent = potentialMatches[0]
            log(.info, "Successfully matched event: '\(matchedEvent.title ?? "N/A")' (EKID: \(matchedEvent.eventIdentifier ?? "N/A"))")
            return matchedEvent
        } else if potentialMatches.isEmpty {
            log(.error, "Could not find specific event matching Title/Start/End in the fetched range. UID: \(eventInfo.uid)")
            return nil
        } else {
            log(.warn, "Found multiple (\(potentialMatches.count)) events matching Title/Start/End in the range. Cannot reliably identify the correct event. UID: \(eventInfo.uid)")
            potentialMatches.forEach { event in
                log(.warn, "  Ambiguous Match: \(event.title ?? "N/A"), Start: \(String(describing: event.startDate)), End: \(String(describing: event.endDate)), EKID: \(event.eventIdentifier ?? "N/A")")
            }
            return nil
        }
    }
    
    private func findConflicts(for event: EKEvent) -> [EKEvent] {
        guard let startDate = event.startDate, let endDate = event.endDate else {
            log(.warn, "Cannot find conflicts for event without start or end date: \(event.title ?? "N/A")")
            return []
        }
        
        let calendarsToCheck = eventStore.calendars(for: .event)
        guard !calendarsToCheck.isEmpty else {
            log(.warn, "No calendars available to check for conflicts.")
            return []
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendarsToCheck)
        let overlappingEvents = eventStore.events(matching: predicate)
        
        let conflictingEvents = overlappingEvents.filter { $0.eventIdentifier != event.eventIdentifier && !$0.isAllDay }
        
        log(.debug, "Found \(conflictingEvents.count) conflicting events for event EKID: \(event.eventIdentifier ?? "N/A")")
        return conflictingEvents
    }
    
    private func log(_ level: LogLevel, _ message: String) {
        #if DEBUG
        print("[\(level.rawValue.uppercased())] [NotificationHandlerService] \(message)")
        #endif
    }
    
    private enum LogLevel: String {
        case debug, info, warn, error
    }
}

private struct ParsedEventInfo {
    let uid: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarName: String?
}

extension NotificationHandlerService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            await handleLocalNotification(response.notification)
            completionHandler()
        }
    }
}

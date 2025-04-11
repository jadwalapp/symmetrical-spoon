import Foundation
import EventKit
import UserNotifications

struct Conflict: Identifiable, Codable {
    let id: UUID
    let originalEvent: EventInfo
    let conflictingEvents: [EventInfo]
    let createdAt: Date
    var resolved: Bool
    var resolution: ConflictResolution?
    
    struct EventInfo: Codable, Equatable {
        let title: String
        let startDate: Date
        let endDate: Date
        let calendarName: String?
        let eventIdentifier: String?
        var isNew: Bool
        
        init(title: String, startDate: Date, endDate: Date, calendarName: String?, eventIdentifier: String?, isNew: Bool) {
            self.title = title
            self.startDate = startDate
            self.endDate = endDate
            self.calendarName = calendarName
            self.eventIdentifier = eventIdentifier
            self.isNew = isNew
        }
        
        enum CodingKeys: String, CodingKey {
             case title, startDate, endDate, calendarName, eventIdentifier, isNew
        }
    }
    
    enum ConflictResolution: Codable, Equatable {
        case keepBoth
        case moveEvent(EventInfo, Date)
        case deleteEvent(EventInfo)
        
        static func == (lhs: ConflictResolution, rhs: ConflictResolution) -> Bool {
            switch (lhs, rhs) {
            case (.keepBoth, .keepBoth):
                return true
            case let (.moveEvent(lhsEvent, lhsDate), .moveEvent(rhsEvent, rhsDate)):
                return lhsEvent.eventIdentifier == rhsEvent.eventIdentifier && lhsDate == rhsDate
            case let (.deleteEvent(lhsEvent), .deleteEvent(rhsEvent)):
                return lhsEvent.eventIdentifier == rhsEvent.eventIdentifier
            default:
                return false
            }
        }
    }
}

@MainActor
class ConflictManager: ObservableObject {
    static let shared = ConflictManager()
    
    @Published private(set) var conflicts: [Conflict] = []
    @Published var selectedConflictId: UUID?
    @Published var showConflictsView = false
    private let userDefaults = UserDefaults.standard
    private let conflictsKey = "stored_conflicts"
    
    private let eventStore: EKEventStore
    
    private init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
        loadConflicts()
    }
    
    func recordConflict(originalEvent: EKEvent, conflictingEvents: [EKEvent]) async {
        let conflict = Conflict(
            id: UUID(),
            originalEvent: .init(
                title: originalEvent.title ?? "Untitled",
                startDate: originalEvent.startDate,
                endDate: originalEvent.endDate,
                calendarName: originalEvent.calendar.title,
                eventIdentifier: originalEvent.eventIdentifier,
                isNew: true
            ),
            conflictingEvents: conflictingEvents.map { event in
                .init(
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    calendarName: event.calendar.title,
                    eventIdentifier: event.eventIdentifier,
                    isNew: false
                )
            },
            createdAt: Date(),
            resolved: false,
            resolution: nil
        )
        
        conflicts.append(conflict)
        saveConflicts()
        await scheduleNotification(for: conflict)
    }
    
    func resolveConflict(_ conflict: Conflict, with resolution: Conflict.ConflictResolution) async {
        guard let index = conflicts.firstIndex(where: { $0.id == conflict.id }) else { 
            print("[ConflictManager] Error: Conflict with ID \(conflict.id) not found locally.")
            return 
        }

        var eventKitError: Error? = nil

        switch resolution {
        case .keepBoth:
            print("[ConflictManager] Info: Resolving conflict \(conflict.id) by keeping both events.")
            break

        case .moveEvent(let eventInfo, let newStartDate):
            print("[ConflictManager] Info: Resolving conflict \(conflict.id) by moving event to \(newStartDate).")
            guard let identifier = eventInfo.eventIdentifier,
                  let eventToMove = eventStore.event(withIdentifier: identifier) else {
                print("[ConflictManager] Error: Could not find event with identifier \(eventInfo.eventIdentifier ?? "nil") to move.")
                eventKitError = NSError(domain: "ConflictManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Event to move not found"])
                break
            }
            
            let originalDuration = eventInfo.endDate.timeIntervalSince(eventInfo.startDate)
            let newEndDate = newStartDate.addingTimeInterval(originalDuration)
            
            eventToMove.startDate = newStartDate
            eventToMove.endDate = newEndDate
            
            do {
                try eventStore.save(eventToMove, span: .thisEvent)
                print("[ConflictManager] Info: Successfully moved event \(identifier) to \(newStartDate).")
            } catch {
                print("[ConflictManager] Error: Failed to save moved event \(identifier): \(error.localizedDescription)")
                eventKitError = error
            }

        case .deleteEvent(let eventInfo):
            print("[ConflictManager] Info: Resolving conflict \(conflict.id) by deleting event.")
             guard let identifier = eventInfo.eventIdentifier,
                   let eventToDelete = eventStore.event(withIdentifier: identifier) else {
                 print("[ConflictManager] Error: Could not find event with identifier \(eventInfo.eventIdentifier ?? "nil") to delete.")
                 eventKitError = NSError(domain: "ConflictManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Event to delete not found"])
                 break
             }

            do {
                try eventStore.remove(eventToDelete, span: .thisEvent)
                print("[ConflictManager] Info: Successfully deleted event \(identifier).")
            } catch {
                print("[ConflictManager] Error: Failed to delete event \(identifier): \(error.localizedDescription)")
                eventKitError = error
            }
        }

        if eventKitError == nil {
            conflicts[index].resolved = true
            conflicts[index].resolution = resolution
            saveConflicts()
            print("[ConflictManager] Debug: Successfully marked conflict \(conflict.id) as resolved locally.")
        } else {
             print("[ConflictManager] Error: Failed to resolve conflict \(conflict.id) in EventKit. Local state not updated. Error: \(eventKitError!.localizedDescription)")
        }
    }
    
    func showConflict(_ conflictId: UUID) {
        selectedConflictId = conflictId
        showConflictsView = true
    }
    
    private func saveConflicts() {
        if let encoded = try? JSONEncoder().encode(conflicts) {
            userDefaults.set(encoded, forKey: conflictsKey)
        }
    }
    
    private func loadConflicts() {
        if let data = userDefaults.data(forKey: conflictsKey),
           let decoded = try? JSONDecoder().decode([Conflict].self, from: data) {
            conflicts = decoded
        }
    }
    
    private func scheduleNotification(for conflict: Conflict) async {
        let content = UNMutableNotificationContent()
        content.title = "Calendar Conflict Detected"
        content.body = "'\(conflict.originalEvent.title)' has \(conflict.conflictingEvents.count) conflicting event(s)"
        content.sound = .default
        
        content.userInfo = [
            "type": "conflict",
            "conflict_id": conflict.id.uuidString
        ]
        
        let request = UNNotificationRequest(
            identifier: conflict.id.uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("[ConflictManager] Info: Scheduled notification for conflict ID: \(conflict.id)")
        } catch {
            print("[ConflictManager] Error: Failed to schedule conflict notification: \(error.localizedDescription)")
        }
    }
} 

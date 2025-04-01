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
    
    struct EventInfo: Codable {
        let title: String
        let startDate: Date
        let endDate: Date
        let calendarName: String?
        let eventIdentifier: String?
    }
    
    enum ConflictResolution: Codable {
        case keepBoth
        case moveEvent(EventInfo, Date)
        case deleteEvent(EventInfo)
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
    
    private init() {
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
                eventIdentifier: originalEvent.eventIdentifier
            ),
            conflictingEvents: conflictingEvents.map { event in
                .init(
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    calendarName: event.calendar.title,
                    eventIdentifier: event.eventIdentifier
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
    
    func resolveConflict(_ conflict: Conflict, with resolution: Conflict.ConflictResolution) {
        guard let index = conflicts.firstIndex(where: { $0.id == conflict.id }) else { return }
        conflicts[index].resolved = true
        conflicts[index].resolution = resolution
        saveConflicts()
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
        content.body = "\(conflict.originalEvent.title) has \(conflict.conflictingEvents.count) conflicting events"
        content.sound = .default
        
        // Add deep link data
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
        } catch {
            print("Failed to schedule conflict notification: \(error)")
        }
    }
} 
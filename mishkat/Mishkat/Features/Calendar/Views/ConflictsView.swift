import SwiftUI
import EventKit

struct ConflictsView: View {
    @StateObject private var conflictManager = ConflictManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConflict: Conflict?
    
    var body: some View {
        NavigationView {
            List {
                if conflictManager.conflicts.filter({ !$0.resolved }).isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("No Conflicts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("All your calendar events are properly scheduled")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(conflictManager.conflicts.filter { !$0.resolved }) { conflict in
                        ConflictRow(conflict: conflict)
                            .onTapGesture {
                                selectedConflict = conflict
                            }
                    }
                }
            }
            .navigationTitle("Conflicts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedConflict) { conflict in
                NavigationView {
                    ConflictResolutionView(conflict: conflict)
                }
            }
        }
        .onAppear {
            if let conflictId = conflictManager.selectedConflictId,
               let conflict = conflictManager.conflicts.first(where: { $0.id == conflictId }) {
                selectedConflict = conflict
            }
        }
    }
}

struct ConflictRow: View {
    let conflict: Conflict
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(conflict.originalEvent.title)
                .font(.headline)
            Text("\(conflict.conflictingEvents.count) conflicting events")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(conflict.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ConflictResolutionView: View {
    let conflict: Conflict
    @StateObject private var conflictManager = ConflictManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedResolution: Conflict.ConflictResolution?
    @State private var isMovingEvent = false
    @State private var newDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Original Event")) {
                    EventInfoView(event: conflict.originalEvent)
                }
                
                Section(header: Text("Conflicting Events")) {
                    ForEach(conflict.conflictingEvents, id: \.eventIdentifier) { event in
                        EventInfoView(event: event)
                    }
                }
                
                Section(header: Text("Resolution Options")) {
                    Button("Keep Both Events") {
                        selectedResolution = .keepBoth
                        isMovingEvent = false
                    }
                    
                    Button("Move Original Event") {
                        isMovingEvent = true
                    }
                    
                    Button("Delete Original Event") {
                        selectedResolution = .deleteEvent(conflict.originalEvent)
                        isMovingEvent = false
                    }
                    .foregroundColor(.red)
                }
                
                if isMovingEvent {
                    Section(header: Text("New Date")) {
                        DatePicker("Select Date", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Resolve Conflict")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Resolve") {
                        if isMovingEvent {
                            selectedResolution = .moveEvent(conflict.originalEvent, newDate)
                        }
                        if let resolution = selectedResolution {
                            conflictManager.resolveConflict(conflict, with: resolution)
                            dismiss()
                        }
                    }
                    .disabled(selectedResolution == nil && !isMovingEvent)
                }
            }
        }
    }
}

struct EventInfoView: View {
    let event: Conflict.EventInfo
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(event.title)
                .font(.headline)
            Text("\(event.startDate, style: .date) - \(event.endDate, style: .date)")
                .font(.subheadline)
            if let calendarName = event.calendarName {
                Text(calendarName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ConflictsView()
} 

import SwiftUI
import EventKit

struct ConflictsView: View {
    @StateObject private var conflictManager = ConflictManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConflict: Conflict?
    
    var body: some View {
        NavigationView {
            ZStack {
                if conflictManager.conflicts.filter({ !$0.resolved }).isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                        
                        Text("No Scheduling Conflicts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your calendar is free from any scheduling conflicts.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(conflictManager.conflicts.filter { !$0.resolved }) { conflict in
                            Button {
                                selectedConflict = conflict
                            } label: {
                                ConflictRow(conflict: conflict)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Scheduling Conflicts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedConflict) { conflict in
            NavigationView {
                ConflictResolutionView(conflict: conflict)
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
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(conflict.originalEvent.title)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDateRange(start: conflict.originalEvent.startDate, end: conflict.originalEvent.endDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("\(conflict.conflictingEvents.count) conflicting event\(conflict.conflictingEvents.count > 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return "\(dateFormatter.string(from: start))"
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // New Event Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("New Event")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("Needs Resolution")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                    
                    EventCard(event: conflict.originalEvent, isNew: true)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Existing Events Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Existing Event\(conflict.conflictingEvents.count > 1 ? "s" : "")")
                        .font(.headline)
                    
                    ForEach(conflict.conflictingEvents, id: \.eventIdentifier) { event in
                        EventCard(event: event, isNew: false)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Resolution Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Resolution Options")
                        .font(.headline)
                    
                    ResolutionOption(
                        icon: "calendar.badge.plus",
                        title: "Keep Both Events",
                        description: "Keep all events as scheduled",
                        isSelected: selectedResolution == .keepBoth,
                        action: {
                            selectedResolution = .keepBoth
                            isMovingEvent = false
                        }
                    )
                    
                    ResolutionOption(
                        icon: "arrow.right.circle",
                        title: "Reschedule New Event",
                        description: "Move the new event to a different time",
                        isSelected: isMovingEvent,
                        action: {
                            isMovingEvent = true
                            selectedResolution = nil
                        }
                    )
                    
                    if isMovingEvent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select New Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.leading)
                    }
                    
                    ResolutionOption(
                        icon: "trash",
                        title: "Cancel New Event",
                        description: "Remove the new event from your calendar",
                        isSelected: selectedResolution == .deleteEvent(conflict.originalEvent),
                        action: {
                            selectedResolution = .deleteEvent(conflict.originalEvent)
                            isMovingEvent = false
                        }
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Resolve Conflict")
        .navigationBarTitleDisplayMode(.inline)
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
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
            }
        }
    }
}

struct EventCard: View {
    let event: Conflict.EventInfo
    let isNew: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(isNew ? .accentColor : .primary)
                
                Spacer()
                
                if isNew {
                    Text("New")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDateRange(start: event.startDate, end: event.endDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let calendarName = event.calendarName {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(calendarName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return "\(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end))"
    }
}

struct ResolutionOption: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    ConflictsView()
} 

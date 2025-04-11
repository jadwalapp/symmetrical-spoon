import SwiftUI
import EventKit

struct ConflictsView: View {
    @StateObject private var conflictManager = ConflictManager.shared
    @EnvironmentObject private var viewModel: CalendarViewModel
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
                                ConflictRowView(conflict: conflict)
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
            ConflictResolutionView(conflict: conflict)
                .environmentObject(viewModel)
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

#Preview {
    ConflictsView()
} 

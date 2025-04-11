import SwiftUI

/// A row item for displaying conflict information in a list
struct ConflictRowView: View {
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
//
//  EventRow.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import SwiftUI
import EventKit

struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(event.calendar.cgColor))
                .frame(width: 4)
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                Text(timeRangeString(for: event))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    func timeRangeString(for event: EKEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
}

#Preview {
    EventRow(event: EKEvent())
}

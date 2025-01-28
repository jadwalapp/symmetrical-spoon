//
//  CalendarsListView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import EventKit

struct CalendarsListView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.calendarSources, id: \.sourceIdentifier) { source in
                    Section(header: Text(source.title)) {
//                        ForEach(Array(source.calendars(for: .event)), id: \.calendarIdentifier) { calendar in
//                            Text("\()")
//                            CalendarRowView(calendar: calendar, isVisible: viewModel.visibleCalendars.contains(calendar)) { isOn in
//                                if isOn {
//                                    viewModel.visibleCalendars.insert(calendar)
//                                } else {
//                                    viewModel.visibleCalendars.remove(calendar)
//                                }
//                                viewModel.fetchEvents(for: viewModel.selectedDate)
//                            }
//                        }
                    }
                }
            }
            .navigationTitle("Calendars")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CalendarRowView: View {
    let calendar: EKCalendar
    let isVisible: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(Color(calendar.cgColor))
                .frame(width: 20, height: 20)
            Text(calendar.title)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isVisible },
                set: onToggle
            ))
        }
    }
}

#Preview {
    CalendarsListView()
        .environmentObject(CalendarViewModel())
}

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
    @State private var showingAddCalendarSheet = false
    @State private var editingCalendar: EKCalendar?
    
    var body: some View {
        NavigationView {
            CalendarsList(
                sources: viewModel.calendarSources,
                visibleCalendars: viewModel.visibleCalendars,
                onToggleVisibility: { calendar, isVisible in
                    if isVisible {
                        viewModel.visibleCalendars.insert(calendar)
                    } else {
                        viewModel.visibleCalendars.remove(calendar)
                    }
                    viewModel.fetchEvents(for: viewModel.selectedDate)
                },
                onDeleteCalendar: viewModel.deleteCalendar,
                onEditCalendar: { calendar in
                    editingCalendar = calendar
                }
            )
            .navigationTitle("Calendars")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCalendarSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddCalendarSheet) {
                CalendarEditView(mode: .add)
            }
            .sheet(item: $editingCalendar) { calendar in
                CalendarEditView(mode: .edit(calendar))
            }
        }
    }
}

private struct CalendarsList: View {
    let sources: [EKSource]
    let visibleCalendars: Set<EKCalendar>
    let onToggleVisibility: (EKCalendar, Bool) -> Void
    let onDeleteCalendar: (EKCalendar) -> Void
    let onEditCalendar: (EKCalendar) -> Void
    
    var body: some View {
        List {
            ForEach(sources, id: \.sourceIdentifier) { source in
                CalendarSourceSection(
                    source: source,
                    visibleCalendars: visibleCalendars,
                    onToggleVisibility: onToggleVisibility,
                    onDeleteCalendar: onDeleteCalendar,
                    onEditCalendar: onEditCalendar
                )
            }
        }
    }
}

private struct CalendarSourceSection: View {
    let source: EKSource
    let visibleCalendars: Set<EKCalendar>
    let onToggleVisibility: (EKCalendar, Bool) -> Void
    let onDeleteCalendar: (EKCalendar) -> Void
    let onEditCalendar: (EKCalendar) -> Void
    
    var body: some View {
        Section(header: Text(source.title)) {
            ForEach(Array(source.calendars(for: .event)), id: \.calendarIdentifier) { calendar in
                CalendarRowView(
                    calendar: calendar,
                    isVisible: visibleCalendars.contains(calendar),
                    onToggle: { isVisible in
                        onToggleVisibility(calendar, isVisible)
                    }
                )
                .swipeActions(edge: .trailing) {
                    if calendar.allowsContentModifications {
                        Button(role: .destructive) {
                            onDeleteCalendar(calendar)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            onEditCalendar(calendar)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
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

struct CalendarEditView: View {
    enum Mode {
        case add
        case edit(EKCalendar)
    }
    
    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var title = ""
    @State private var color = Color.green
    @State private var selectedSource: EKSource?
    @State private var isLoading = false
    
    private var isFormValid: Bool {
        if case .add = mode {
            return !title.isEmpty && selectedSource != nil
        }
        return !title.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section {
                        TextField("Calendar Name", text: $title)
                        ColorPicker("Color", selection: $color)
                    }
                    
                    if case .add = mode {
                        Section("Account") {
                            ForEach(viewModel.calendarSources, id: \.sourceIdentifier) { source in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(source.title)
                                            .font(.headline)
                                        Text(source.sourceType.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if source == selectedSource {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.green)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSource = source
                                }
                            }
                        }
                    }
                }
                .disabled(isLoading)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(.green)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isLoading = true
                        Task {
                            switch mode {
                            case .add:
                                if let source = selectedSource {
                                    await viewModel.createCalendar(title: title, color: color, source: source)
                                }
                            case .edit(let calendar):
                                await viewModel.updateCalendar(calendar, title: title, color: color)
                            }
                            dismiss()
                        }
                    }
                    .disabled(!isFormValid)
                    .tint(.green)
                }
            }
            .onAppear {
                if case .edit(let calendar) = mode {
                    title = calendar.title
                    color = Color(calendar.cgColor)
                } else {
                    // For add mode, select the default calendar's source
                    selectedSource = viewModel.eventStore.defaultCalendarForNewEvents?.source
                }
            }
        }
        .interactiveDismissDisabled(isLoading)
    }
    
    private var navigationTitle: String {
        if case .add = mode {
            return "New Calendar"
        } else {
            return "Edit Calendar"
        }
    }
}

extension EKSourceType {
    var description: String {
        switch self {
        case .local:
            return "On My iPhone"
        case .calDAV:
            return "CalDAV"
        case .exchange:
            return "Exchange"
        case .mobileMe:
            return "iCloud"
        case .subscribed:
            return "Subscribed"
        case .birthdays:
            return "Birthdays"
        @unknown default:
            return "Other"
        }
    }
}

// Make EKCalendar identifiable for sheet presentation
extension EKCalendar: Identifiable {
    public var id: String { calendarIdentifier }
}

#Preview {
    CalendarsListView()
        .environmentObject(CalendarViewModel())
}

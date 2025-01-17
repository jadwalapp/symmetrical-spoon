//
//  CalendarView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import EventKit

struct CalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var showingAddEventSheet = false
    @State private var showingCalendarsSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                EnhancedCalendarView()
                    .blur(radius: viewModel.authorizationStatus != .authorized ? 10 : 0)
                
                if viewModel.authorizationStatus != .authorized {
                    AccessRequestCard(status: viewModel.authorizationStatus, requestAccess: viewModel.requestAccess, openSettings: viewModel.openSettings)
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingCalendarsSheet.toggle()
                        } label: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.primary)
                        }
                        
                        Button {
                            showingAddEventSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventView(isPresented: $showingAddEventSheet)
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingCalendarsSheet) {
                CalendarsListView()
            }
        }
    }
}

struct AccessRequestCard: View {
    let status: EKAuthorizationStatus
    let requestAccess: () -> Void
    let openSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Calendar Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("To use the calendar features, we need access to your calendar. This allows us to display and manage your events.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                if status == .notDetermined {
                    requestAccess()
                } else {
                    openSettings()
                }
            }) {
                Text(status == .denied ? "Open Settings" : "Grant Access")
                    .fontWeight(.semibold)
                    .frame(minWidth: 200)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: 300)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CalendarsListView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.calendarSources, id: \.sourceIdentifier) { source in
                    Section(header: Text(source.title)) {
                        ForEach(Array(source.calendars(for: .event)), id: \.calendarIdentifier) { calendar in
                            HStack {
                                Circle()
                                    .fill(Color(calendar.cgColor))
                                    .frame(width: 20, height: 20)
                                Text(calendar.title)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { viewModel.visibleCalendars.contains(calendar) },
                                    set: { isOn in
                                        if isOn {
                                            viewModel.visibleCalendars.insert(calendar)
                                        } else {
                                            viewModel.visibleCalendars.remove(calendar)
                                        }
                                        viewModel.fetchEvents(for: viewModel.selectedDate)
                                    }
                                ))
                            }
                        }
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


struct EventsListView: View {
    let events: [EKEvent]
    
    var body: some View {
        List(events, id: \.eventIdentifier) { event in
            VStack(alignment: .leading) {
                Text(event.title)
                Text("\(event.startDate, formatter: dateFormatter) - \(event.endDate, formatter: dateFormatter)")
                    .font(.caption)
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct CalendarViewRepresentable: UIViewRepresentable {
    @Binding var selectedDate: DateComponents?
    @Binding var displayEvents: Bool
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.delegate = context.coordinator
        calendarView.calendar = Calendar(identifier: .gregorian)
        
        calendarView.tintColor = .accent
        calendarView.availableDateRange = DateInterval(start: .distantPast, end: .distantFuture)
        
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = dateSelection
        
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarViewRepresentable
        
        init(parent: CalendarViewRepresentable) {
            self.parent = parent
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            parent.selectedDate = dateComponents
            parent.displayEvents = true
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            return nil
        }
    }
}

#Preview {
    CalendarView()
}

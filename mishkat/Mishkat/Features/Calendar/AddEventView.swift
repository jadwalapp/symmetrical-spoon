//
//  AddEventView.swift
//  Mishkat
//
//  Created by Human on 26/11/2024.
//

import SwiftUI

struct AddEventView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    @Binding var isPresented: Bool
    var selectedDate: DateComponents?
    
    @State private var eventTitle = ""
    @State private var eventLocation = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var notes = ""
    @State private var isAllDay = false
    
    @State private var selectedCalender: Calendar_V1_Calendar?
    
    var isValid: Bool {
        return eventTitle.count > 0 && startDate < endDate && selectedCalender != nil
    }
    
    var calendarPicker: some View {
        AsyncView(response: calendarViewModel.calendarsWithCalendarAccountsState) { resp in
            if selectedCalender != nil {
                Picker("Calendar", selection: $selectedCalender) {
                    ForEach(resp.calendarAccountWithCalendarsList) { accountWithCalendars in
                        Section(header: Text("\(accountWithCalendars.account.provider.rawValue)")) {
                            ForEach(accountWithCalendars.calendars) { calendar in
                                Text(calendar.name).tag(calendar)
                            }
                        }
                    }
                }
            } else {
                HStack {
                    Text("Calendar")
                        .unredacted()
                    Spacer()
                    Text("THE CALENDAR :D")
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $eventTitle)
                    TextField("Location", text: $eventLocation)
                } header: {
                    Text("Event Details")
                }
                
                Section {
                    calendarPicker
                        .frame(height: 40)
                }
                
                Section {
                    Toggle("All-day", isOn: $isAllDay)
                    DatePicker(
                        "Starts",
                        selection: $startDate,
                        displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                    DatePicker(
                        "Ends",
                        selection: $endDate,
                        displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                }
                
                Section {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if calendarViewModel.createEventState == .loading {
                        ProgressView()
                    } else {
                        Button("Add") {
                            if let calendarId = selectedCalender?.id {
                                calendarViewModel.createEvent(
                                    calendarId: calendarId,
                                    title: eventTitle,
                                    location: eventLocation,
                                    isAllDay: isAllDay,
                                    startDate: startDate,
                                    endDate: endDate
                                )
                            }
                        }
                        .disabled(!isValid || calendarViewModel.calendarsWithCalendarAccountsState == .loading)
                    }
                }
            }
        }
        .onAppear {
            calendarViewModel.getCalendarsWithCalendarAccounts()
            
            if let selectedDate = selectedDate {
                var components = DateComponents()
                components.year = selectedDate.year
                components.month = selectedDate.month
                components.day = selectedDate.day
                
                if let date = Calendar.current.date(from: components) {
                    startDate = date
                    endDate = date.addingTimeInterval(3600)
                }
            }
        }
        .onChange(of: calendarViewModel.createEventState) { newValue in
            if  case .loaded = newValue {
                isPresented = false
            }
        }
        .onChange(of: calendarViewModel.calendarsWithCalendarAccountsState) { newValue in
            if case .loaded(let calendars) = newValue, !calendars.calendarAccountWithCalendarsList.isEmpty {
                if let firstCalendar = calendars.calendarAccountWithCalendarsList.first?.calendars.first {
                    selectedCalender = firstCalendar
                }
            }
        }
    }
}

#Preview {
    AddEventView(
        isPresented: .constant(true),
        selectedDate: DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2024,
            month: 10,
            day: 20
        )
    )
    .environmentObject(CalendarViewModel(calendarRepository: DependencyContainer.shared.calendarRepository))
}

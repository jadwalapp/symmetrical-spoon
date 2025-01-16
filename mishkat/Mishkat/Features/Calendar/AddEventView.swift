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
    
    var isValid: Bool {
        return eventTitle.count > 0 && startDate < endDate
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
                    Button("Add") {
                        print("add clicked")
                    }
                    .disabled(!isValid)
                    
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

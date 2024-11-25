//
//  AddEventView.swift
//  Mishkat
//
//  Created by Human on 26/11/2024.
//

import SwiftUI

struct AddEventView: View {
    @Binding var isPresented: Bool
    var selectedDate: DateComponents?
    
    @State private var eventTitle = ""
    @State private var eventLocation = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var notes = ""
    @State private var isAllDay = false
    
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
                    DatePicker("Starts",
                             selection: $startDate,
                             displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                    DatePicker("Ends",
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
                        // Here you would save the event
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
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
}

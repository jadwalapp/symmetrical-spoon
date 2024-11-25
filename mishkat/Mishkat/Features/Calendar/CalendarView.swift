//
//  CalendarView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate: DateComponents?
    @State private var displayEvents = false
    @State private var showingAddEventSheet = false
    
    var body: some View {
        NavigationStack {
            CalendarViewRepresentable(
                selectedDate: $selectedDate,
                displayEvents: $displayEvents
            )
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            // Handle notifications
                        } label: {
                            Image(systemName: "bell")
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
                AddEventView(isPresented: $showingAddEventSheet, selectedDate: selectedDate)
            }
        }
    }
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

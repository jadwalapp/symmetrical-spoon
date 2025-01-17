//
//  CalendarViewModel.swift
//  Mishkat
//
//  Created by Human on 04/01/2025.
//

import Foundation
import EventKit

class CalendarViewModel: ObservableObject {
    private let eventStore = EKEventStore()
    
    func requestAccess() {
        eventStore.requestAccess(to: .event) { (granted, error) in
            if !granted {
                print("Access to calendar not granted")
            }
        }
    }
    
    func fetchCalendarSources() -> [EKSource] {
        return eventStore.sources
    }
    
    func fetchEvents(for date: Date) -> [EKEvent] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        return eventStore.events(matching: predicate)
    }
}

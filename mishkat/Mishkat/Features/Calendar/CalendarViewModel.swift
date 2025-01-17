//
//  CalendarViewModel.swift
//  Mishkat
//
//  Created by Human on 04/01/2025.
//

import Foundation
import EventKit
import EventKitUI
import SwiftUI

class CalendarViewModel: NSObject, ObservableObject, EKEventEditViewDelegate {
    let eventStore = EKEventStore()
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var selectedDate: DateComponents?
    @Published var events: [EKEvent] = []
    @Published var calendarSources: [EKSource] = []
    @Published var defaultCalendar: EKCalendar?
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .authorized {
            fetchCalendarSources()
            setDefaultCalendar()
        }
    }
    
    func requestAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.authorizationStatus = granted ? .authorized : .denied
                if granted {
                    self?.fetchCalendarSources()
                    self?.setDefaultCalendar()
                }
            }
        }
    }
    
    func fetchCalendarSources() {
        calendarSources = eventStore.sources.filter { $0.sourceType != .calDAV }
    }
    
    func setDefaultCalendar() {
        defaultCalendar = eventStore.defaultCalendarForNewEvents
    }
    
    func fetchEvents(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        events = eventStore.events(matching: predicate)
    }
    
    func addEvent() -> EKEventEditViewController {
        let editViewController = EKEventEditViewController()
        editViewController.eventStore = eventStore
        editViewController.editViewDelegate = self
        
        let event = EKEvent(eventStore: eventStore)
        if let date = selectedDate?.date {
            event.startDate = date
            event.endDate = date.addingTimeInterval(3600) // 1 hour later
        }
        event.calendar = defaultCalendar
        editViewController.event = event
        
        return editViewController
    }
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        NotificationCenter.default.post(name: NSNotification.Name("DismissAddEventView"), object: nil)
        
        if action == .saved {
            if let date = selectedDate?.date {
                fetchEvents(for: date)
            }
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}


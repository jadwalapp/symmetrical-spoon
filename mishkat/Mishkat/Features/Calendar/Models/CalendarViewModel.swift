//
//  CalendarViewModel.swift
//  Mishkat
//
//  Created by Human on 04/01/2025.
//

import Foundation
import EventKit
import EventKitUI

/// ViewModel for managing calendar events and authorization status.
class CalendarViewModel: NSObject, ObservableObject, EKEventEditViewDelegate {
    let eventStore = EKEventStore()
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var selectedDate: Date = Date()
    @Published var dailyEvents: [EKEvent] = []
    @Published var monthlyEvents: [EKEvent] = []
    @Published var calendarSources: [EKSource] = []
    @Published var visibleCalendars: Set<EKCalendar> = []
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .authorized {
            fetchCalendarSources()
        }
    }
    
    func requestAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.authorizationStatus = granted ? .authorized : .denied
                if granted {
                    self?.fetchCalendarSources()
                }
            }
        }
    }
    
    func fetchCalendarSources() {
        calendarSources = eventStore.sources
        let allCalendars = calendarSources.flatMap { $0.calendars(for: .event) }
        visibleCalendars = Set(allCalendars)
    }
    
    func fetchDailyEvents(for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: Array(visibleCalendars))
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fetchedEvents = self?.eventStore.events(matching: predicate) ?? []
            DispatchQueue.main.async {
                self?.dailyEvents = fetchedEvents
            }
        }
    }
    
    func fetchMonthlyEvents(for date: Date) {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: Array(visibleCalendars))
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fetchedEvents = self?.eventStore.events(matching: predicate) ?? []
            DispatchQueue.main.async {
                self?.monthlyEvents = fetchedEvents
            }
        }
    }
    
    func addEvent() -> EKEventEditViewController {
        let editViewController = EKEventEditViewController()
        editViewController.eventStore = eventStore
        editViewController.editViewDelegate = self
        
        let event = EKEvent(eventStore: eventStore)
        event.startDate = selectedDate
        event.endDate = selectedDate.addingTimeInterval(3600) // 1 hour later
        editViewController.event = event
        
        return editViewController
    }
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        NotificationCenter.default.post(name: NSNotification.Name("DismissAddEventView"), object: nil)
        
        if action == .saved {
            fetchDailyEvents(for: selectedDate)
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

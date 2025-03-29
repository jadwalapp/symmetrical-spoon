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

/// ViewModel for managing calendar events and authorization status.
class CalendarViewModel: NSObject, ObservableObject, EKEventEditViewDelegate {
    let eventStore = EKEventStore()
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var selectedDate: Date = Date()
    @Published var dailyEvents: [EKEvent] = []
    @Published var monthlyEvents: [EKEvent] = []
    @Published var calendarSources: [EKSource] = []
    @Published var visibleCalendars: Set<EKCalendar> = []
    @Published var error: Error?
    @Published var isMonthView: Bool = true
    @Published var isLoading: Bool = false
    
    // Cache for monthly events
    private var eventCache: [String: [EKEvent]] = [:]
    private var lastFetchDates: [String: Date] = [:]
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
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
                self?.dailyEvents = fetchedEvents.sorted { $0.startDate < $1.startDate }
            }
        }
    }
    
    func fetchMonthlyEvents(for date: Date, forceRefresh: Bool = false) {
        let key = cacheKey(for: date)
        
        // Check cache first (unless force refresh is requested)
        if !forceRefresh && !shouldRefetchCache(for: date), let cachedEvents = eventCache[key] {
            self.monthlyEvents = cachedEvents
            // Notify about event update even when using cache
            NotificationCenter.default.post(name: NSNotification.Name("MonthlyEventsUpdated"), object: nil)
            return
        }
        
        isLoading = true
        
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: Array(visibleCalendars))
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fetchedEvents = self?.eventStore.events(matching: predicate) ?? []
            let sortedEvents = fetchedEvents.sorted { $0.startDate < $1.startDate }
            
            DispatchQueue.main.async {
                self?.monthlyEvents = sortedEvents
                self?.eventCache[key] = sortedEvents
                self?.lastFetchDates[key] = Date()
                self?.isLoading = false
                
                // Notify observers that events have been updated
                NotificationCenter.default.post(name: NSNotification.Name("MonthlyEventsUpdated"), object: nil)
            }
        }
    }
    
    func fetchEvents(for date: Date) {
        if isMonthView {
            fetchMonthlyEvents(for: date, forceRefresh: true)
        } else {
            fetchDailyEvents(for: date)
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
            fetchMonthlyEvents(for: selectedDate, forceRefresh: true)
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Calendar Management
    
    @MainActor
    func createCalendar(title: String, color: Color, source: EKSource) async {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = title
        calendar.source = source
        calendar.cgColor = UIColor(color).cgColor
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            fetchCalendarSources()
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    func updateCalendar(_ calendar: EKCalendar, title: String, color: Color) async {
        calendar.title = title
        calendar.cgColor = UIColor(color).cgColor
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            fetchCalendarSources()
        } catch {
            self.error = error
        }
    }
    
    func deleteCalendar(_ calendar: EKCalendar) {
        do {
            try eventStore.removeCalendar(calendar, commit: true)
            fetchCalendarSources()
        } catch {
            self.error = error
        }
    }
    
    func editCalendar(_ calendar: EKCalendar) {
        // This will be handled by the UI
    }
    
    // MARK: - Event Management
    
    func editEvent(_ event: EKEvent) -> EKEventEditViewController {
        let editViewController = EKEventEditViewController()
        editViewController.event = event
        editViewController.eventStore = eventStore
        editViewController.editViewDelegate = self
        return editViewController
    }
    
    private func cacheKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
    
    private func shouldRefetchCache(for date: Date) -> Bool {
        let key = cacheKey(for: date)
        guard let lastFetch = lastFetchDates[key] else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheDuration
    }
    
    func refreshAllEvents() {
        isLoading = true
        eventCache.removeAll()
        lastFetchDates.removeAll()
        fetchEvents(for: selectedDate)
        isLoading = false
    }
    
    // This ensures a smooth transition when switching to day view
    func prepareForDayView(date: Date) {
        // Pre-fetch the events for the day to ensure a smooth transition
        fetchDailyEvents(for: date)
        
        // Pre-fetch adjacent days for swiping experience
        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: date) {
            fetchDailyEvents(for: yesterday)
        }
        
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) {
            fetchDailyEvents(for: tomorrow)
        }
    }
}

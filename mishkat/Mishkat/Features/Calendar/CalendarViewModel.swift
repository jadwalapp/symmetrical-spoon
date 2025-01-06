//
//  CalendarViewModel.swift
//  Mishkat
//
//  Created by Human on 04/01/2025.
//

import Foundation

class CalendarViewModel: ObservableObject {
    @Published private(set) var calendarsWithCalendarAccountsState: AsyncValue<Calendar_V1_GetCalendarsWithCalendarAccountsResponse> = .idle
    @Published private(set) var createCalendarState: AsyncValue<Calendar_V1_CreateCalendarResponse> = .idle
    @Published private(set) var createEventState: AsyncValue<Calendar_V1_CreateEventResponse> = .idle
    
    private let calendarRepository: CalendarRepository
    init(calendarRepository: CalendarRepository) {
        self.calendarRepository = calendarRepository
    }
    
    func getCalendarsWithCalendarAccounts() {
        Task {
            await MainActor.run {
                self.calendarsWithCalendarAccountsState = .loading
            }
            
            do {
                let response = try await calendarRepository.getCalendarsWithCalendarAccounts()
                await MainActor.run {
                    self.calendarsWithCalendarAccountsState = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    self.calendarsWithCalendarAccountsState = .failed(error)
                }
            }
        }
    }
    
    func createCalendar(accountId: String, name: String, color: String) {
        Task {
            await MainActor.run {
                self.createCalendarState = .loading
            }
            
            do {
                let response = try await calendarRepository.createCalendar(
                    accountId: accountId,
                    name: name,
                    color: color
                )
                await MainActor.run {
                    self.createCalendarState = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    self.createCalendarState = .failed(error)
                }
            }
        }
    }
    
    func createEvent(calendarId: String, title: String, location: String, isAllDay: Bool, startDate: Date, endDate: Date) {
        Task {
            await MainActor.run {
                self.createEventState = .loading
            }
            
            do {
                let response = try await calendarRepository.createEvent(
                    calendarId: calendarId,
                    title: title,
                    location: location,
                    isAllDay: isAllDay,
                    startDate: startDate,
                    endDate: endDate
                )
                await MainActor.run {
                    self.createEventState = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    self.createEventState = .failed(error)
                }
            }
        }
    }
    
    func resetCreateCalendarState() {
        createCalendarState = .idle
    }
    
    func resetCreateEventState() {
        createEventState = .idle
    }
}

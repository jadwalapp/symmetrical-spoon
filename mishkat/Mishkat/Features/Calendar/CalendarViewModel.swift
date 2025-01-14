//
//  CalendarViewModel.swift
//  Mishkat
//
//  Created by Human on 04/01/2025.
//

import Foundation

class CalendarViewModel: ObservableObject {
    private let calendarRepository: CalendarRepository
    init(calendarRepository: CalendarRepository) {
        self.calendarRepository = calendarRepository
    }
}

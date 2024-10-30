//
//  CalendarView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import ElegantCalendar

struct CalendarView: View {
    let startDate = Date().addingTimeInterval(TimeInterval(60 * 60 * 24 * (-30 * 36)))
    let endDate = Date().addingTimeInterval(TimeInterval(60 * 60 * 24 * (30 * 36)))
    
    @ObservedObject var calMan: ElegantCalendarManager
    
    init() {
        calMan = ElegantCalendarManager(
            configuration: CalendarConfiguration(
                startDate: startDate,
                endDate: endDate
            ),
            initialMonth: Date()
        )
    }
    
    var body: some View {
        ElegantCalendarView(
            calendarManager: calMan
        )
        .theme(.kiwiGreen)
        .vertical()
    }
}

#Preview {
    CalendarView()
}

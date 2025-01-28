//
//  DateHelpers.swift
//  Mishkat
//
//  Created by Human on 17/01/2025.
//

import Foundation

struct DateHelpers {
    static func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    static func dayOfMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

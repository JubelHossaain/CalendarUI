//
//  Calendar+LastWeekday.swift
//  CalendarUI
//
//  Created by Appnap WS13 on 3/15/23.
//

import Foundation
extension Calendar {
    var lastWeekday: Int {
        let numDays = self.weekdaySymbols.count
        let res = (self.firstWeekday + numDays - 1) % numDays
        return res != 0 ? res : self.weekdaySymbols.count
    }
}

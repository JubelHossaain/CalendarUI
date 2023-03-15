//
//  String+CapitalizeFirstLetter.swift
//  CalendarUI
//
//  Created by Appnap WS13 on 3/15/23.
//

import Foundation
extension String {

    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

}

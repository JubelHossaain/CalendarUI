//
//  Config.swift
//  CalendarUI
//
//  Created by Appnap WS13 on 3/15/23.
//
import UIKit

/// Main configuration file
public struct Config {

    /**
     The default configuration.

     Fastis can be customized global or local.

     Modify this variable to customize all Fastis controllers in your app:
     ```swift
     Config.default.monthHeader.labelColor = .red
     ```

     Or you can copy and modify this config for some special controller:
     ```swift
     let config: Config = .default
     config.monthHeader.labelColor = .red
     let controller = FastisController(mode: .single, config: config)
     ```
     */
    public static var `default` = Config()

    private init() { }

    /**
     Base calendar used to build a view

     Default value — `.current`
     */
    public var calendar: Calendar = .current

    /// Base view controller (`cancelButtonTitle`, `doneButtonTitle`, etc.)
    public var controller = Config.Controller()

    /// Month titles
    public var monthHeader = Config.MonthHeader()
//
//    /// Day cells (selection parameters, font, etc.)
    public var dayCell = Config.DayCell()
//
//    /// Top header view with week day names
    public var weekView = Config.WeekView()
//
//    /// Current value view appearance (clear button, date format, etc.)
    public var currentValueView = Config.CurrentValueView()
//
//    /// Bottom view with shortcuts
    public var shortcutContainerView = Config.ShortcutContainerView()
//
//    /// Shortcut item in the bottom view
    public var shortcutItemView = Config.ShortcutItemView()

}

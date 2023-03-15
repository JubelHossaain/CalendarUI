//
//  CalendarViewController.swift
//  CalendarUI
//
//  Created by Appnap WS13 on 3/15/23.
//

import UIKit
import Foundation

class CalendarViewController: UIViewController {

    // MARK: - Outlets

    private lazy var cancelBarButtonItem: UIBarButtonItem = {
        if let customButton = self.appearance.customCancelButton {
            customButton.target = self
            customButton.action = #selector(self.cancel)
            return customButton
        }

        let barButtonItem = UIBarButtonItem(
            title: self.appearance.cancelButtonTitle,
            style: .plain,
            target: self,
            action: #selector(self.cancel)
        )
        barButtonItem.tintColor = self.appearance.barButtonItemsColor
        return barButtonItem
    }()

    private lazy var doneBarButtonItem: UIBarButtonItem = {
        if let customButton = self.appearance.customDoneButton {
            customButton.target = self
            customButton.action = #selector(self.done)
            return customButton
        }

        let barButtonItem = UIBarButtonItem(
            title: self.appearance.doneButtonTitle,
            style: .done,
            target: self,
            action: #selector(self.done)
        )
        barButtonItem.tintColor = self.appearance.barButtonItemsColor
        barButtonItem.isEnabled = self.allowToChooseNilDate
        return barButtonItem
    }()
    
//    private lazy var shortcutContainerView: ShortcutContainerView<Value> = {
//        let view = ShortcutContainerView<Value>(
//            config: self.config.shortcutContainerView,
//            itemConfig: self.config.shortcutItemView,
//            shortcuts: self.shortcuts
//        )
//        view.translatesAutoresizingMaskIntoConstraints = false
//        if let value = self.value {
//            view.selectedShortcut = self.shortcuts.first(where: { $0.isEqual(to: value) })
//        }
//        view.onSelect = { [weak self] selectedShortcut in
//            guard let self else { return }
//            let newValue = selectedShortcut.action()
//            if !newValue.outOfRange(minDate: self.privateMinimumDate, maxDate: self.privateMaximumDate) {
//                self.value = newValue
//               // self.selectValue(newValue, in: self.calendarView)
//            }
//        }
//        return view
//    }()
    
    private lazy var weekView: WeekView = {
        let view = WeekView(calendar: self.config.calendar, config: self.config.weekView)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Variables

    private let config: Config
    private var appearance: Config.Controller = Config.default.controller
    public var allowToChooseNilDate = false
    private var privateMinimumDate: Date?
    private var privateMaximumDate: Date?
    /**
     The block to execute after the dismissal finishes
     */
    public var dismissHandler: (() -> Void)?

    /**
     The block to execute after "Done" button will be tapped
     */
//    public var doneHandler: ((Value?) -> Void)?
//    private var value: Value? {
//        didSet {
////            self.updateSelectedShortcut()
////            self.currentValueView.currentValue = self.value
//            self.doneBarButtonItem.isEnabled = self.allowToChooseNilDate || self.value != nil
//        }
//    }
//    public var shortcuts: [FastisShortcut<Value>] = []
    
    //MARK: - LifeCycle
    /// Initiate FastisController
    /// - Parameter config: Configuration parameters
    public init(config: Config = .default) {
        self.config = config
        self.appearance = config.controller
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    private func configureUI() {
        self.view.backgroundColor = self.appearance.backgroundColor
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem
        self.navigationItem.rightBarButtonItem = self.doneBarButtonItem
    }

    
    //MARK: - Actions
//    private func updateSelectedShortcut() {
//        guard !self.shortcuts.isEmpty else { return }
//        if let value = self.value {
//            self.shortcutContainerView.selectedShortcut = self.shortcuts.first(where: { $0.isEqual(to: value) })
//        } else {
//            self.shortcutContainerView.selectedShortcut = nil
//        }
//    }
    
    @objc private func cancel() {
        self.navigationController?.popViewController(animated: true)
       
          //  self.dismissHandler?()
        
    }

    @objc private func done() {
       // self.doneHandler?(self.value)
        self.cancel()
    }
    
//    private func selectValue(_ value: Value?, in calendar: JTACMonthView) {
//        if let date = value as? Date {
//            calendar.selectDates([date])
//        } else if let range = value as? FastisRange {
//            self.selectRange(range, in: calendar)
//        }
//    }
    
}

public extension Config {
    
    /**
     Configuration of base view controller (`cancelButtonTitle`, `doneButtonTitle`, etc.)
     
     Configurable in Config.``Config/controller-swift.property`` property
     */
    struct Controller {
        
        /**
         Cancel button title
         
         Default value — `"Cancel"`
         */
        public var cancelButtonTitle = "Cancel"
        
        /**
         Done button title
         
         Default value — `"Done"`
         */
        public var doneButtonTitle = "Done"
        
        /**
         Controller's background color
         
         Default value — `.systemBackground`
         */
        public var backgroundColor: UIColor = .systemBackground
        
        /**
         Bar button items tint color
         
         Default value — `.systemBlue`
         */
        public var barButtonItemsColor: UIColor = .systemBlue
        
        /**
         Custom cancel button in navigation bar
         
         Default value — `nil`
         */
        public var customCancelButton: UIBarButtonItem?
        
        /**
         Custom done button in navigation bar
         
         Default value — `nil`
         */
        public var customDoneButton: UIBarButtonItem?
        
    }
}

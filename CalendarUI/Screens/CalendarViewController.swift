//
//  CalendarViewController.swift
//  CalendarUI
//
//  Created by Appnap WS13 on 3/15/23.
//

import UIKit
import Foundation
import JTAppleCalendar

class CalendarViewController<Value: FastisValue> : UIViewController,JTACMonthViewDelegate, JTACMonthViewDataSource{
    
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
    
    private lazy var calendarView: JTACMonthView = {
        let monthView = JTACMonthView()
        monthView.translatesAutoresizingMaskIntoConstraints = false
        monthView.backgroundColor = self.appearance.backgroundColor
        monthView.ibCalendarDelegate = self
        monthView.ibCalendarDataSource = self
        monthView.minimumLineSpacing = 2
        monthView.minimumInteritemSpacing = 0
        monthView.showsVerticalScrollIndicator = false
        monthView.cellSize = 46
        monthView.allowsMultipleSelection = Value.mode == .range
        monthView.allowsRangedSelection = true
        monthView.rangeSelectionMode = .continuous
        monthView.contentInsetAdjustmentBehavior = .always
        return monthView
    }()
    
    private lazy var currentValueView: CurrentValueView<Value> = {
        let view = CurrentValueView<Value>(config: self.config.currentValueView)
        view.currentValue = self.value
        view.translatesAutoresizingMaskIntoConstraints = false
        view.onClear = { [weak self] in
            guard let self else { return }
            self.value = nil
            self.viewConfigs.removeAll()
            self.calendarView.deselectAllDates()
            self.calendarView.visibleDates { segment in
                UIView.performWithoutAnimation {
                    self.calendarView.reloadItems(at: (segment.outdates + segment.indates).map(\.indexPath))
                }
            }
        }
        return view
    }()
    // MARK: - Variables
    
    private let config: Config
    private var appearance: Config.Controller = Config.default.controller
    private let dayCellReuseIdentifier = "DayCellReuseIdentifier"
    private let monthHeaderReuseIdentifier = "MonthHeaderReuseIdentifier"
    private var viewConfigs: [IndexPath: DayCell.ViewConfig] = [:]
    public var allowToChooseNilDate = false
    private var privateMinimumDate: Date?
    private var privateMaximumDate: Date?
    private var privateSelectMonthOnHeaderTap = false
    private var value: Value? {
        didSet {
            self.currentValueView.currentValue = self.value
            self.doneBarButtonItem.isEnabled = self.allowToChooseNilDate || self.value != nil
        }
    }
    /**
     The block to execute after the dismissal finishes
     */
    public var dismissHandler: (() -> Void)?
    
    public var initialValue: Value?
    
    /**
     Minimal selection date. Dates less then current will be marked as unavailable
     */
    public var minimumDate: Date? {
        get {
            self.privateMinimumDate
        }
        set {
            self.privateMinimumDate = newValue?.startOfDay()
        }
    }
    /**
     Maximum selection date. Dates greater then current will be marked as unavailable
     */
    public var maximumDate: Date? {
        get {
            self.privateMaximumDate
        }
        set {
            self.privateMaximumDate = newValue?.endOfDay()
        }
    }
    public var allowDateRangeChanges = false
    
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
        configureSubviews()
        configureConstraints()
    }
    
    // MARK: - Configuration
    private func configureUI() {
        self.view.backgroundColor = self.appearance.backgroundColor
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem
        self.navigationItem.rightBarButtonItem = self.doneBarButtonItem
    }
    
    private func configureSubviews() {
        self.calendarView.register(DayCell.self, forCellWithReuseIdentifier: self.dayCellReuseIdentifier)
        self.calendarView.register(
            MonthHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: self.monthHeaderReuseIdentifier
        )
        self.view.addSubview(self.currentValueView)
        self.view.addSubview(self.weekView)
        self.view.addSubview(self.calendarView)
        //        if !self.shortcuts.isEmpty {
        //            self.view.addSubview(self.shortcutContainerView)
        //        }
    }
    
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            self.currentValueView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.currentValueView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 12),
            self.currentValueView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -12)
        ])
        NSLayoutConstraint.activate([
            self.weekView.topAnchor.constraint(equalTo: self.currentValueView.bottomAnchor),
            self.weekView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 12),
            self.weekView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -12)
        ])
        
        NSLayoutConstraint.activate([
            self.calendarView.topAnchor.constraint(equalTo: self.weekView.bottomAnchor),
            self.calendarView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            self.calendarView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            self.calendarView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
//        calendarView.translatesAutoresizingMaskIntoConstraints = false
//        calendarView.anchorView(top: self.weekView.bottomAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingLeft: 16, paddingRight: -16)
        
    }
    
    private func configureInitialState() {
        self.value = self.initialValue
        if let date = self.value as? Date {
            self.calendarView.selectDates([date])
            self.calendarView.scrollToHeaderForDate(date)
        } else if let rangeValue = self.value as? FastisRange {
            self.selectRange(rangeValue, in: self.calendarView)
            self.calendarView.scrollToHeaderForDate(rangeValue.fromDate)
        } else {
            let nowDate = Date()
            let targetDate = self.privateMaximumDate ?? nowDate
            if targetDate < nowDate {
                self.calendarView.scrollToHeaderForDate(targetDate)
            } else {
                self.calendarView.scrollToHeaderForDate(Date())
            }
        }
    }
    private func configureCell(_ cell: JTACDayCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        guard let cell = cell as? DayCell else { return }
        if let cachedConfig = self.viewConfigs[indexPath] {
            cell.configure(for: cachedConfig)
        } else {
            let newConfig = DayCell.makeViewConfig(
                for: cellState,
                minimumDate: self.privateMinimumDate,
                maximumDate: self.privateMaximumDate,
                rangeValue: self.value as? FastisRange,
                calendar: self.config.calendar
            )
            self.viewConfigs[indexPath] = newConfig
            cell.applyConfig(self.config)
            cell.configure(for: newConfig)
        }
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
    
    private func selectRange(_ range: FastisRange, in calendar: JTACMonthView) {
        calendar.deselectAllDates(triggerSelectionDelegate: false)
        calendar.selectDates(
            from: range.fromDate,
            to: range.toDate,
            triggerSelectionDelegate: true,
            keepSelectionIfMultiSelectionAllowed: false
        )
        calendar.visibleDates { segment in
            UIView.performWithoutAnimation {
                calendar.reloadItems(at: (segment.outdates + segment.indates).map(\.indexPath))
            }
        }
    }
    
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
    private func selectValue(_ value: Value?, in calendar: JTACMonthView) {
        if let date = value as? Date {
            calendar.selectDates([date])
        } else if let range = value as? FastisRange {
            self.selectRange(range, in: calendar)
        }
    }
    private func handleDateTap(in calendar: JTACMonthView, date: Date) {

        switch Value.mode {
        case .single:
            self.value = date as? Value
            self.selectValue(date as? Value, in: calendar)
            return

        case .range:
            var newValue: FastisRange!
            if let currentValue = self.value as? FastisRange {

                let dateRangeChangesDisabled = !self.allowDateRangeChanges
                let rangeSelected = !currentValue.fromDate.isInSameDay(date: currentValue.toDate)
                if dateRangeChangesDisabled, rangeSelected {
                    newValue = .from(date.startOfDay(in: self.config.calendar), to: date.endOfDay(in: self.config.calendar))
                } else if date.isInSameDay(in: self.config.calendar, date: currentValue.fromDate) {
                    let newToDate = date.endOfDay(in: self.config.calendar)
                    newValue = .from(currentValue.fromDate, to: newToDate)
                } else if date.isInSameDay(in: self.config.calendar, date: currentValue.toDate) {
                    let newFromDate = date.startOfDay(in: self.config.calendar)
                    newValue = .from(newFromDate, to: currentValue.toDate)
                } else if date < currentValue.fromDate {
                    let newFromDate = date.startOfDay(in: self.config.calendar)
                    newValue = .from(newFromDate, to: currentValue.toDate)
                } else {
                    let newToDate = date.endOfDay(in: self.config.calendar)
                    newValue = .from(currentValue.fromDate, to: newToDate)
                }

            } else {
                newValue = .from(date.startOfDay(in: self.config.calendar), to: date.endOfDay(in: self.config.calendar))
            }

            self.value = newValue as? Value
            self.selectValue(newValue as? Value, in: calendar)

        }

    }

    // MARK: - JTACMonthViewDelegate
    
    public func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy MM dd"
        dateFormatter.timeZone = self.config.calendar.timeZone
        dateFormatter.locale = self.config.calendar.locale
        var startDate = dateFormatter.date(from: "2000 01 01")!
        var endDate = dateFormatter.date(from: "2030 12 01")!
        
        if let maximumDate = self.privateMaximumDate,
           let endOfNextMonth = self.config.calendar.date(byAdding: .month, value: 0, to: maximumDate)?
            .endOfMonth(in: self.config.calendar)
        {
            endDate = endOfNextMonth
        }
        
        if let minimumDate = self.privateMinimumDate,
           let startOfPreviousMonth = self.config.calendar.date(byAdding: .month, value: 0, to: minimumDate)?
            .startOfMonth(in: self.config.calendar)
        {
            startDate = startOfPreviousMonth
        }
        
        let parameters = ConfigurationParameters(
            startDate: startDate,
            endDate: endDate,
            numberOfRows: 6,
            calendar: self.config.calendar,
            generateInDates: .forAllMonths,
            generateOutDates: .tillEndOfRow,
            firstDayOfWeek: nil,
            hasStrictBoundaries: true
        )
        return parameters
    }
    
    func calendar(
        _ calendar: JTACMonthView,
        headerViewForDateRange range: (start: Date, end: Date),
        at indexPath: IndexPath
    ) -> JTACMonthReusableView {
        let header = calendar.dequeueReusableJTAppleSupplementaryView(
            withReuseIdentifier: self.monthHeaderReuseIdentifier,
            for: indexPath
        ) as! MonthHeader
        header.applyConfig(self.config.monthHeader)
        header.configure(for: range.start)
        if self.privateSelectMonthOnHeaderTap, Value.mode == .range {
            header.tapHandler = {
                var fromDate = range.start.startOfMonth(in: self.config.calendar)
                var toDate = range.start.endOfMonth(in: self.config.calendar)
                if let minDate = self.minimumDate {
                    if toDate < minDate { return } else if fromDate < minDate {
                        fromDate = minDate.startOfDay(in: self.config.calendar)
                    }
                }
                if let maxDate = self.maximumDate {
                    if fromDate > maxDate { return } else if toDate > maxDate {
                        toDate = maxDate.endOfDay(in: self.config.calendar)
                    }
                }
                let newValue: FastisRange = .from(fromDate, to: toDate)
                self.value = newValue as? Value
                self.selectRange(newValue, in: calendar)
            }
        }
        return header
    }
    
    func calendar(_ calendar: JTACMonthView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTACDayCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: self.dayCellReuseIdentifier, for: indexPath)
        self.configureCell(cell, forItemAt: date, cellState: cellState, indexPath: indexPath)
        return cell
    }
    
    func calendar(
        _ calendar: JTACMonthView,
        willDisplay cell: JTACDayCell,
        forItemAt date: Date,
        cellState: CellState,
        indexPath: IndexPath
    ) {
        self.configureCell(cell, forItemAt: date, cellState: cellState, indexPath: indexPath)
    }
    
    func calendar(
        _ calendar: JTACMonthView,
        didSelectDate date: Date,
        cell: JTACDayCell?,
        cellState: CellState,
        indexPath: IndexPath
    ) {
        if cellState.selectionType == .some(.userInitiated) {
            self.handleDateTap(in: calendar, date: date)
        } else if let cell {
            self.configureCell(cell, forItemAt: date, cellState: cellState, indexPath: indexPath)
        }
    }
    
    func calendar(
        _ calendar: JTACMonthView,
        didDeselectDate date: Date,
        cell: JTACDayCell?,
        cellState: CellState,
        indexPath: IndexPath
    ) {
        if cellState.selectionType == .some(.userInitiated), Value.mode == .range {
            self.handleDateTap(in: calendar, date: date)
        } else if let cell {
            self.configureCell(cell, forItemAt: date, cellState: cellState, indexPath: indexPath)
        }
    }
    
    func calendar(
        _ calendar: JTACMonthView,
        shouldSelectDate date: Date,
        cell: JTACDayCell?,
        cellState: CellState,
        indexPath: IndexPath
    ) -> Bool {
        self.viewConfigs.removeAll()
        return true
    }
    
    func calendar(
        _ calendar: JTACMonthView,
        shouldDeselectDate date: Date,
        cell: JTACDayCell?,
        cellState: CellState,
        indexPath: IndexPath
    ) -> Bool {
        self.viewConfigs.removeAll()
        return true
    }
    
    func calendarSizeForMonths(_ calendar: JTACMonthView?) -> MonthSize? {
        self.config.monthHeader.height
    }
}



extension CalendarViewController where Value == FastisRange {
    
    /// Initiate FastisController
    /// - Parameters:
    ///   - mode: Choose `.range` or `.single` mode
    ///   - config: Custom configuration parameters. Default value is equal to `FastisConfig.default`
    convenience init(mode: FastisModeRange, config: Config = .default) {
        self.init(config: config)
        // self.selectMonthOnHeaderTap = true
    }
    
    /**
     Set this variable to `true` if you want to allow select date ranges by tapping on months
     */
        var selectMonthOnHeaderTap: Bool {
            get {
                self.privateSelectMonthOnHeaderTap
            }
            set {
                self.privateSelectMonthOnHeaderTap = newValue
            }
        }
}

extension CalendarViewController where Value == Date {
    
    /// Initiate FastisController
    /// - Parameters:
    ///   - mode: Choose .range or .single mode
    ///   - config: Custom configuration parameters. Default value is equal to `FastisConfig.default`
    convenience init(mode: FastisModeSingle, config: Config = .default) {
        self.init(config: config)
    }
    
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

final class DayCell: JTACDayCell {

    // MARK: - Outlets

    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var selectionBackgroundView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var leftRangeView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var rightRangeView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Variables

    private var config: Config.DayCell = Config.default.dayCell
    private var rangeViewTopAnchorConstraints: [NSLayoutConstraint] = []
    private var rangeViewBottomAnchorConstraints: [NSLayoutConstraint] = []

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureSubviews()
        self.configureConstraints()
        self.applyConfig(.default)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configurations

    public func applyConfig(_ config: Config) {
        self.backgroundColor = config.controller.backgroundColor

        let config = config.dayCell
        self.config = config
        self.rightRangeView.backgroundColor = config.onRangeBackgroundColor
        self.leftRangeView.backgroundColor = config.onRangeBackgroundColor
        self.rightRangeView.layer.cornerRadius = config.rangeViewCornerRadius
        self.leftRangeView.layer.cornerRadius = config.rangeViewCornerRadius
        self.selectionBackgroundView.backgroundColor = config.selectedBackgroundColor
        self.dateLabel.font = config.dateLabelFont
        self.dateLabel.textColor = config.dateLabelColor
        if let cornerRadius = config.customSelectionViewCornerRadius {
            self.selectionBackgroundView.layer.cornerRadius = cornerRadius
        }
        self.rangeViewTopAnchorConstraints.forEach({ $0.constant = config.rangedBackgroundViewVerticalInset })
        self.rangeViewBottomAnchorConstraints.forEach({ $0.constant = -config.rangedBackgroundViewVerticalInset })
    }

    public func configureSubviews() {
        self.contentView.addSubview(self.leftRangeView)
        self.contentView.addSubview(self.rightRangeView)
        self.contentView.addSubview(self.selectionBackgroundView)
        self.contentView.addSubview(self.dateLabel)
        self.selectionBackgroundView.layer.cornerRadius = .minimum(self.frame.width, self.frame.height) / 2
    }

    public func configureConstraints() {
        let inset = self.config.rangedBackgroundViewVerticalInset
        NSLayoutConstraint.activate([
            self.dateLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.dateLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.dateLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.dateLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
        NSLayoutConstraint.activate([
            self.leftRangeView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.leftRangeView.rightAnchor.constraint(equalTo: self.contentView.centerXAnchor)
        ])
        NSLayoutConstraint.activate([
            self.rightRangeView.leftAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            // Add small offset to prevent spacing between cells
            self.rightRangeView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: 1)
        ])
        NSLayoutConstraint.activate([
            {
                let constraint = self.selectionBackgroundView.heightAnchor.constraint(equalToConstant: 100)
                constraint.priority = .defaultLow
                return constraint
            }(),
            self.selectionBackgroundView.leftAnchor.constraint(greaterThanOrEqualTo: self.contentView.leftAnchor, constant: 1),
            self.selectionBackgroundView.topAnchor.constraint(greaterThanOrEqualTo: self.contentView.topAnchor, constant: 1),
            self.selectionBackgroundView.rightAnchor.constraint(lessThanOrEqualTo: self.contentView.rightAnchor, constant: -1),
            self.selectionBackgroundView.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor, constant: -1),
            self.selectionBackgroundView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            self.selectionBackgroundView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.selectionBackgroundView.widthAnchor.constraint(equalTo: self.selectionBackgroundView.heightAnchor)
        ])
        self.rangeViewTopAnchorConstraints = [
            self.leftRangeView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: inset),
            self.rightRangeView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: inset)
        ]
        self.rangeViewBottomAnchorConstraints = [
            self.leftRangeView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -inset),
            self.rightRangeView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -inset)
        ]
        NSLayoutConstraint.activate(self.rangeViewTopAnchorConstraints)
        NSLayoutConstraint.activate(self.rangeViewBottomAnchorConstraints)
    }

    public static func makeViewConfig(
        for state: CellState,
        minimumDate: Date?,
        maximumDate: Date?,
        rangeValue: FastisRange?,
        calendar: Calendar
    ) -> ViewConfig {

        var config = ViewConfig()

        if state.dateBelongsTo != .thisMonth {

            config.isSelectedViewHidden = true

            if let value = rangeValue {

                let calendar = Calendar.current
                var showRangeView = false

                if state.dateBelongsTo == .followingMonthWithinBoundary {
                    let endOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: state.date)!.endOfMonth(in: calendar)
                    let startOfCurrentMonth = state.date.startOfMonth(in: calendar)
                    let fromDateIsInPast = value.fromDate < endOfPreviousMonth
                    let toDateIsInFutureOrCurrent = value.toDate > startOfCurrentMonth
                    showRangeView = fromDateIsInPast && toDateIsInFutureOrCurrent
                } else if state.dateBelongsTo == .previousMonthWithinBoundary {
                    let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: state.date)!.startOfMonth(in: calendar)
                    let endOfCurrentMonth = state.date.endOfMonth(in: calendar)
                    let toDateIsInFuture = value.toDate > startOfNextMonth
                    let fromDateIsInPastOrCurrent = value.fromDate < endOfCurrentMonth
                    showRangeView = toDateIsInFuture && fromDateIsInPastOrCurrent
                }

                if showRangeView {

                    if state.day.rawValue == calendar.firstWeekday {
                        config.rangeView.leftSideState = .rounded
                        config.rangeView.rightSideState = .squared
                    } else if state.day.rawValue == calendar.lastWeekday {
                        config.rangeView.leftSideState = .squared
                        config.rangeView.rightSideState = .rounded
                    } else {
                        config.rangeView.leftSideState = .squared
                        config.rangeView.rightSideState = .squared
                    }
                }

            }

            return config
        }

        config.dateLabelText = state.text

        if let minimumDate, state.date < minimumDate.startOfDay() {
            config.isDateEnabled = false
            return config
        } else if let maximumDate, state.date > maximumDate.endOfDay() {
            config.isDateEnabled = false
            return config
        }

        if state.isSelected {

            let position = state.selectedPosition()

            switch position {

            case .full:
                config.isSelectedViewHidden = false

            case .left,
                 .right,
                 .middle:
                config.isSelectedViewHidden = position == .middle

                if position == .right, state.day.rawValue == calendar.firstWeekday {
                    config.rangeView.leftSideState = .rounded

                } else if position == .left, state.day.rawValue == calendar.lastWeekday {
                    config.rangeView.rightSideState = .rounded

                } else if position == .left {
                    config.rangeView.rightSideState = .squared

                } else if position == .right {
                    config.rangeView.leftSideState = .squared

                } else if state.day.rawValue == calendar.firstWeekday {
                    config.rangeView.leftSideState = .rounded
                    config.rangeView.rightSideState = .squared

                } else if state.day.rawValue == calendar.lastWeekday {
                    config.rangeView.leftSideState = .squared
                    config.rangeView.rightSideState = .rounded

                } else {
                    config.rangeView.leftSideState = .squared
                    config.rangeView.rightSideState = .squared
                }

            default:
                break
            }

        }

        return config
    }

    enum RangeSideState {
        case squared
        case rounded
        case hidden
    }

    struct RangeViewConfig: Hashable {

        var leftSideState: RangeSideState = .hidden
        var rightSideState: RangeSideState = .hidden

        var isHidden: Bool {
            self.leftSideState == .hidden && self.rightSideState == .hidden
        }

    }

    struct ViewConfig {
        var dateLabelText: String?
        var isSelectedViewHidden = true
        var isDateEnabled = true
        var rangeView = RangeViewConfig()
    }

    internal func configure(for config: ViewConfig) {

        self.selectionBackgroundView.isHidden = config.isSelectedViewHidden
        self.isUserInteractionEnabled = config.dateLabelText != nil && config.isDateEnabled
        self.clipsToBounds = config.dateLabelText == nil

        if let dateLabelText = config.dateLabelText {
            self.dateLabel.isHidden = false
            self.dateLabel.text = dateLabelText
            if !config.isDateEnabled {
                self.dateLabel.textColor = self.config.dateLabelUnavailableColor
            } else if !config.isSelectedViewHidden {
                self.dateLabel.textColor = self.config.selectedLabelColor
            } else if !config.rangeView.isHidden {
                self.dateLabel.textColor = self.config.onRangeLabelColor
            } else {
                self.dateLabel.textColor = self.config.dateLabelColor
            }

        } else {
            self.dateLabel.isHidden = true
        }

        switch config.rangeView.rightSideState {
        case .squared:
            self.rightRangeView.isHidden = false
            self.rightRangeView.layer.maskedCorners = []
        case .rounded:
            self.rightRangeView.isHidden = false
            self.rightRangeView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        case .hidden:
            self.rightRangeView.isHidden = true
        }

        switch config.rangeView.leftSideState {
        case .squared:
            self.leftRangeView.isHidden = false
            self.leftRangeView.layer.maskedCorners = []
        case .rounded:
            self.leftRangeView.isHidden = false
            self.leftRangeView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        case .hidden:
            self.leftRangeView.isHidden = true
        }

    }

}

public extension Config {

    /**
     Day cells (selection parameters, font, etc.)

     Configurable in FastisConfig.``FastisConfig/dayCell-swift.property`` property
     */
    struct DayCell {

        /**
         Font of date label in cell

         Default value — `.systemFont(ofSize: 17)`
         */
        public var dateLabelFont: UIFont = .systemFont(ofSize: 17)

        /**
         Color of date label in cell

         Default value — `.label`
         */
        public var dateLabelColor: UIColor = .label

        /**
         Color of date label in cell when date is unavailable for select

         Default value — `.tertiaryLabel`
         */
        public var dateLabelUnavailableColor: UIColor = .tertiaryLabel

        /**
         Color of background of cell when date is selected

         Default value — `.systemBlue`
         */
        public var selectedBackgroundColor: UIColor = .systemBlue

        /**
         Color of date label in cell when date is selected

         Default value — `.white`
         */
        public var selectedLabelColor: UIColor = .white

        /**
         Corner radius of cell when date is a start or end of selected range

         Default value — `6pt`
         */
        public var rangeViewCornerRadius: CGFloat = 6

        /**
         Color of background of cell when date is a part of selected range

         Default value — `.systemBlue.withAlphaComponent(0.2)`
         */
        public var onRangeBackgroundColor: UIColor = .systemBlue.withAlphaComponent(0.2)

        /**
         Color of date label in cell when date is a part of selected range

         Default value — `.label`
         */
        public var onRangeLabelColor: UIColor = .label

        /**
         Inset of cell's background view when date is a part of selected range

         Default value — `3pt`
         */
        public var rangedBackgroundViewVerticalInset: CGFloat = 3

        /**
          This property allows to set custom radius for selection view

          If this value is not `nil` then selection view will have corner radius `.height / 2`

          Default value — `nil`
         */
        public var customSelectionViewCornerRadius: CGFloat?
    }

}


//public extension Config {
//
//    /**
//     Day cells (selection parameters, font, etc.)
//
//     Configurable in FastisConfig.``FastisConfig/dayCell-swift.property`` property
//     */
//    struct DayCell {
//
//        /**
//         Font of date label in cell
//
//         Default value — `.systemFont(ofSize: 17)`
//         */
//        public var dateLabelFont: UIFont = .systemFont(ofSize: 17)
//
//        /**
//         Color of date label in cell
//
//         Default value — `.label`
//         */
//        public var dateLabelColor: UIColor = .label
//
//        /**
//         Color of date label in cell when date is unavailable for select
//
//         Default value — `.tertiaryLabel`
//         */
//        public var dateLabelUnavailableColor: UIColor = .tertiaryLabel
//
//        /**
//         Color of background of cell when date is selected
//
//         Default value — `.systemBlue`
//         */
//        public var selectedBackgroundColor: UIColor = .systemBlue
//
//        /**
//         Color of date label in cell when date is selected
//
//         Default value — `.white`
//         */
//        public var selectedLabelColor: UIColor = .white
//
//        /**
//         Corner radius of cell when date is a start or end of selected range
//
//         Default value — `6pt`
//         */
//        public var rangeViewCornerRadius: CGFloat = 6
//
//        /**
//         Color of background of cell when date is a part of selected range
//
//         Default value — `.systemBlue.withAlphaComponent(0.2)`
//         */
//        public var onRangeBackgroundColor: UIColor = .systemBlue.withAlphaComponent(0.2)
//
//        /**
//         Color of date label in cell when date is a part of selected range
//
//         Default value — `.label`
//         */
//        public var onRangeLabelColor: UIColor = .label
//
//        /**
//         Inset of cell's background view when date is a part of selected range
//
//         Default value — `3pt`
//         */
//        public var rangedBackgroundViewVerticalInset: CGFloat = 3
//
//        /**
//         This property allows to set custom radius for selection view
//
//         If this value is not `nil` then selection view will have corner radius `.height / 2`
//
//         Default value — `nil`
//         */
//        public var customSelectionViewCornerRadius: CGFloat?
//    }
//
//}

//open class JTACDayCell: UICollectionViewCell {
//    @available(*, message: "Using isSelected only to determing when selection occurs is ok. For other cases please use cellState.isSelected to avoid synchronization issues.")
//    open override var isSelected: Bool {
//        get { return super.isSelected }
//        set { super.isSelected = newValue}
//    }
//
//    /// Cell view that will be customized
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//
//    /// Returns an object initialized from data in a given unarchiver.
//    required public init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//
//    /// Prepares the receiver for service after it has been loaded from an Interface Builder archive, or nib file.
//    open override func awakeFromNib() {
//        super.awakeFromNib()
//
//        self.contentView.frame = self.bounds
//        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//    }
//
//}
//
//
//
//public struct CellState {
//    /// returns true if a cell is selected
//    public let isSelected: Bool
//    /// returns the date as a string
//    public let text: String
//    /// returns the a description of which month owns the date
//    public let dateBelongsTo: DateOwner
//    /// returns the date
//    public let date: Date
//    /// returns the day
//    public let day: DaysOfWeek
//    /// returns the row in which the date cell appears visually
//    public let row: () -> Int
//    /// returns the column in which the date cell appears visually
//    public let column: () -> Int
//    /// returns the section the date cell belongs to
//    public let dateSection: () -> (range: (start: Date, end: Date), month: Int, rowCount: Int)
//    /// returns the position of a selection in the event you wish to do range selection
//    public let selectedPosition: () -> SelectionRangePosition
//    /// returns the cell.
//    /// Useful if you wish to display something at the cell's frame/position
//    public var cell: () -> JTACDayCell?
//    /// Shows if a cell's selection/deselection was done either programatically or by the user
//    /// This variable is guranteed to be non-nil inside of a didSelect/didDeselect function
//    public var selectionType: SelectionType? = nil
//}
//
//
///// Describes which month owns the date
//public enum DateOwner: Int {
//    /// Describes which month owns the date
//    case thisMonth = 0,
//         previousMonthWithinBoundary,
//         previousMonthOutsideBoundary,
//         followingMonthWithinBoundary,
//         followingMonthOutsideBoundary
//}
///// Months of the year
//public enum MonthsOfYear: Int, CaseIterable {
//    case jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec
//}
//
///// Selection position of a range-selected date cell
//public enum SelectionRangePosition: Int {
//    /// Selection position
//    case left = 1, middle, right, full, none
//}
//
///// Between month segments, the range selection can either be visually disconnected or connected
//public enum RangeSelectionMode {
//    case segmented, continuous
//}
//
///// Signifies whether or not a selection was done programatically or by the user
//public enum SelectionType: String {
//    /// Selection type
//    case programatic, userInitiated
//}
//
///// Days of the week. By setting your calendar's first day of the week,
///// you can change which day is the first for the week. Sunday is the default value.
//public enum DaysOfWeek: Int, CaseIterable {
//    /// Days of the week.
//    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
//}
//
//internal enum DelayedTaskType {
//    case scroll, general
//}
//
//internal enum SelectionAction {
//    case didSelect, didDeselect
//}
//
//internal enum ShouldSelectionAction {
//    case shouldSelect, shouldDeselect
//}

//
//  ViewController.swift
//  CalendarUI
//
//  Created by Appnap WS13 on 3/14/23.
//

import UIKit

class HomeViewController: UIViewController,SKUIDatePickerDelegate {
    // MARK: - Outlets
   
    lazy var chooseRangeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Show Calendar", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(self.chooseRange), for: .touchUpInside)
        return button
    }()
    
    lazy var startTextField : UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter Start Date"
        textField.keyboardType = UIKeyboardType.default
        textField.returnKeyType = UIReturnKeyType.done
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.font = UIFont.systemFont(ofSize: 13)
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.clearButtonMode = UITextField.ViewMode.whileEditing;
        textField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        return textField
    }()
    
    lazy var endDateTxtField : UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter End Date"
        textField.keyboardType = UIKeyboardType.default
        textField.returnKeyType = UIReturnKeyType.done
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.font = UIFont.systemFont(ofSize: 13)
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.clearButtonMode = UITextField.ViewMode.whileEditing;
        textField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        textField.addTarget(self, action: #selector(myTargetFunction), for: .touchDown)
        return textField
    }()
    
    // MARK: - Variables
    private var isEndTextFieldSelected : Bool = false
    private var skUIdatePicker: SKUIDatePicker?
   
    var currentValue: FastisValue? {
        didSet {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            if let rangeValue = self.currentValue as? FastisRange {
                //self.currentDateLabel.text = formatter.string(from: rangeValue.fromDate) + " - " + formatter.string(from: rangeValue.toDate)
            } else if let date = self.currentValue as? Date {
              //  self.currentDateLabel.text = formatter.string(from: date)
            } else {
               // self.currentDateLabel.text = "Choose a date"
            }
        }
    }
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.configureUI()
        self.configureSubviews()
        
        skUIdatePicker = SKUIDatePicker()
        skUIdatePicker!.delegate = self
        skUIdatePicker!.showDatePicker(txtDatePicker: startTextField)
        //skUIdatePicker!.showDatePicker(txtDatePicker: endDateTxtField)
    }
    
    // MARK: - Configuration
    
   
    private func configureUI() {
        self.view.backgroundColor = .systemBackground
        self.navigationItem.title = "Celendar demo"
        self.navigationItem.largeTitleDisplayMode = .always
    }
    /**
     Present FastisController above current top view controller

     - Parameters:
        - viewController: view controller which will present FastisController
        - flag: Pass true to animate the presentation; otherwise, pass false.
        - completion: The block to execute after the presentation finishes. This block has no return value and takes no parameters. You may specify nil for this parameter.
     */
//     func present(above viewController: UIViewController, animated flag: Bool = true, completion: (() -> Void)? = nil) {
//        let navVc = UINavigationController(rootViewController: self)
//        navVc.modalPresentationStyle = .formSheet
//        if viewController.preferredContentSize != .zero {
//            navVc.preferredContentSize = viewController.preferredContentSize
//        } else {
//            navVc.preferredContentSize = CGSize(width: 445, height: 550)
//        }
//
//        viewController.present(navVc, animated: flag, completion: completion)
//    }
    
    private func configureSubviews() {
        self.view.addSubview(self.chooseRangeButton)
        self.view.addSubview(startTextField)
        self.view.addSubview(endDateTxtField)
        chooseRangeButton.centerX(inView: self.view)
        chooseRangeButton.centerY(inView: self.view)
        startTextField.anchorView(top: chooseRangeButton.bottomAnchor,paddingTop: 30)
        startTextField.centerX(inView: self.view)
        startTextField.setDimensions(width: 200, height: 50)
        
        endDateTxtField.anchorView(top: startTextField.bottomAnchor,paddingTop: 30)
        endDateTxtField.centerX(inView: self.view)
        endDateTxtField.setDimensions(width: 200, height: 50)
    }
    
    func datesRange(from: Date, to: Date) -> [Date] {
        // in case of the "from" date is more than "to" date,
        // it should returns an empty array:
        if from > to { return [Date]() }
        
        var tempDate = from
        var array = [tempDate]
        
        while tempDate < to {
            tempDate = Calendar.current.date(byAdding: .day, value: 1, to: tempDate)!
            array.append(tempDate)
        }
        
        return array
    }
    
    // MARK: - Actions
    @objc func myTargetFunction(textField: UITextField) {
        print("myTargetFunction")
        isEndTextFieldSelected = true
        skUIdatePicker!.showDatePicker(txtDatePicker: endDateTxtField)
    }
    public var minimumDate: Date?
    public var maximumDate: Date?
    @objc private func chooseRange() {
        
        let calendarViewController = CalendarViewController(mode: .range)
        calendarViewController.initialValue = self.currentValue as? FastisRange
        calendarViewController.minimumDate = minimumDate
        print("minimum Data : \(calendarViewController.minimumDate)")
        calendarViewController.maximumDate = maximumDate
        print("maximumDate Data : \(calendarViewController.maximumDate)")
        calendarViewController.allowToChooseNilDate = true
        calendarViewController.doneHandler = { newValue in
            self.currentValue = newValue
            
        }
////        fastisController.title = "Choose range"
////        fastisController.initialValue = self.currentValue as? FastisRange
////        fastisController.minimumDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
////        print("minimum Data : \(fastisController.minimumDate)")
////        fastisController.maximumDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
////        print("maximumDate Data : \(fastisController.maximumDate)")
////        fastisController.allowToChooseNilDate = true
////       // fastisController.shortcuts = [.today, .lastWeek, .lastMonth]
////        fastisController.doneHandler = { newValue in
////            self.currentValue = newValue
////        }
        self.navigationController?.pushViewController(calendarViewController, animated: true)
      //  let today = Date()
//        let nextFiveDays = Calendar.current.date(byAdding: .day, value: 5, to: today)!
//
//        let myRange = datesRange(from: today, to: nextFiveDays)
//        print(myRange)
        //        let fastisController = FastisController(mode: .range)
        //        fastisController.title = "Choose range"
        //        fastisController.initialValue = self.currentValue as? FastisRange
        //        fastisController.minimumDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        //        print("minimum Data : \(fastisController.minimumDate)")
        //        fastisController.maximumDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        //        print("maximumDate Data : \(fastisController.maximumDate)")
        //        fastisController.allowToChooseNilDate = true
        //       // fastisController.shortcuts = [.today, .lastWeek, .lastMonth]
        //        fastisController.doneHandler = { newValue in
        //            self.currentValue = newValue
        //        }
        //        fastisController.present(above: self)
        
    }
    
    func getDate(_ sKUIDatePicker:SKUIDatePicker, date: Date) {
        print(date)
        if isEndTextFieldSelected {
            endDateTxtField.text = "\(date)"
            maximumDate = date
        }
        else {
            startTextField.text = "\(date)"
            minimumDate = date
        }
        
        self.view.endEditing(true)
    }
    func cancel(_ sKUIDatePicker:SKUIDatePicker){
        self.view.endEditing(true)
    }
    
}


import UIKit

protocol SKUIDatePickerDelegate: AnyObject {
    func getDate(_ sKUIDatePicker:SKUIDatePicker, date: Date)
    func cancel(_ sKUIDatePicker:SKUIDatePicker)
}

class SKUIDatePicker:UIView {
    
    private let datePicker = UIDatePicker()
    private var dateFormate = "dd/MM/yyyy"
    weak var delegate:SKUIDatePickerDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // self.frame = UIScreen.main.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showDatePicker(txtDatePicker:UITextField){
        //Formate Date
        datePicker.datePickerMode = .date
        
        //ToolBar
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action:       #selector(donedatePicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem:       UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action:       #selector(cancelDatePicker));
        
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated:       false)
        
        txtDatePicker.inputAccessoryView = toolbar
        txtDatePicker.inputView = datePicker
        
    }
    
    @objc func donedatePicker(){
        
//        let formatter = DateFormatter()
//        formatter.dateFormat = dateFormate
//        let result = formatter.string(from: datePicker.date)
        self.delegate?.getDate(self, date: datePicker.date)
        
    }
    
    @objc func cancelDatePicker(){
        self.delegate?.cancel(self)
    }
    
}

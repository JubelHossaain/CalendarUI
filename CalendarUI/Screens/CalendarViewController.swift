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

    // MARK: - Variables

    private let config: Config
    private var appearance: Config.Controller = Config.default.controller
    
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

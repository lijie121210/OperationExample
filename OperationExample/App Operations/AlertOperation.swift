//
//  AlertOperation.swift
//  OperationExample
//
//  Created by viwii on 2019/9/10.
//  Copyright © 2019 viwii. All rights reserved.
//

import UIKit
import OperationSample

open class AlertOperation: AnyOperation {
    
    private let controller = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    private weak var presentationContext: UIViewController?
    
    open var title: String? {
        get { controller.title }
        set {
            name = newValue
            controller.title = newValue
        }
    }
    
    open var message: String? {
        get { controller.message }
        set { controller.message = newValue }
    }
    
    public init(presentationContext: UIViewController? = nil) {
        self.presentationContext = presentationContext

        super.init()
        
        addCondition(AlertPresentation())
        
        /*
            This operation modifies the view controller hierarchy.
            Doing this while other such operations are executing can lead to
            inconsistencies in UIKit. So, let's make them mutally exclusive.
        */
        addCondition(MutuallyExclusive<UIViewController>())
    }
    
    public func addAction(title: String, style: UIAlertAction.Style = .default, handler: @escaping (AlertOperation) -> Void = { _ in }) {
        let action = UIAlertAction(title: title, style: style) { [weak self] (_) in
            guard let self = self else { return }
            handler(self)
            self.finish()
        }
        controller.addAction(action)
    }
    
    public override func execute() {
        DispatchQueue.main.async {
            var viewController: UIViewController? = nil
            if #available(iOS 13.0, *) {
                viewController = self.presentationContext
            } else {
                viewController = self.presentationContext ?? UIApplication.shared.keyWindow?.rootViewController
            }
            
            guard let context = viewController else {
                self.finish()
                return
            }
            if self.controller.actions.isEmpty {
                self.addAction(title: "OK")
            }
            
            context.present(self.controller, animated: true, completion: nil)
        }
    }
}

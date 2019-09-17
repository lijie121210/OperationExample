//
//  BackgroundObserver.swift
//  OperationExample
//
//  Created by viwii on 2019/9/15.
//  Copyright © 2019 viwii. All rights reserved.
//

import Foundation
import UIKit
import OperationSample

/**
    `BackgroundObserver` is an `OperationObserver` that will automatically begin
    and end a background task if the application transitions to the background.
    This would be useful if you had a vital `Operation` whose execution *must* complete,
    regardless of the activation state of the app. Some kinds network connections
    may fall in to this category, for example.
*/
open class BackgroundObserver: NSObject, OperationObserver {
    
    private var identifier = UIBackgroundTaskIdentifier.invalid
    private var isInBackground = false
    
    public override init() {
        super.init()
        
        let center = NotificationCenter.default
        
        center.addObserver(
            self,
            selector: #selector(didEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(didEnterForeground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        isInBackground = UIApplication.shared.applicationState == .background
        
        // If we're in the background already, immediately begin the background task.
        if isInBackground {
            startBackgroundTask()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didEnterBackground(_ notification: Notification) {
        guard !isInBackground else {
            return
        }
        isInBackground = true
        startBackgroundTask()
    }
    
    @objc private func didEnterForeground(_ notification: Notification) {
        guard isInBackground else {
            return
        }
        isInBackground = false
        endBackgroundTask()
    }
    
    private func startBackgroundTask() {
        guard identifier == UIBackgroundTaskIdentifier.invalid else {
            return
        }
        identifier = UIApplication.shared.beginBackgroundTask(withName: "BackgroundObserver", expirationHandler: { [weak self] in
            self?.endBackgroundTask()
        })
    }
    
    private func endBackgroundTask() {
        guard identifier != UIBackgroundTaskIdentifier.invalid else {
            return
        }
        UIApplication.shared.endBackgroundTask(identifier)
        identifier = UIBackgroundTaskIdentifier.invalid
    }
    
    public func operationDidStart(_ operation: AnyOperation) {
        
    }
    
    public func operation(_ operation: AnyOperation, didProduceOperation newOperation: Operation) {
        
    }
    
    public func operation(_ operation: AnyOperation, didFinishWithErrors: [NSError]) {
        endBackgroundTask()
    }
}

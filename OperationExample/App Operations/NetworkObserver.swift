//
//  NetworkObserver.swift
//  OperationExample
//
//  Created by viwii on 2019/9/14.
//  Copyright © 2019 viwii. All rights reserved.
//

import Foundation
import UIKit
import OperationSample

/**
    An `OperationObserver` that will cause the network activity indicator to appear
    as long as the `Operation` to which it is attached is executing.
*/
public struct NetworkObserver: OperationObserver {
    
    init() { }
    
    public func operationDidStart(_ operation: AnyOperation) {
        DispatchQueue.main.async {
            IndicatorController.shared.activityDidStart()
        }
    }
    
    public func operation(_ operation: AnyOperation, didProduceOperation newOperation: Operation) {
        
    }
    
    public func operation(_ operation: AnyOperation, didFinishWithErrors: [NSError]) {
        DispatchQueue.main.async {
            IndicatorController.shared.activityDidEnd()
        }
    }
}

extension NetworkObserver {
    
    class IndicatorController {
        
        static let shared = IndicatorController()
        
        private var activityCount = 0
        private var visibilityTimer: CancellableDispatchQueue?
        
        func activityDidStart() {
            assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")

            activityCount += 1
            
            updateIndicatorVisibility()
        }
        
        func activityDidEnd() {
            assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")

            activityCount -= 1
            
            updateIndicatorVisibility()
        }
        
        private func updateIndicatorVisibility() {
            if activityCount > 0 {
                showIndicator()
            } else {
                /*
                    To prevent the indicator from flickering on and off, we delay the
                    hiding of the indicator by one second. This provides the chance
                    to come in and invalidate the timer before it fires.
                */
                visibilityTimer = CancellableDispatchQueue(interval: 1.0, handler: {
                    self.hideIndicator()
                })
            }
        }
        
        private func showIndicator() {
            visibilityTimer?.cancel()
            visibilityTimer = nil
            //
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        private func hideIndicator() {
            visibilityTimer?.cancel()
            visibilityTimer = nil
            //
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}

open class CancellableDispatchQueue {
    
    private var isCancelled = false
    
    public init(interval: TimeInterval, handler: @escaping () -> Void) {
        let when = DispatchTime.now() + interval
        
        DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
            if let self = self, !self.isCancelled {
                handler()
            }
        }
    }
    
    open func cancel() {
        isCancelled = true
    }
}

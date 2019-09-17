//
//  MoreInformationOperation.swift
//  OperationExample
//
//  Created by viwii on 2019/9/12.
//  Copyright © 2019 viwii. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import OperationSample

/// An `Operation` to display an `NSURL` in an app-modal `SFSafariViewController`.
open class MoreInformationOperation: AnyOperation {
    
    public let url: URL
    
    public init(url: URL) {
        self.url = url
        
        super.init()
        
        addCondition(MutuallyExclusive<UIViewController>())
    }
    
    open override func execute() {
        DispatchQueue.main.async {
            self.showSafariViewController()
        }
    }
    
    private func showSafariViewController() {
        guard let context = UIApplication.shared.keyWindow?.rootViewController else {
            finish()
            return
        }

        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        
        let webPage = SFSafariViewController(url: url, configuration: config)
        webPage.delegate = self
        
        context.present(webPage, animated: true, completion: nil)
    }
}

extension MoreInformationOperation : SFSafariViewControllerDelegate {
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
        finish()
    }
}

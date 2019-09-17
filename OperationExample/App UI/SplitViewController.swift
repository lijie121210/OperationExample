//
//  SplitViewController.swift
//  OperationExample
//
//  Created by viwii on 2019/9/16.
//  Copyright © 2019 viwii. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        preferredDisplayMode = .allVisible
        delegate = self
        
    }
}

extension SplitViewController: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let navi = secondaryViewController as? UINavigationController,
            let earthquake = navi.viewControllers.first as? EarthquakeTableViewController else {
                return false
        }
        return earthquake.earthquake == nil
    }
}

//
//  GetEarthquakesOperation.swift
//  OperationExample
//
//  Created by viwii on 2019/9/14.
//  Copyright © 2019 viwii. All rights reserved.
//

import Foundation
import CoreData
import CoreDataPlatform
import OperationSample

open class GetEarthquakesOperation: GroupOperation {
    
    let downloadOperation: DownloadEarthquakesOperation
    let parseOperation: ParseEarthquakeOperation
    
    private var hasProducedAlert = false
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             Earthquakes will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init(context: NSManagedObjectContext, handler: @escaping () -> Void) {
        let cachesFolder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let cacheFile = cachesFolder.appendingPathComponent("earthquakes.json")
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        */
        downloadOperation = DownloadEarthquakesOperation(cacheFile: cacheFile)
        parseOperation = ParseEarthquakeOperation(cacheFile: cacheFile, context: context)
        
        let finishOperation = BlockOperation(block: handler)
        
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        super.init([downloadOperation, parseOperation, finishOperation])
        
        name = "Get Earthquakes"
    }
    
    open override func operation(_ op: Operation, didFinishWithErrors errors: [NSError]) {
        if let firstError = errors.first,
            (op === downloadOperation || parseOperation === parseOperation ) {
            produceAlert(error: firstError)
        }
    }
    
    private func produceAlert(error: NSError) {
        /*
            We only want to show the first error, since subsequent errors might
            be caused by the first.
        */
        if hasProducedAlert { return }
        
        var title: String? = nil
        var message: String? = nil
        
        switch (error.domain,
                error.code,
                error.userInfo(for: .operationConditionKey)) {
            
        case (OperationErrorDomain,
              OperationError.Code.conditionFailed.rawValue,
              let reason as String) where reason == ReachabilityCondition.name:
            
            // We failed because the network isn't reachable.
            let hostURL = error.userInfo(for: .reachabilityHostKey) as! URL
            
            title = "Unable to Connect"
            message = "Cannot connect to \(hostURL.host!). Make sure your device is connected to the internet and try again."
            
        case (NSCocoaErrorDomain,
              NSPropertyListReadCorruptError,
              _):
            
            // We failed because the JSON was malformed.
            title = "Unable to Download"
            message = "Cannot download earthquake data. Try again later."

        default:
            return
        }
        
        let alert = AlertOperation()
        
        DispatchQueue.main.async {
            alert.title = title
            alert.message = message
        }
        
        produceOperation(alert)
        hasProducedAlert = true
    }
}

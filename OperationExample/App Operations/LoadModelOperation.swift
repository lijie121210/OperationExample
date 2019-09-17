//
//  LoadModelOperation.swift
//  OperationExample
//
//  Created by viwii on 2019/9/10.
//  Copyright © 2019 viwii. All rights reserved.
//

import UIKit
import CoreData
import OperationSample
import CoreDataPlatform

/**
    An `Operation` subclass that loads the Core Data stack. If this operation fails,
    it will produce an `AlertOperation` that will offer to retry the operation.
*/
open class LoadModelOperation: AnyOperation {

    public let loadHandler: (NSManagedObjectContext) -> Void
    
    public init(handler: @escaping (NSManagedObjectContext) -> Void) {
        loadHandler = handler
        
        super.init()
        
        addCondition(MutuallyExclusive<LoadModelOperation>())
    }
    
    open override func execute() {
        let container = PersistentContainerProvider().earthquakePersistentContainer()
        container.loadPersistentStores { [weak self] (description, error) in
            if let error = error as NSError? {
                self?.finish(with: error)
            } else {
                self?.loadHandler(container.viewContext)
                self?.finish()
            }
        }
    }
    
    open override func finished(errors: [NSError]) {
        guard let firstError = errors.first, isUserInitiated else { return }
        
        /*
            We failed to load the model on a user initiated operation try and present
            an error.
        */
        
        let alert = AlertOperation()
        alert.title = "Unable to load database"
        alert.message = "An error occurred while loading the database. \(firstError.localizedDescription). Please try again later."
        
        // No custom action for this button.
        alert.addAction(title: "Retry Later", style: .cancel)
        
        // Declare this as a local variable to avoid capturing self in the closure below.
        let handler = loadHandler
        
        /*
            For this operation, the `loadHandler` is only ever invoked if there are
            no errors, so if we get to this point we know that it was not executed.
            This means that we can offer to the user to try loading the model again,
            simply by creating a new copy of the operation and giving it the same
            loadHandler.
        */
        alert.addAction(title: "Retry Now") { (alertOperation) in
            let retryOperation = LoadModelOperation(handler: handler)
            retryOperation.isUserInitiated = true
            alertOperation.produceOperation(retryOperation)
        }
        
        produceOperation(alert)
    }
    
}


//
//  EarthquakePersistentContainerProvider.swift
//  CoreDataPlatform
//
//  Created by viwii on 2019/9/12.
//  Copyright © 2019 viwii. All rights reserved.
//

import Foundation
import CoreData

public struct PersistentContainerProvider {
    
    static var persistentContainer: NSPersistentContainer = {
        /*
            We're not going to handle catching the error here, because if we can't
            get the Caches directory, then your entire sandbox is broken and
            there's nothing we can possibly do to fix it.
        */
        let bundle = Bundle(for: Earthquake.self)
        let modelURL = bundle.url(forResource: "Earthquakes", withExtension: "momd")!
        /*
            Force unwrap this model, because this would only fail if we haven't
            included the xcdatamodel in our app resources. If we forgot that step,
            we deserve to crash. Plus, there's really no easy way to recover from
            a missing model without reconstructing it programmatically
        */
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        let container = NSPersistentContainer(name: "Earthquakes", managedObjectModel: model)
        return container
    }()
    
    public init() {
        
    }
        
    public func earthquakePersistentContainer() -> NSPersistentContainer {
        return PersistentContainerProvider.persistentContainer
    }
}

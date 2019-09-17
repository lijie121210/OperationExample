//
//  ParseEarthquakeOperation.swift
//  OperationExample
//
//  Created by viwii on 2019/9/14.
//  Copyright © 2019 viwii. All rights reserved.
//

import Foundation
import CoreData
import CoreDataPlatform
import OperationSample

open class ParseEarthquakeOperation: AnyOperation {
    
    let cacheFile: URL
    let context: NSManagedObjectContext
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load earthquake data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init(cacheFile: URL, context: NSManagedObjectContext) {
        let importContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        importContext.persistentStoreCoordinator = context.persistentStoreCoordinator
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        importContext.mergePolicy = NSOverwriteMergePolicy
        
        self.cacheFile = cacheFile
        self.context = importContext
        
        super.init()
        
        name = "Parse Earthquakes"
    }
    
    open override func execute() {
        do {
            let data = try Data(contentsOf: cacheFile)
            let earthquakes = try ParsedEarthquakes(data: data)
            
            guard !earthquakes.parsedEarthquakes.isEmpty else {
                finish()
                return
            }
            
            context.perform {
                for newe in earthquakes.parsedEarthquakes {
                    self.insert(newe, context: self.context)
                }

                let error = self.save(self.context)
                self.finish(with: error)
            }
            
        } catch let error as NSError {
            finish(with: error)
        }
    }
    
    private func insert(_ parsedEarthquake: ParsedEarthquake, context: NSManagedObjectContext) {
        let earthquake = NSEntityDescription.insertNewObject(forEntityName: Earthquake.entityName, into: context) as! Earthquake
        earthquake.identifier = parsedEarthquake.identifier
        earthquake.timestamp = parsedEarthquake.date
        earthquake.latitude = parsedEarthquake.latitude
        earthquake.longitude = parsedEarthquake.longitude
        earthquake.depth = parsedEarthquake.depth
        earthquake.webLink = parsedEarthquake.link
        earthquake.name = parsedEarthquake.name
        earthquake.magnitude = parsedEarthquake.magnitude
    }
    
    /**
        Save the context, if there are any changes.
    
        - returns: An `NSError` if there was an problem saving the `NSManagedObjectContext`,
            otherwise `nil`.
    
        - note: This method returns an `NSError?` because it will be immediately
            passed to the `finishWithError()` method, which accepts an `NSError?`.
    */
    private func save(_ context: NSManagedObjectContext) -> NSError? {
        guard context.hasChanges else {
            return nil
        }
        do {
            try context.save()
            return nil
        } catch let error as NSError {
            return error
        }
    }
}

extension ParseEarthquakeOperation {
    
    /// A struct to represent a parsed earthquake.
    struct ParsedEarthquake {
        
        var identifier: String
        var name: String
        var link: String
        var magnitude: Double
        var depth: Double = 0
        var latitude: Double = 0
        var longitude: Double = 0
        var date: Date = Date.distantFuture
        
        struct Properties: Codable {
            var place: String = ""
            var url: String = ""
            var mag: Double = 0.0
            var time: Double?
        }
        
        struct Geometry: Codable {
            let coordinates: [Double]
            
            var isValid: Bool { return coordinates.count == 3 }
            
            var longitude: Double { coordinates[0] }
            var latitude: Double { coordinates[1] }
            var depth: Double { coordinates[2] * 1000 }
        }
        
        struct Feature: Codable {
            let id: String
            let properties: Properties
            let geometry: Geometry
        }
        
        init?(feature: Feature) {
            guard !feature.id.isEmpty else {
                return nil
            }
            identifier = feature.id
            
            name = feature.properties.place
            link = feature.properties.url
            magnitude = feature.properties.mag
            
            if let offset = feature.properties.time {
                date = Date(timeIntervalSince1970: offset / 1000)
            }
            
            if feature.geometry.isValid {
                longitude = feature.geometry.longitude
                latitude = feature.geometry.latitude
                
                // `depth` is in km, but we want to store it in meters.
                depth = feature.geometry.depth
            }
        }
        
    }

    struct ParsedEarthquakes {
        
        struct Cache: Codable {
            let features: [ParsedEarthquake.Feature]
        }
        
        var parsedEarthquakes: [ParsedEarthquake]
        
        init(data: Data) throws {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
             parsedEarthquakes = cache.features.compactMap(ParsedEarthquake.init)
        }
    }
}

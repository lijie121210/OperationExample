//
//  Earthquake.swift
//  OperationExample
//
//  Created by viwii on 2019/9/10.
//  Copyright © 2019 viwii. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

/*
    An `NSManagedObject` subclass to model basic earthquake properties. This also
    contains some convenience methods to aid in formatting the information.
*/
public class Earthquake: NSManagedObject {

}

public extension Earthquake {

    @nonobjc class func fetchRequest() -> NSFetchRequest<Earthquake> {
        return NSFetchRequest<Earthquake>(entityName: "Earthquake")
    }

    @NSManaged var identifier: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var name: String
    @NSManaged var magnitude: Double
    @NSManaged var timestamp: Date
    @NSManaged var depth: Double
    @NSManaged var webLink: String

}

public extension Earthquake {
    
    // MARK: Static Properties

    static let entityName = "Earthquake"
    
    // MARK: Formatters

    static let timestampFormatter: DateFormatter = {
        let timestampFormatter = DateFormatter()
        
        timestampFormatter.dateStyle = .medium
        timestampFormatter.timeStyle = .medium

        return timestampFormatter
    }()
    
    static let magnitudeFormatter: NumberFormatter = {
        let magnitudeFormatter = NumberFormatter()
        
        magnitudeFormatter.numberStyle = .decimal
        magnitudeFormatter.maximumFractionDigits = 1
        magnitudeFormatter.minimumFractionDigits = 1

        return magnitudeFormatter
    }()
    
    static let depthFormatter: LengthFormatter = {
        let depthFormatter = LengthFormatter()

        depthFormatter.isForPersonHeightUse = false

        return depthFormatter
    }()
    
    static let distanceFormatter: LengthFormatter = {
        let distanceFormatter = LengthFormatter()

        distanceFormatter.isForPersonHeightUse = false
        distanceFormatter.numberFormatter.maximumFractionDigits = 2
        
        return distanceFormatter
    }()
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: -depth,
            horizontalAccuracy: kCLLocationAccuracyBest,
            verticalAccuracy: kCLLocationAccuracyBest,
            timestamp: timestamp
        )
    }
}


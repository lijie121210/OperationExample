//
//  EarthquakeTableViewController.swift
//  OperationExample
//
//  Created by viwii on 2019/9/15.
//  Copyright © 2019 viwii. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreDataPlatform
import OperationSample

class EarthquakeTableViewController: UITableViewController {
    
    var queue: AnyOperationQueue?
    var earthquake: Earthquake?
    var locationRequest: LocationOperation?
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var magnitudeLabel: UILabel!
    @IBOutlet weak var depthLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        guard let earthquake = earthquake else {
            locationLabel.text = nil
            magnitudeLabel.text = nil
            depthLabel.text = nil
            timeLabel.text = nil
            distanceLabel.text = nil
            return
        }
        
        let span = MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
        map.region = MKCoordinateRegion(center: earthquake.coordinate, span: span)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = earthquake.coordinate
        map.addAnnotation(annotation)
        map.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: "pin")

        
        locationLabel.text = earthquake.name
        magnitudeLabel.text = Earthquake.magnitudeFormatter.string(for: NSNumber(value: earthquake.magnitude))
        depthLabel.text = Earthquake.depthFormatter.string(fromMeters: earthquake.depth)
        timeLabel.text = Earthquake.timestampFormatter.string(from: earthquake.timestamp)
        
        /*
            We can use a `LocationOperation` to retrieve the user's current location.
            Once we have the location, we can compute how far they currently are
            from the epicenter of the earthquake.
            
            If this operation fails (ie, we are denied access to their location),
            then the text in the `UILabel` will remain as what it is defined to
            be in the storyboard.
        */
        let locationOperation = LocationOperation(accuracy: kCLLocationAccuracyKilometer) { [weak self] (location) in
            if let earthquakeLocation = self?.earthquake?.location {
                let distance = location.distance(from: earthquakeLocation)
                self?.distanceLabel.text = Earthquake.distanceFormatter.string(fromMeters: distance)
            }

            self?.locationRequest = nil
        }
        
        queue?.addOperation(locationOperation)
        locationRequest = locationOperation
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // If the LocationOperation is still going on, then cancel it.
        locationRequest?.cancel()
    }
    
    
    @IBAction func onShare(_ sender: UIBarButtonItem) {
        guard let earthquake = self.earthquake, let url = URL(string: earthquake.webLink) else {
            return
        }
        
        let location = earthquake.location
        
        /*
            We could present the share sheet manually, but by putting it inside
            an `Operation`, we can make it mutually exclusive with other operations
            that modify the view controller hierarchy.
        */
        let shareOperation = AnyBlockOperation { [weak self] (continuation: @escaping () -> Void) in
            DispatchQueue.main.async {
                let shareSheet = UIActivityViewController(activityItems: [url, location], applicationActivities: nil)
                shareSheet.popoverPresentationController?.barButtonItem = sender
                shareSheet.completionWithItemsHandler = { ( activityType: UIActivity.ActivityType?, done: Bool, items: [Any]?, error: Error?) -> Void in
                    // End the operation when the share sheet completes.
                    continuation()
                }
                self?.present(shareSheet, animated: true, completion: nil)
            }
        }
        
        /*
            Indicate that this operation modifies the View Controller hierarchy
            and is thus mutually exclusive.
        */
        shareOperation.addCondition(MutuallyExclusive<UIViewController>())
        
        queue?.addOperation(shareOperation)
    }

    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section, indexPath.row) == (1, 0) {
            // The user has tapped the "More Information" button.
            if let link = earthquake?.webLink, let url = URL(string: link) {
                // If we have a link, present the "More Information" dialog.
                let moreInformation = MoreInformationOperation(url: url)

                queue?.addOperation(moreInformation)
            } else {
                // No link; present an alert.
                let alert = AlertOperation(presentationContext: self)
                alert.title = "No Information"
                alert.message = "No other information is available for this earthquake"
                queue?.addOperation(alert)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

extension EarthquakeTableViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let earthquake = earthquake else { return nil }
                
        let pin = mapView.dequeueReusableAnnotationView(withIdentifier: "pin", for: annotation) as! MKPinAnnotationView
        pin.isEnabled = false

        switch earthquake.magnitude {
        case 0..<3: pin.pinTintColor = UIColor.gray
        case 3..<4: pin.pinTintColor = UIColor.blue
        case 4..<5: pin.pinTintColor = UIColor.orange
        default:    pin.pinTintColor = UIColor.red
        }

        return pin
    }
}

//
//  EarthquakesTableViewController.swift
//  OperationExample
//
//  Created by viwii on 2019/9/15.
//  Copyright © 2019 viwii. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import CoreDataPlatform
import OperationSample

class EarthquakesTableViewController: UITableViewController {
    
    var fetchedResultsController: NSFetchedResultsController<Earthquake>?
    
    var operationQueue = AnyOperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let loadModelOperation = LoadModelOperation { [weak self] (context) in
            DispatchQueue.main.async {
                let request: NSFetchRequest<Earthquake> = Earthquake.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)];
                request.fetchLimit = 100
                let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
                self?.fetchedResultsController = controller
                self?.updateUI()
            }
        }
        operationQueue.addOperation(loadModelOperation)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let navi = segue.destination as? UINavigationController,
            let earthquakeTVC = navi.viewControllers.first as? EarthquakeTableViewController else {
                return
        }
        
        earthquakeTVC.queue = operationQueue
        
        if let indexPath = tableView.indexPathForSelectedRow {
            earthquakeTVC.earthquake = fetchedResultsController?.object(at: indexPath)
        }
    }
    
    @IBAction private func onRefreshing(_ sender: UIRefreshControl) {
        getEarthquakes()
    }
    
    private func getEarthquakes(userInitiated: Bool = true) {
        if let context = fetchedResultsController?.managedObjectContext {
            let getEarthquakesOperation = GetEarthquakesOperation(context: context) { [weak self] in
                DispatchQueue.main.async {
                    self?.refreshControl?.endRefreshing()
                    self?.updateUI()
                }
            }

            getEarthquakesOperation.isUserInitiated = userInitiated
            operationQueue.addOperation(getEarthquakesOperation)
            
        } else {
            /*
                We don't have a context to operate on, so wait a bit and just make
                the refresh control end.
            */
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func updateUI() {
        do {
            try fetchedResultsController?.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }

        tableView.reloadData()
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
            Instead of performing the segue directly, we can wrap it in a `BlockOperation`.
            This allows us to attach conditions to the operation. For example, you
            could make it so that you could only perform the segue if the network
            is reachable and you have access to the user's Photos library.
            
            If you decide to use this pattern in your apps, choose conditions that
            are sensible and do not place onerous requirements on the user.
            
            It's also worth noting that the Observer attached to the `BlockOperation`
            will cause the tableview row to be deselected automatically if the
            `Operation` fails.
            
            You may choose to add your own observer to introspect the errors reported
            as the operation finishes. Doing so would allow you to present a message
            to the user about why you were unable to perform the requested action.
        */
        
        let operation = AnyBlockOperation { [weak self] in
            self?.performSegue(withIdentifier: "showEarthquake", sender: nil)
        }
        operation.addCondition(MutuallyExclusive<UIViewController>())

        let blockObserver = BlockObserver(startHandler: nil, produceHandler: nil) { (_, errors) in
            /*
                If the operation errored (ex: a condition failed) then the segue
                isn't going to happen. We shouldn't leave the row selected.
            */
            if !errors.isEmpty {
                DispatchQueue.main.async {
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            }
        }
        operation.addObserver(blockObserver)
        
        operationQueue.addOperation(operation)
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return fetchedResultsController?.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = fetchedResultsController?.sections?[section]
        return section?.numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EarthquakeTableViewCell", for: indexPath) as! EarthquakeTableViewCell

        guard let earthquake = fetchedResultsController?.object(at: indexPath) else {
            return cell
        }
        
        cell.timestampLabel.text = Earthquake.timestampFormatter.string(from: earthquake.timestamp)
        cell.magnitudeLabel.text = Earthquake.magnitudeFormatter.string(from: NSNumber(value: earthquake.magnitude))
        cell.locationLabel.text = earthquake.name
        
        let imageName: String
        
        switch earthquake.magnitude {
            case 0..<2: imageName = ""
            case 2..<3: imageName = "2.0"
            case 3..<4: imageName = "3.0"
            case 4..<5: imageName = "4.0"
            default:    imageName = "5.0"
        }

        cell.magnitudeImage.image = UIImage(named: imageName)

        return cell
    }
    
}

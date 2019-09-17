//
//  DownloadEarthquakesOperation.swift
//  OperationExample
//
//  Created by viwii on 2019/9/14.
//  Copyright © 2019 viwii. All rights reserved.
//

import Foundation
import OperationSample

open class DownloadEarthquakesOperation: GroupOperation {
    
    let cacheFile: URL
    
    /// - parameter cacheFile: The file `NSURL` to which the earthquake feed will be downloaded.
    public init(cacheFile: URL) {
        self.cacheFile = cacheFile
        
        super.init([])
        
        name = "Download Earthquakes"
        
        /*
            Since this server is out of our control and does not offer a secure
            communication channel, we'll use the http version of the URL and have
            added "earthquake.usgs.gov" to the "NSExceptionDomains" value in the
            app's Info.plist file. When you communicate with your own servers,
            or when the services you use offer secure communication options, you
            should always prefer to use https.
        */
        let url = URL(string: "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.geojson")!
        let task = URLSession.shared.downloadTask(with: url) { [weak self] (url, response, error) in
            self?.downloadFinished(url: url, response: response as? HTTPURLResponse, error: error as NSError?)
        }
        
        let taskOperation = URLSessionTaskOperation(task: task)
        
        let reachabilityCondition = ReachabilityCondition(url)
        taskOperation.addCondition(reachabilityCondition)
        
        addOperation(taskOperation)
    }
    
    func downloadFinished(url: URL?, response: HTTPURLResponse?, error: NSError?) {
        if let error = error {
            aggregateError(error)
            return
        }
        guard let localURL = url else {
            // Do nothing, and the operation will automatically finish.
            return
        }
        do {
            /*
                If we already have a file at this location, just delete it.
                Also, swallow the error, because we don't really care about it.
            */
            try FileManager.default.removeItem(at: cacheFile)
        } catch {
            
        }
        do {
            try FileManager.default.moveItem(at: localURL, to: cacheFile)
        } catch let fileError as NSError {
            aggregateError(fileError)
        }
    }
    
}

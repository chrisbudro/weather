//
//  WeatherViewController.swift
//  weatherList
//
//  Created by Chris Budro on 3/29/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit
import CoreLocation


class WeatherViewController: UICollectionViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, CLLocationManagerDelegate, LocationsTableViewControllerDelegate {
    
    
    private struct Constants {
        static let desiredAccuracy : CLLocationAccuracy = 1000
        static let minimumDistanceMoved : Double = 3000
        static let localID = "local"
        static let minimumTimeSinceLastUpdate = 7200
        static let cellReuseIdentifier = "Cell"
        static let savedLocations = "savedLocations"
    }

    
    // Properties
    let weatherRequester = WeatherRequester()
    
    // Get weather dictionary from User Defaults
    var weatherDict : [String : WeatherData] = {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey(Constants.savedLocations) as? NSData {
            let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String: WeatherData]

            return dict
        }
        return [String: WeatherData]()
    }()
    
    // Get Weather Tags array from User Defaults
    var weatherPlaceIDs : [String] = {
        if let placeIDs = NSUserDefaults.standardUserDefaults().objectForKey("weatherPlaceIDs") as? [String] {
            return placeIDs
        }
        return [String]()
    }()
    
    var backgroundImageView = UIImageView()
    var nextImageView = UIImageView()
    var toImage = UIImage()
    var scrollOffset : CGFloat?
    let locationManager = CLLocationManager()
    var currentIndex : Int?
    var currentCell : WeatherViewCell?
    let transitionManager = TransitionManager()
    var addLocationsButton : UIBarButtonItem!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if weatherPlaceIDs.count > 0 {
            currentIndex = 0
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "viewBecameActive", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        //check location athorization status
        locationManager.delegate = self
        
        if CLLocationManager.locationServicesEnabled() {
            if self.locationManager.respondsToSelector("requestWhenInUseAuthorization") {
                if (CLLocationManager.authorizationStatus() == .NotDetermined) {
                    locationManager.requestWhenInUseAuthorization()
                }
            } else {
                getLocation()
            }
        }
        
        prepareBackgroundImageViews()
        setupToolbar()
    }
    

    //MARK: Location Delegate
    
    func getLocation() {
        println("getting location")
        startActivityIndicator(0)
        locationManager.desiredAccuracy = Constants.desiredAccuracy
        locationManager.startUpdatingLocation()
    }
    
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
            getLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.locationManager.stopUpdatingLocation()
        let newLocation = locations[0] as! CLLocation
        var distanceFromLast : Double?
        if let lastLocation = NSUserDefaults.standardUserDefaults().objectForKey("lastKnownLocation") as? NSData {
            
            let lastKnownLocation = NSKeyedUnarchiver.unarchiveObjectWithData(lastLocation) as! CLLocation
            println("last known: \(lastKnownLocation)")
            distanceFromLast = newLocation.distanceFromLocation(lastKnownLocation)  //Fix issue of showing as 0
            
            println("distance traveled: \(distanceFromLast)")
        }

        let locationData = NSKeyedArchiver.archivedDataWithRootObject(newLocation)
        NSUserDefaults.standardUserDefaults().setObject(locationData, forKey: "lastKnownLocation")
        
        println("distance from last: \(distanceFromLast)")
        
        if (distanceFromLast == nil || distanceFromLast > Constants.minimumDistanceMoved) {
            let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(newLocation, completionHandler: {(placemarks, error) -> Void in
                if error == nil {
                    let placemark = placemarks[0] as! CLPlacemark
                    let placeDescription = "\(placemark.locality), \(placemark.administrativeArea)"
                    let placeDetails = (description: placeDescription, placeID: Constants.localID)
                    let coordinates = "\(placemark.location.coordinate.latitude),\(placemark.location.coordinate.longitude)"
                    let displayName = placemark.locality as String
                    self.requestLocalWeatherData(placeDetails, coordinates: coordinates)
  
                } else {
                    self.stopActivityIndicator()
                    println(error)
                }
            })
            
        } else {
            stopActivityIndicator()
        }
    }
    
    //MARK: Weather Updates
    

    func updateWeatherData(currentIndex: Int?, forceUpdate: Bool) {
        if let index = currentIndex {
            startActivityIndicator(index)
            
            let placeID = weatherPlaceIDs[index]
            let weatherData = weatherDict[placeID]
            let placeDetails = (description: weatherData!.locationName!, placeID: placeID)
            let elapsedTime = getElapsedTime(weatherData!.unixTime!)

            if (elapsedTime > Constants.minimumTimeSinceLastUpdate || (elapsedTime > 600 && forceUpdate == true) ) {
                var local = (index == 0) ? true : false
                requestWeatherData(placeDetails, isLocal: local)  // need to update input of request weather Data
                println("updated weather")
            } else {
                stopActivityIndicator()
                println("not updated")
            }
        } else {
            getLocation()
        }
    }
    
    func requestLocalWeatherData(placeDetails: (description: String, placeID: String), coordinates: String) {
        self.weatherRequester.getWeatherData(placeDetails, coordinates: coordinates, isLocal: true) { (weatherData, placeID, error) -> Void in
            
            if (error == nil) {
                // add or update location in the weather Dictionary with local tag key: 0
                self.weatherDict[Constants.localID] = weatherData
                
                // if the local tag is already in the weatherTags array, make sure it is first
                if let index = find(self.weatherPlaceIDs, Constants.localID) {
                    if index != 0 {
                        self.weatherPlaceIDs.removeAtIndex(index)
                        self.weatherPlaceIDs.insert(Constants.localID, atIndex: 0)
                    }
                } else {
                    self.weatherPlaceIDs.insert(Constants.localID, atIndex: 0)
                }
                self.saveData(self.weatherDict, weatherPlaceIDs: self.weatherPlaceIDs)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.stopActivityIndicator()
                    self.collectionView!.reloadData()
                })
            } else {
                println("error: \(error)")
            }
        }
    }
    

    func requestWeatherData(placeDetails: (description: String, placeID: String), isLocal: Bool) {
        var coordinates : String?
        println("placeDetails: \(placeDetails)")
        if (weatherDict[placeDetails.placeID] == nil) {
            // pull google place id search request and assign coordinates
            requestPlaceCoordinates(placeDetails.placeID, completion: { (coordinates) -> Void in
                println("coordinates: \(coordinates)")
                self.weatherRequester.getWeatherData(placeDetails, coordinates: coordinates, isLocal: false, completion: { (weatherData, placeID, error) -> Void in
                    
                    
                    if (error == nil) {

                        self.weatherDict[placeID] = weatherData
                        
                        // if the tag is already in the list then leave it
                        if let index = find(self.weatherPlaceIDs, placeID) {
                            println("already in tags array")
                        } else {
                            self.weatherPlaceIDs.append(placeID)
                        }
                        
                        
                        println("request finished")
                        
                        // store downloaded data
                        self.saveData(self.weatherDict, weatherPlaceIDs: self.weatherPlaceIDs)
                        self.checkForStrayPlaceIDs()

                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.stopActivityIndicator()
                            self.collectionView!.reloadData()
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.stopActivityIndicator()
                        })
                        // Setup alert view to alert of weather request errors
                        println("error")
                        self.checkForStrayPlaceIDs()
                    }
                })
             })
        } else {
            let location = weatherDict[placeDetails.placeID] as WeatherData!
            coordinates = location.coordinates!
            
            self.weatherRequester.getWeatherData(placeDetails, coordinates: coordinates!, isLocal: false, completion: { (weatherData, placeID, error) -> Void in
                
                
                if (error == nil) {
                    
                    self.weatherDict[placeID] = weatherData
                    
                    // if the tag is already in the list then leave it
                    if let index = find(self.weatherPlaceIDs, placeID) {
                        println("already in tags array")
                    } else {
                        self.weatherPlaceIDs.append(placeID)
                    }
                    
                    
                    println("request finished")
                    
                    // store downloaded data
                    self.saveData(self.weatherDict, weatherPlaceIDs: self.weatherPlaceIDs)
                    self.checkForStrayPlaceIDs()
                    
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.stopActivityIndicator()
                        self.collectionView!.reloadData()
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.stopActivityIndicator()
                    })
                    // Setup alert view to alert of weather request errors
                    println("error")
                    self.checkForStrayPlaceIDs()
                }
            })
            
    }
    }

    func requestPlaceCoordinates(placeID: String, completion: (coordinates: String) -> Void) {
        let apiKey = "AIzaSyAyeGkrgfIa2Ov7Kb8Hzr2pHOYNMPytlWc"
        let placeRequestURL = NSURL(string: "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(placeID)&key=\(apiKey)")
        
        
        
        let downloadTask : NSURLSessionDownloadTask = NSURLSession.sharedSession().downloadTaskWithURL(placeRequestURL!, completionHandler: { (placeData : NSURL!, response: NSURLResponse!, error: NSError!) -> Void in
            if (error == nil) {
                let data = NSData(contentsOfURL: placeData, options: nil, error: nil)
                let placeJSON = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary
                println("JSON: \(placeJSON)")
                
                let placeResult = placeJSON["result"] as! NSDictionary
                let placeGeometry = placeResult["geometry"] as! NSDictionary
                let placeCoordinate = placeGeometry["location"] as! NSDictionary
                let latitude = placeCoordinate["lat"] as? Double
                let longitude = placeCoordinate["lng"] as? Double
                let coordinates = "\(latitude!),\(longitude!)"
                
                completion(coordinates: coordinates)
            } else {
                println("error: \(error)")
            }
        })
        downloadTask.resume()
        
        
    }
    
    
    //MARK: Helper Methods
    
    
    func prepareBackgroundImageViews() {
        // prepare background imageViews for transitions
        collectionView!.backgroundColor = UIColor.blackColor()
        nextImageView.alpha = 0.0
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = UIColor.clearColor()
        backgroundView.addSubview(nextImageView)
        backgroundView.addSubview(backgroundImageView)
        backgroundView.alpha = 0.5
        
        backgroundImageView.backgroundColor = UIColor.clearColor()
        nextImageView.backgroundColor = UIColor.clearColor()
        backgroundImageView.frame = backgroundView.frame
        nextImageView.frame = backgroundView.frame
        backgroundImageView.contentMode = .Center
        nextImageView.contentMode = .Center
        
        self.collectionView?.backgroundView = backgroundView
        
        // set first background image
        backgroundImageView.image = getImage(0)
    }
    
    
    func setupToolbar() {
        let toolbar = UIToolbar(frame: CGRectMake(0, 0, self.view.frame.size.width, 65))
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: UIBarPosition.Any, barMetrics: UIBarMetrics.Default)
        toolbar.translucent = true
        toolbar.backgroundColor = UIColor(white: 0.3, alpha: 0.3)
        
        self.view.addSubview(toolbar)
        
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshWasPressed")
        refreshButton.tintColor = UIColor(white: 1.0, alpha: 0.8)
        refreshButton.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0)
        
        addLocationsButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addWasPressed:")
        addLocationsButton.tintColor = UIColor(white: 1.0, alpha: 0.8)
        addLocationsButton.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0)
        
        let buttonSpacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        
        toolbar.setItems([refreshButton, buttonSpacer, addLocationsButton], animated: false)
    }
    
    
    func startActivityIndicator(index: Int) {
        currentCell = collectionView!.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) as? WeatherViewCell
        currentCell?.activityIndicator.startAnimating()
    }
    
    
    func stopActivityIndicator() {
        currentCell?.activityIndicator.stopAnimating()
    }
    
    
    func getTimeSinceLastUpdate(unixTime: Int?) -> String {
        if let lastUpdate = unixTime {
            let elapsedTimeInSeconds = getElapsedTime(lastUpdate)
            let elapsedTimeInMinutes = elapsedTimeInSeconds / 60
            return createLastUpdateLabelMessage(elapsedTimeInMinutes)
        }
        return ""
    }
    
    
    func getElapsedTime(unixTime: Int) -> Int {
        let lastUpdateTimestamp = NSTimeInterval(unixTime)
        let elapsedTime = NSDate().timeIntervalSince1970 - lastUpdateTimestamp
        return Int(elapsedTime)
    }
    
    
    func createLastUpdateLabelMessage(elapsedTimeInMinutes: Int) -> String {
        switch (elapsedTimeInMinutes) {
            case 0...5:
                return "updated a moment ago"
            case 6...55:
                return "updated \(elapsedTimeInMinutes) minutes ago"
            case 56...70:
                return "updated an hour ago"
            case 71...110:
                return "updated over an hour ago"
            case 111...125:
                return "updated two hours ago"
            default:
                return "updated more than two hours ago"
        }
    }
    
    
    func checkForStrayPlaceIDs() {
        for (index, placeID) in enumerate(self.weatherPlaceIDs) {
            if (self.weatherDict[placeID] == nil) {
                self.weatherPlaceIDs.removeAtIndex(index)
            }
        }
    }
    
    
    func viewBecameActive() {
        getLocation()
        updateWeatherData(currentIndex, forceUpdate: false)
    }
    
    
    func saveData(weatherDict: [String : WeatherData], weatherPlaceIDs: [String]) {
        let data = NSKeyedArchiver.archivedDataWithRootObject(weatherDict)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: Constants.savedLocations)
        NSUserDefaults.standardUserDefaults().setObject(weatherPlaceIDs, forKey: "weatherPlaceIDs")
    }
    
    
    func savePlaceIDs(placeIDs: [String]) {
        NSUserDefaults.standardUserDefaults().setObject(weatherPlaceIDs, forKey: "weatherPlaceIDs")
    }
    
    
    func getImage(index: Int) -> UIImage {
        if (index < weatherPlaceIDs.count) {
            let placeID = weatherPlaceIDs[index]
            let weatherData = weatherDict[placeID] as WeatherData!
            
            return weatherImageFromString(weatherData.imageString!)
        }
        return UIImage(named: "default")!
    }
    
    
    func weatherImageFromString(stringIcon: String) -> UIImage {
        var imageName: String
        
        switch stringIcon {
        case "clear-day":
            imageName = "clear"
        case "clear-night":
            imageName = "clear"
        case "rain":
            imageName = "rain"
        case "snow":
            imageName = "snow"
        case "sleet":
            imageName = "snow"
        case "wind":
            imageName = "cloudy"
        case "fog":
            imageName = "cloudy"
        case "cloudy":
            imageName = "cloudy"
        case "partly-cloudy-day":
            imageName = "partly-cloudy"
        case "partly-cloudy-night":
            imageName = "partly-cloudy"
        default:
            imageName = "default"
            
        }

        var iconImage = UIImage(named: imageName)
        return iconImage!
        
    }
    

    //MARK: Scroll View Delegate

    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // Grab Scroll View Content Offset at start to calculate distance dragged
        scrollOffset = scrollView.contentOffset.x
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollOffset == nil {
            scrollOffset = 0.0
        }
        // Calculate transition percentage.  current offset - starting offset / view width
        let transitionPercentage = abs(scrollView.contentOffset.x - scrollOffset!) / self.view.frame.width
        
        // cross dissolve background image transition
        self.backgroundImageView.alpha = 1.0 - transitionPercentage
        self.nextImageView.alpha = 0.0 + transitionPercentage
        
        
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        // Calculate distance dragged by comparing start and end content offsets
        var distanceSwiped = scrollView.contentOffset.x - scrollOffset!
        
        if (abs(distanceSwiped) > (self.view.bounds.width / 2)) {
            
            // Find horizontal center by halving frame width and offsetting by the scroll view.  Then grab the indexPath at that point
            let centerPoint = CGPointMake(self.collectionView!.frame.size.width / 2 + scrollView.contentOffset.x, self.collectionView!.frame.size.height / 2)
            let currentIndexPath = self.collectionView!.indexPathForItemAtPoint(centerPoint)
            
            //update current page number
            currentIndex = currentIndexPath!.row
            backgroundImageView.image = getImage(currentIndex!)
            
            
            
            // reset cross dissolve image views
            backgroundImageView.alpha = 1.0
            nextImageView.alpha = 0.0
        }
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.weatherPlaceIDs.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.cellReuseIdentifier, forIndexPath: indexPath) as! WeatherViewCell
        
//        updateWeatherData(indexPath.row, forceUpdate: false)
        let placeID = weatherPlaceIDs[indexPath.row]
        
        if let weatherData = weatherDict[placeID] {
            cell.currentTemperatureLabel!.text = "\(weatherData.temperature!)"
            cell.locationNameLabel.text = weatherData.locationName
            cell.currentSummaryLabel.text = weatherData.summary
            cell.currentPrecipLabel.text = "Precip: \(weatherData.precip!)%"
            cell.currentWindLabel.text = "Wind: \(weatherData.wind!) MPH"
            cell.currentHighLowLabel.text = "\(weatherData.currentDayHighTemp!)° / \(weatherData.currentDayLowTemp!)°"
            cell.lastUpdateTimeLabel.text = getTimeSinceLastUpdate(weatherData.unixTime)
            
            toImage = getImage(indexPath.row)
            nextImageView.image = toImage
        
        } else {
            println("did not assign")
        }

        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.bounds.size
        
    }


   //MARK: Locations Table View Delegate Methods 
    
    
    func didAddLocation(placeDetails: (description: String, placeID: String)) {
        
        self.weatherPlaceIDs.append(placeDetails.placeID)
        requestWeatherData(placeDetails, isLocal: false)
        collectionView?.reloadData()
        println("delegate called")
        
    }
    
    func didDeleteLocation(placeID: String) {

        if let placeIdIndex = find(weatherPlaceIDs, placeID) {
            weatherPlaceIDs.removeAtIndex(placeIdIndex)
        }
        
        if (weatherDict[placeID] != nil) {
            weatherDict.removeValueForKey(placeID)
        }
        saveData(weatherDict, weatherPlaceIDs: weatherPlaceIDs)
        collectionView?.reloadData()
    }
    
    func didArrangeList(weatherPlaceIDs: [String]) {
        self.weatherPlaceIDs = weatherPlaceIDs
        collectionView?.reloadData()
    }
    
    func didSelectLocationFromList(placeID: String) {
        if let index = find(weatherPlaceIDs, placeID) {
            self.collectionView!.selectItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), animated: false, scrollPosition: .CenteredHorizontally)
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showLocationsList" ) {
            let vc = segue.destinationViewController as! LocationsTableViewController
            vc.weatherPlaceIDs = self.weatherPlaceIDs
            vc.weatherDict = self.weatherDict
            vc.delegate = self as LocationsTableViewControllerDelegate
            println("vc.delegate: \(vc.delegate)")
            
            // Transition Animation
            
            let sourceController = segue.sourceViewController as! WeatherViewController
            
            vc.transitioningDelegate = self.transitionManager
            self.transitionManager.locationsListController = vc
            
            
        }
    }

    //MARK: Buttons
    
    
    func refreshWasPressed() {
        updateWeatherData(currentIndex, forceUpdate: true)
    }
    
    func addWasPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier("showLocationsList", sender: self)
    }
    
    @IBAction func unwindFromList(sender: UIStoryboardSegue) {
        
    }
}





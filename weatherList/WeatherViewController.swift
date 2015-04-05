//
//  WeatherViewController.swift
//  weatherList
//
//  Created by Chris Budro on 3/29/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit
import CoreLocation

let reuseIdentifier = "Cell"
let savedLocations = "savedLocations"

class WeatherViewController: UICollectionViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, CLLocationManagerDelegate, LocationsTableViewControllerDelegate {
    
    
    
    
    //Constants
    let desiredAccuracy : CLLocationAccuracy = 1000
    let minimumDistanceMoved : Double = 3000
    let localTag = 0
    let minimumTimeSinceLastUpdate = -7200.0

    
    // Properties
    let weatherRequester = WeatherRequester()
    
    // Get weather dictionary from User Defaults
    var weatherDict : [Int : WeatherData] = {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey(savedLocations) as? NSData {
            let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [Int: WeatherData]

            return dict
        }
        return [Int: WeatherData]()
    }()
    
    // Get Weather Tags array from User Defaults
    var weatherTags : [Int] = {
        if let tags = NSUserDefaults.standardUserDefaults().objectForKey("weatherTags") as? [Int] {
            return tags
        }
        return [Int]()
    }()
    
    var backgroundImageView = UIImageView()
    var nextImageView = UIImageView()
    var toImage = UIImage()
    var scrollOffset : CGFloat?
    let pageControl = UIPageControl() //doesn't reload
    let locationManager = CLLocationManager()
    var currentIndex : Int?
    let transitionManager = TransitionManager()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.transitionManager.sourceViewController = self
        
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

        
        // Set Nav Bar Title Properties
        let navBarFont = UIFont(name: "HelveticaNeue-Light", size: 14.0)
        let fontDict = [NSFontAttributeName: navBarFont!, NSForegroundColorAttributeName: UIColor.whiteColor() ]
        self.navigationController?.navigationBar.titleTextAttributes = fontDict

        // prepare background imageViews for transitions
        collectionView!.backgroundColor = UIColor.blackColor()
        nextImageView.alpha = 0.0
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = UIColor.clearColor()
        backgroundView.addSubview(nextImageView)
        backgroundView.addSubview(backgroundImageView)
        backgroundView.alpha = 0.5
        
        self.collectionView?.backgroundView = backgroundView
        backgroundImageView.backgroundColor = UIColor.clearColor()
        nextImageView.backgroundColor = UIColor.clearColor()
        backgroundImageView.frame = backgroundView.frame
        nextImageView.frame = backgroundView.frame
        backgroundImageView.contentMode = .Center
        nextImageView.contentMode = .Center
        
        // set first background image
        backgroundImageView.image = getImage(0)
    
        
        // initialize page control
        pageControl.frame = CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width-200, 100)
        pageControl.frame.origin.x = self.view.center.x - (pageControl.frame.width / 2)
          // Placeholder until locations database is setup
        pageControl.currentPage = 0
        self.view.addSubview(pageControl)
        pageControl.userInteractionEnabled = false
        
        collectionView?.alwaysBounceVertical = true
        
        
        // Add Location Button
//        let topView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 40))
//        let locationsButton = UIButton(frame: CGRectMake(self.view.frame.width - 40, 30, 40, 40))
//        let buttonImageView = UIImageView(image: UIImage(named: "menu"))
//        buttonImageView.frame = CGRectMake(0, 0, 30, 30)
//        locationsButton.addSubview(buttonImageView)
//        locationsButton.addTarget(self, action: "addWasPressed:", forControlEvents: .TouchUpInside)
//        
//        topView.backgroundColor = UIColor.clearColor()
//        
//        topView.addSubview(locationsButton)
//        self.view.addSubview(topView)
        
//        let bottomView = UIView(frame: CGRectMake(0, self.view.frame.size.height - 60, self.view.frame.size.width, 60))
//        bottomView.backgroundColor = UIColor.clearColor()
        

        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
//        // Set Nav Bar Transparency
//        self.navigationController!.navigationBar.setBackgroundImage(UIImage(named: "lightNavBarBackground"), forBarMetrics: .Default)
//        self.navigationController!.navigationBar.shadowImage = UIImage()
//        
    }
    
    
    //MARK: Location Delegate
    
    func getLocation() {
        println("getting location")
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.startUpdatingLocation()
    }
    
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
            getLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("CLLocation finished")
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
        
        if (distanceFromLast == nil || distanceFromLast > minimumDistanceMoved) {
            let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(newLocation, completionHandler: {(placemarks, error) -> Void in
                if error == nil {
                    let placemark = placemarks[0] as! CLPlacemark
                    self.requestWeatherData(placemark, isLocal: true)
  
                } else {
                    println(error)
                }
            })
            
        }
    }
    
    //MARK: Weather Updates
    
    func updateWeatherData(currentIndex: Int?, forceUpdate: Bool) {
        if let index = currentIndex {
            let tag = weatherTags[index]
            let weatherData = weatherDict[tag]
            let lastUpdateTimestamp = NSTimeInterval(weatherData!.unixTime!)
            let lapsedTime = NSDate().timeIntervalSince1970 - lastUpdateTimestamp
            
            if (lapsedTime < -600) {
                if (lapsedTime < minimumTimeSinceLastUpdate || forceUpdate == true ) {
                    var local = (index == 0) ? true : false
                    requestWeatherData(weatherData!.placemark!, isLocal: local)
                    println("updated weather")
                } else {
                    println("not updated")
                }
            } else {
                println("Refreshing Too Soon")
            }
        }
    }
    
    func requestWeatherData(placemark: CLPlacemark, isLocal: Bool) {

        self.weatherRequester.getWeatherData(placemark, isLocal: true, completion: { (weatherData, tag, error) -> Void in
            
            
            if (error == nil) {
                if (isLocal) {
                    // add or update location in the weather Dictionary with local tag key: 0
                    self.weatherDict[self.localTag] = weatherData
                    
                    // if the local tag is already in the weatherTags array, make sure it is first
                    if let index = find(self.weatherTags, self.localTag) {
                        if index != 0 {
                            self.weatherTags.removeAtIndex(index)
                            self.weatherTags.insert(self.localTag, atIndex: 0)
                        }
                    } else {
                        self.weatherTags.insert(self.localTag, atIndex: 0)
                    }
                    
                } else {
                    self.weatherDict[placemark.location.hash] = weatherData
                    
                    // if the tag is already in the list then leave it
                    if let index = find(self.weatherTags, placemark.location.hash) {
                        println("already in tags array")
                    } else {
                        self.weatherTags.append(placemark.location.hash)
                    }
                }
                
                println("request finished: \(placemark.locality)")
                
                // store downloaded data
                self.saveData(self.weatherDict, weatherTags: self.weatherTags)
                self.checkForStrayTags()

                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.collectionView!.reloadData()
                })
            } else {
                
                // Setup alert view to alert of weather request errors
                println("error")
                self.checkForStrayTags()
            }
        })
    }

    
    
    //MARK: Helper Methods
    
    func checkForStrayTags() {
        for (index, tag) in enumerate(self.weatherTags) {
            if (self.weatherDict[tag] == nil) {
                self.weatherTags.removeAtIndex(index)
            }
        }
    }
    
    func viewBecameActive() {
        getLocation()
        
        updateWeatherData(currentIndex, forceUpdate: false)
    }
    
    
    func saveData(weatherDict: [Int : WeatherData], weatherTags: [Int]) {
        let data = NSKeyedArchiver.archivedDataWithRootObject(weatherDict)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: savedLocations)
        NSUserDefaults.standardUserDefaults().setObject(weatherTags, forKey: "weatherTags")
    }
    
    func saveTags(weatherTags: [Int]) {
        NSUserDefaults.standardUserDefaults().setObject(weatherTags, forKey: "weatherTags")
    }
    
    
    func getImage(index: Int) -> UIImage {
        if (index < weatherTags.count) {
            let tag = weatherTags[index]
            let weatherData = weatherDict[tag] as WeatherData!
            
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
            pageControl.currentPage = currentIndexPath!.row
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
        println("cell count: \(weatherTags.count)")
        return self.weatherTags.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! WeatherViewCell
        
//        updateWeatherData(indexPath.row, forceUpdate: false)
        let tag = weatherTags[indexPath.row]
        
        if let weatherData = weatherDict[tag] {
            cell.currentTemperatureLabel!.text = "\(weatherData.temperature!)"
            cell.locationNameLabel.text = weatherData.locationName
            cell.currentSummaryLabel.text = weatherData.summary
            toImage = getImage(indexPath.row)
            nextImageView.image = toImage
        
        } else {
            println("did not assign")
        }
        
        
        
//        if (currentWeather != nil) {
//            let currentLocation = currentWeather![indexPath.row]
//            
//            cell.currentTemperatureLabel.text = currentLocation["temperature"] as? String
//            cell.locationNameLabel.text = currentLocation["locationName"] as? String
//            cell.currentSummaryLabel.text = currentLocation["summary"] as? String
//            toImage = imageArray[indexPath.row]!
//            nextImageView.image = toImage
//
//        }
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.bounds.size
        
    }
    
//    func freezeImage() -> UIImage {
//        UIGraphicsBeginImageContext(self.view.bounds.size)
//        self.view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: true)
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        let blurredImage = image.applyBlurWithRadius(20, tintColor: UIColor(white: 1.0, alpha: 0.2), saturationDeltaFactor: 1.3, maskImage: nil)
//        
//        
//        return blurredImage
//    }
    


   //MARK: Locations Table View Delegate Methods 
    
    
    func didAddLocation(placemark: CLPlacemark) {
        
        self.weatherTags.append(placemark.location.hash)
        requestWeatherData(placemark, isLocal: false)
        collectionView?.reloadData()
        println("delegate called")
        
    }
    
    func didDeleteLocation(tag: Int) {

        if let tagIndex = find(weatherTags, tag) {
            weatherTags.removeAtIndex(tagIndex)
        }
        
        if (weatherDict[tag] != nil) {
            weatherDict.removeValueForKey(tag)
        }
        saveData(weatherDict, weatherTags: weatherTags)
        collectionView?.reloadData()
    }
    
    func didArrangeList(weatherTags: [Int]) {
        self.weatherTags = weatherTags
        collectionView?.reloadData()
    }
    
    func didSelectLocationFromList(tag: Int) {
        let index = find(weatherTags, tag)
        self.collectionView!.selectItemAtIndexPath(NSIndexPath(forItem: index!, inSection: 0), animated: false, scrollPosition: .CenteredHorizontally)
    }

    //MARK: Buttons
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if (segue.identifier == "showLocationsList" ) {
            let vc = segue.destinationViewController as! LocationsTableViewController
            vc.weatherTags = self.weatherTags
            vc.weatherDict = self.weatherDict
            vc.delegate = self
            
            // Transition Animation
            
            let sourceController = segue.sourceViewController as! WeatherViewController
            
            vc.transitioningDelegate = self.transitionManager
            self.transitionManager.locationsListController = vc
            
            
//        }
    }
    
    
    @IBAction func refreshWasPressed(sender: UIBarButtonItem) {
        
        getLocation()
        updateWeatherData(currentIndex, forceUpdate: true)
        self.collectionView!.reloadData()
        
    }
    
    @IBAction func addWasPressed(sender: UIButton) {
        performSegueWithIdentifier("showLocationsList", sender: self)
    }
    
    @IBAction func unwindFromList(sender: UIStoryboardSegue) {
//        self.dismissViewControllerAnimated(true, completion:nil)
        
    }
}





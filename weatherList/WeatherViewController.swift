//
//  WeatherViewController.swift
//  weatherList
//
//  Created by Chris Budro on 3/29/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit


class WeatherViewController: UICollectionViewController {
    
    
    private struct Constants {

        static let minimumTimeSinceLastUpdate = 7200
        static let cellReuseIdentifier = "Cell"
        static let savedLocations = "savedLocations"
    }

    
    let weatherAPI = WeatherAPI.sharedInstance
    var weatherLocations : [WeatherData] {
        return weatherAPI.getLocations()
    }
    var backgroundImageView = UIImageView()
    var nextImageView = UIImageView()
    var toImage = UIImage()
    var scrollOffset : CGFloat?
    var currentIndex : Int?
    let transitionManager = TransitionManager()
    var addLocationsButton : UIBarButtonItem!


    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshList", name: "locationsListUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "viewBecameActive", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        if weatherLocations.count > 0 {
            currentIndex = 0
        }
        
        
        // loadSavedState here.  load last seen index as currentIndex
        
        weatherAPI.getCurrentLocation()
        prepareBackgroundImageViews()
        setupToolbar()
    }
    
    
    //MARK: Weather Updates
    
    func updateWeatherData(currentIndex: Int?, forceUpdate: Bool) {
        if let index = currentIndex {
            weatherAPI.refreshWeather(index, forceUpdate: forceUpdate)

        } else {
            weatherAPI.getCurrentLocation()
        }
    }
    

    //MARK: Helper Methods
    
    func refreshList() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let index = self.currentIndex {
                self.collectionView?.reloadData()
                if (self.weatherLocations.count > index) {
                    self.collectionView?.selectItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), animated: false, scrollPosition: .CenteredHorizontally)
                }
            }
        })
    }
    
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
        backgroundImageView.image = getImage(currentIndex)
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
    
    func getTimeSinceLastUpdate(unixTime: Int) -> String {
            let elapsedTimeInSeconds = getElapsedTimeInSeconds(unixTime)
            let elapsedTimeInMinutes = elapsedTimeInSeconds / 60
            return createLastUpdateLabelMessage(elapsedTimeInMinutes)
    }
    
    
    func getElapsedTimeInSeconds(unixTime: Int) -> Int {
        let lastUpdateTimestamp = NSTimeInterval(unixTime)
        let elapsedTime = NSDate().timeIntervalSince1970 - lastUpdateTimestamp
        return Int(elapsedTime)
    }
    
    
    func createLastUpdateLabelMessage(elapsedTimeInMinutes: Int) -> String {
        switch (elapsedTimeInMinutes) {
            case 0...2:
                return "updated a moment ago"
            case 3...55:
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
    
    func viewBecameActive() {
        if (currentIndex == 0) {
            weatherAPI.getCurrentLocation()
        }
        updateWeatherData(currentIndex, forceUpdate: false)
    }
    

    func getImage(index: Int?) -> UIImage {
        if (index != nil && index < weatherLocations.count) {
            let location = weatherLocations[index!]
            if let imageString = location.imageString {
                var imageName : String?
 
                switch imageString {
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

                var weatherImage = UIImage(named: imageName!)
                return weatherImage!
            }
        }
        // if all else fails, return the default image
        return UIImage(named: "default")!
    }
    


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showLocationsList" ) {
            let vc = segue.destinationViewController as! LocationsTableViewController
 
            vc.currentIndex = currentIndex
            
            // Transition Animation
            vc.transitioningDelegate = self.transitionManager
            self.transitionManager.locationsListController = vc
        }
    }


    //MARK: Buttons
    
    
    func refreshWasPressed() {
        if (currentIndex == 0 && weatherAPI.locationServicesEnabled) {
            weatherAPI.getCurrentLocation()
        }
        updateWeatherData(currentIndex, forceUpdate: true)
    }
    
    func addWasPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier("showLocationsList", sender: self)
    }
    
    @IBAction func unwindFromList(sender: UIStoryboardSegue) {
        
    }
}

extension WeatherViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: UICollectionViewDelegate and Data Source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.weatherLocations.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.cellReuseIdentifier, forIndexPath: indexPath) as! WeatherViewCell
        
        
        
        let location = weatherLocations[indexPath.row]
        currentIndex = indexPath.row

        cell.locationNameLabel.text = location.displayName
        if let temperature = location.temperature,
                            summary = location.summary,
                            precip = location.precip,
                            wind = location.wind,
                            highTemp = location.currentDayHighTemp,
                            lowTemp = location.currentDayLowTemp,
                            unixTime = location.unixTime
        {
            cell.currentTemperatureLabel!.text = "\(temperature)"
            cell.currentSummaryLabel.text = summary
            cell.currentPrecipLabel.text = "Precip: \(precip)%"
            cell.currentWindLabel.text = "Wind: \(wind) MPH"
            cell.currentHighLowLabel.text = "\(highTemp)° / \(lowTemp)°"
            cell.lastUpdateTimeLabel.text = getTimeSinceLastUpdate(unixTime)
        }
            toImage = getImage(indexPath.row)
        
            nextImageView.image = toImage
        
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.bounds.size
        
    }
    
    
}

extension WeatherViewController : UIScrollViewDelegate {
    
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
            
            //update current Index
            currentIndex = currentIndexPath!.row
            backgroundImageView.image = getImage(currentIndex!)
            
            // reset cross dissolve image views
            backgroundImageView.alpha = 1.0
            nextImageView.alpha = 0.0
        }
    }
}

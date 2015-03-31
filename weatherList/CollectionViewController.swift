//
//  CollectionViewController.swift
//  weatherList
//
//  Created by Mac Pro on 3/29/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit

let reuseIdentifier = "Cell"

class CollectionViewController: UICollectionViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    let navTitleArray = ["index 0", "index 1", "index 2", "index 3"]
    var currentWeather : [NSDictionary]?
    let dataModel = DataModel()
    let defaults = NSUserDefaults.standardUserDefaults()
    var currentIndex : Int?
    var backgroundImageView = UIImageView(image: UIImage(named: "defaultWeatherImage"))
    var nextImageView = UIImageView(image: UIImage(named: "cloudy"))

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextImageView.alpha = 0.0
        let backgroundView = UIView(frame: self.view.frame)
        backgroundView.addSubview(backgroundImageView)
        backgroundView.addSubview(nextImageView)
        
        self.collectionView?.backgroundView = backgroundView
        self.backgroundImageView.contentMode = .Center
        
        self.dataModel.getLocation()

        
        // set nav bar
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(named: "lightNavBarBackground"), forBarMetrics: .Default)
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        
        let navBarFont = UIFont(name: "HelveticaNeue-Light", size: 14.0)
        let fontDict = [NSFontAttributeName: navBarFont!, NSForegroundColorAttributeName: UIColor.whiteColor() ]
        
        self.navigationController?.navigationBar.titleTextAttributes = fontDict
        
        
        
        
        if let weatherDict = defaults.arrayForKey("savedLocations") as? [NSDictionary] {
            currentWeather = weatherDict
            println(weatherDict)
        }
        
        dataModel.getLocationsList()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationsChanged", name:
            "locationsUpdated", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "weatherRefreshed", name:
            "weatherRefreshed", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationsChanged", name: "currentLocationUpdated", object: nil)
        
        }
    
    func locationsChanged() {
        println("locationsUpdated")
        self.collectionView!.reloadData()
//        self.dataModel.refreshAllWeather()

    }
    
    func weatherRefreshed() {
        println("collection reloaded from refreshed weather")
        self.collectionView!.reloadData()
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        if let weatherCount = defaults.arrayForKey("savedLocations") {
            return weatherCount.count
        }
        return 0
        
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    
        println("end dragging")
        self.navigationItem.title = navTitleArray[currentIndex!]
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
//        println("did scroll")
        
        let percentage = (scrollView.contentOffset.x / scrollView.contentSize.width) * 2

//        println("scrolled: \(Int(percentage * 100))%")
        println("scrolled: \(percentage)")
        self.backgroundImageView.alpha = 1.0 - percentage
        self.nextImageView.alpha = 0.0 + percentage
        
    }
    


    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as CollectionViewCell


        if let current = defaults.arrayForKey("savedLocations") as? [NSDictionary] {
            let currentLocation = current[indexPath.row]
            cell.temperatureLabel.text = currentLocation["temperature"] as? String
            cell.locationNameLabel.text = currentLocation["locationName"] as? String
            cell.summaryLabel.text = currentLocation["summary"] as? String
            
            currentIndex = indexPath.row
//            self.navigationItem.title = currentLocation["locationName"] as? String
            currentIndex = indexPath.row
            if let weatherIconString = currentLocation["icon"] as? String {
                println(weatherIconString)
                let weatherImage = self.dataModel.weatherIconFromString(weatherIconString)
//                let weatherImage = UIImage(named: "defaultWeatherImage")
                self.backgroundImageView.image = weatherImage
                
                
                if ((indexPath.row + 1) < current.count) {
                    let nextLocation = current[indexPath.row + 1]
                    if let nextIconString = nextLocation["icon"] as? String {
                        let nextImage = self.dataModel.weatherIconFromString(nextIconString)
                        self.nextImageView.image = nextImage
                        
                    }
                }
            }
            
            

            
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.bounds.size
        
    }
    
    
    @IBAction func refreshWasPressed(sender: UIBarButtonItem) {
        self.dataModel.refresh(self.currentIndex!)
        
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}

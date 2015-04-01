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
    

    var currentWeather : [NSDictionary]?
    let dataModel = DataModel()
    let defaults = NSUserDefaults.standardUserDefaults()
    var currentIndex : Int?
    var backgroundImageView = UIImageView(image: UIImage(named: "defaultWeatherImage"))
    var nextImageView = UIImageView(image: UIImage(named: "cloudy"))
    var percentage : CGFloat = 0.0
    var scrollOffset : CGFloat?
    var titleOrigin : CGFloat?

    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentIndex = 0
        
        // set nav bar
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(named: "lightNavBarBackground"), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        let navBarFont = UIFont(name: "HelveticaNeue-Light", size: 14.0)
        let fontDict = [NSFontAttributeName: navBarFont!, NSForegroundColorAttributeName: UIColor.whiteColor() ]
        self.navigationController?.navigationBar.titleTextAttributes = fontDict
//        self.navigationController?.navigationBarHidden = true
//        self.navigationController?.toolbarHidden = false

        // prepare background imageViews for transitions
        nextImageView.alpha = 0.0
        let backgroundView = UIView(frame: self.view.frame)
        backgroundView.addSubview(backgroundImageView)
        backgroundView.addSubview(nextImageView)
        self.collectionView?.backgroundView = backgroundView
        self.backgroundImageView.contentMode = .Center
        
        // Get current location and list of locations
        dataModel.getLocation()
        dataModel.getLocationsList()


        if let weatherDict = defaults.arrayForKey("savedLocations") as? [NSDictionary] {
            currentWeather = weatherDict
            println(weatherDict)
        }
        
        
        
    }
    
    func locationsChanged() {
        self.collectionView!.reloadData()

    }
    
    func weatherRefreshed() {
        self.collectionView!.reloadData()
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        if let weatherCount = currentWeather {
            return weatherCount.count
        }
        return 0
        
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {

        
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        println("end dragging")
        println("percent \(percentage)")
        var distanceSwiped = scrollView.contentOffset.x - scrollOffset!
        println("scroll current content offset: \(scrollView.contentOffset.x)")
        println("scroll offset variable: \(scrollOffset)")
        println("scroll distance: \(distanceSwiped)")
        println("width: \(self.view.bounds.width)")
        if (abs(distanceSwiped) > (self.view.bounds.width / 2)) {
            println("cell changed")
            let centerPoint = CGPointMake(self.collectionView!.frame.size.width / 2 + scrollView.contentOffset.x, self.collectionView!.frame.size.height / 2)
            let thisIndex = self.collectionView!.indexPathForItemAtPoint(centerPoint)
            currentIndex = thisIndex!.row
            self.navTitle.frame.origin.x = titleOrigin!
            self.navTitle.text = currentWeather![thisIndex!.row]["locationName"] as? String
            
        } else {
            println("not far enough")
        }
        
    }
    
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollOffset = scrollView.contentOffset.x
        println("scroll offset: \(scrollOffset)")
        
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
//        println("did scroll")
        
        percentage = (scrollView.contentOffset.x / self.view.frame.width)

        self.backgroundImageView.alpha = 1.0 - percentage
        self.nextImageView.alpha = 0.0 + percentage
        titleOrigin = self.navTitle.frame.origin.x
        self.navTitle.frame.origin.x -= scrollView.contentOffset.x / 4

        
    }
    


    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as CollectionViewCell


        if (currentWeather != nil) {
            let currentLocation = currentWeather![indexPath.row]
            
            
            cell.temperatureLabel.text = currentLocation["temperature"] as? String
            cell.locationNameLabel.text = currentLocation["locationName"] as? String
            cell.summaryLabel.text = currentLocation["summary"] as? String

            if let weatherIconString = currentLocation["icon"] as? String {
                let weatherImage = self.dataModel.weatherIconFromString(weatherIconString)
                self.backgroundImageView.image = weatherImage
            }
            
            if ((indexPath.row + 1) < currentWeather!.count) {
                let nextLocation = currentWeather![indexPath.row + 1]
                if let nextIconString = nextLocation["icon"] as? String {
                    let nextImage = self.dataModel.weatherIconFromString(nextIconString)
                    self.nextImageView.image = nextImage
                    
                }
            }
            
            
            

            
        }
        currentIndex = indexPath.row
        println(currentIndex)
        return cell
    }
    
    func populateWeatherView(index: Int) {
        
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.bounds.size
        
    }
    
    
    @IBAction func refreshWasPressed(sender: UIBarButtonItem) {
        self.dataModel.refresh(self.currentIndex!)
        self.collectionView?.reloadData()
        
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

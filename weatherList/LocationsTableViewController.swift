//
//  LocationsTableViewController.swift
//  Stormy
//
//  Created by Mac Pro on 3/25/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation


protocol LocationsTableViewControllerDelegate  {
    
    func didDeleteLocation()
    func didAddLocation(weatherDict: [Int : WeatherData], weatherTags: [Int])
    
    
}





class LocationsTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    var searchResults: String?
    let geoCoder = CLGeocoder()
    var placemarks = []
    let searchResultsView = UITableViewController()
    var results: NSMutableArray?
    var searchController : UISearchController?
    var savedLocations: [NSDictionary]?
    let dataModel = DataModel()
    var backgroundImage : UIImage?
    
    var delegate : LocationsTableViewControllerDelegate?
    
    let weatherRequester = WeatherRequester()
    
    var weatherDict : [Int : WeatherData] = {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("savedLocations") as? NSData {
            let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as [Int : WeatherData]
            return dict
        }
        return [Int : WeatherData]()
    }()
    
    var weatherTags : [Int] = {
        if let tags = NSUserDefaults.standardUserDefaults().arrayForKey("weatherTags") as? [Int] {
            return tags
        }
        return [Int]()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let backgroundView = UIImageView(frame: self.view.bounds)
//        backgroundView.image = backgroundImage!
        self.view.addSubview(backgroundView)
        self.tableView.sendSubviewToBack(backgroundView)
        

        // Instantiate Search Controller
        self.searchController = UISearchController(searchResultsController: searchResultsView)
        self.searchController!.searchResultsUpdater = self
        self.searchController!.searchBar.delegate = self
        self.searchController!.delegate = self
        self.searchController!.dimsBackgroundDuringPresentation = false
        self.searchController!.hidesNavigationBarDuringPresentation = false
        self.searchController!.searchBar.showsCancelButton = true
        self.navigationItem.titleView = searchController!.searchBar
        self.searchResultsView.navigationItem.titleView = searchController!.searchBar
        
        let resultsTableView = UITableView(frame: self.tableView.frame)
        self.searchResultsView.tableView = resultsTableView
        self.searchResultsView.tableView.dataSource = self
        self.searchResultsView.tableView.delegate = self
        self.searchResultsView.navigationController?.navigationBarHidden = true
        self.definesPresentationContext = true
        
        self.tableView.backgroundColor = UIColor.clearColor()
        

        // Instantiate Table View Cell
        self.searchResultsView.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
    }
    
    
    func locationsChanged() {
        println("locationsUpdated in tables")
        self.tableView.reloadData()
    }

    // MARK: - Search Bar Data source
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {

        geoCodeString(searchController.searchBar.text)
        self.searchResultsView.tableView.reloadData()
        
    }

    
    func geoCodeString(locationString: String) {
        if (locationString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
            self.geoCoder.geocodeAddressString(locationString, completionHandler: { (placemarks, error) -> Void in
                
                if (error == nil) {
                    self.placemarks = placemarks
                } else {
                    println(error)
                }
            })
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchResults = searchBar.text
        if (self.placemarks.count != 0) {
            createLocationFromPlacemark(self.placemarks[0] as CLPlacemark)
        }
        searchBar.resignFirstResponder()
        searchBar.text = ""
        
    }
    
    
     func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.searchController?.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    //MARK: - Search Locations
    
    func createLocationFromPlacemark(placemark: CLPlacemark) {

        weatherRequester.getWeatherData(placemark, isLocal: false) { (weatherData, tag) -> Void in
            
            // add or update location in the weather Dictionary with local tag key: 0
            self.weatherDict[placemark.hash] = weatherData
            // if the local tag is already in the weatherTags array, make sure it is first
            if let index = find(self.weatherTags, placemark.hash) {
                    println("already in tags array")
            } else {
                self.weatherTags.append(placemark.hash)
            }
            println("request finished: \(placemark.hash)")
            println("dict: \(self.weatherDict)")
            println("tags: \(self.weatherTags)")
            
            //testing delegate
            println("delegate should be called")
            self.delegate?.didAddLocation(self.weatherDict, weatherTags: self.weatherTags)
            
            
            // store download data
            let data = NSKeyedArchiver.archivedDataWithRootObject(self.weatherDict)
            NSUserDefaults.standardUserDefaults().setObject(data, forKey: "savedLocations")
            NSUserDefaults.standardUserDefaults().setObject(self.weatherTags, forKey: "weatherTags")

            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                println("data reloaded")
            })
            
            
            
        }
    }
    
        
        
        
        
//                let location = placemark.location
//                let city = placemark.locality
//                let area = placemark.administrativeArea
//
//                // get location name
//                let locationName = "\(city), \(area)"
//                
//                //get Coordinates
//                let coordinate = location.coordinate
//                let latitudeRaw = "\(coordinate.latitude)"
//                let longitudeRaw = "\(coordinate.longitude)"
//                let latitude = latitudeRaw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
//                let longitude = longitudeRaw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
//                let coordinates = "\(latitude),\(longitude)"
//                let locationDict = ["locationName": locationName, "coordinates": coordinates]
//    
//                
//                //save to user defaults
//                
//                if let savedLocations = self.defaults.arrayForKey("savedLocations") as? [NSDictionary] {
//                    var updatedLocations = savedLocations
//                    updatedLocations.append(locationDict)
//                    self.defaults.setObject(updatedLocations, forKey: "savedLocations")
//                } else {
//                    self.defaults.setObject([[String:String](), locationDict], forKey: "savedLocations")
//                }
//                NSNotificationCenter.defaultCenter().postNotificationName("currentLocationUpdated", object: nil)
//        
//    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.tableView) {
            return weatherTags.count
        }
        if (tableView == self.searchResultsView.tableView) {
            return placemarks.count
        }
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        if (tableView == self.tableView ) {
            
            let tag = weatherTags[indexPath.row]
            
            if let location = weatherDict[tag] as WeatherData! {
                cell.textLabel!.text = location.locationName
                cell.backgroundColor = UIColor.clearColor()
                cell.textLabel!.textColor = UIColor.whiteColor()
            }
            
            if (indexPath.row == 0) {
                cell.accessoryType = .Checkmark
                cell.selectionStyle = .None
            }
        }
        
        if (tableView == self.searchResultsView.tableView) {
        
//            let cell = self.searchResultsView.tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
            if (self.placemarks.count != 0) {
                if let placemark = self.placemarks[indexPath.row] as? CLPlacemark {
                    println("placemark: \(placemark)")
//                    if (placemark. == "en_US") {
                        cell.textLabel!.text = "\(placemark.locality), \(placemark.administrativeArea)"
//                    } else {
//                        cell.textLabel!.text = "\(placemark.locality), \(placemark.ISOcountryCode)"
//                    }
                }
            }
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (tableView == self.searchResultsView.tableView) {
                createLocationFromPlacemark(self.placemarks[indexPath.row] as CLPlacemark)
                searchController?.searchBar.text = ""
                self.placemarks = []
            
        }
        self.tableView.reloadData()
    }

    
    // Override to support conditional editing of the table view.

    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        if (indexPath.row == 0) {
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCellEditingStyle {
            
//            if (indexPath.row == 0) {
//                return UITableViewCellEditingStyle.None
//            }
        return UITableViewCellEditingStyle.Delete
    }
    

    // Override to support editing the table view.
//    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        
//        if editingStyle == .Delete {
//            // Delete the row from the data source
//            
//            if let locations = defaults.arrayForKey("savedLocations") as? [NSDictionary] {
//                var newLocations = locations
//                newLocations.removeAtIndex(indexPath.row)
//                self.defaults.setObject(newLocations, forKey: "savedLocations")
//                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//                NSNotificationCenter.defaultCenter().postNotificationName("locationsUpdated", object: nil)
//                
//            }
//
//        }
//    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return false
    }




    @IBAction func doneWasPressed(sender: AnyObject) {
    }
}

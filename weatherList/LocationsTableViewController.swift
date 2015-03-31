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

class LocationsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    var searchResults: String?
    let geoCoder = CLGeocoder()
    var placemarks : NSMutableArray?
    let searchResultsView = UITableViewController()
    var results: NSMutableArray?
    var searchController : UISearchController?
    var savedLocations: [NSDictionary]?
    let defaults = NSUserDefaults.standardUserDefaults()
    let dataModel = DataModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let locations = defaults.arrayForKey("savedLocations") as? [NSDictionary] {
            self.savedLocations = locations
        }
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController!.searchResultsUpdater = self
        self.searchController!.searchBar.delegate = self
        self.searchController!.delegate = self
        self.searchController!.dimsBackgroundDuringPresentation = false
        self.searchController!.hidesNavigationBarDuringPresentation = false
        self.searchController!.searchBar.showsCancelButton = true
        self.navigationItem.titleView = searchController!.searchBar
        
        let resultsTableView = UITableView(frame: CGRectMake(160, 240, 150, 150))
        self.searchResultsView.tableView = resultsTableView
        self.searchResultsView.tableView.dataSource = self
        self.searchResultsView.tableView.delegate = self
        
        self.searchResultsView.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationsChanged", name:
            "currentLocationUpdated", object: nil)

    
        
    }
    
    func locationsChanged() {
        println("locationsUpdated in tables")
        self.tableView.reloadData()
    }

    // MARK: - Search Bar Data source
    
     func updateSearchResultsForSearchController(searchController: UISearchController) {
        if (searchController.searchBar.text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
        self.geoCoder.geocodeAddressString(searchController.searchBar.text, completionHandler: { (placemarks, error) -> Void in
            if (error == nil) {
                self.placemarks = NSMutableArray(array: placemarks)
                self.searchResultsView.tableView.reloadData()
            } else {
                println(error)
            }
        })
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchResults = searchBar.text
        getCoordinates()
        searchBar.resignFirstResponder()
        searchBar.text = ""
        
        
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar == self.searchController!.searchBar) {
        }
    }
    
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        println("end editing")
    }
    
     func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    //MARK: - Search Locations
    
    func getCoordinates() {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(self.searchResults, completionHandler: { (placemarks, error) -> Void in
            if (error == nil) {
//                self.placemarks = placemarks
                let placemark = placemarks[0] as CLPlacemark
                let location = placemark.location
                let city = placemark.locality
                let area = placemark.administrativeArea
                
                // get location name
                let locationName = "\(city), \(area)"
                
                //get Coordinates
                let coordinate = location.coordinate
                let latitudeRaw = "\(coordinate.latitude)"
                let longitudeRaw = "\(coordinate.longitude)"
                let latitude = latitudeRaw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let longitude = longitudeRaw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let coordinates = "\(latitude),\(longitude)"
                let locationDict = ["locationName": locationName, "coordinates": coordinates]
                
                //save to user defaults
                
                if let savedLocations = self.defaults.arrayForKey("savedLocations") as? [NSDictionary] {
                    var updatedLocations = savedLocations
                    updatedLocations.append(locationDict)
                    self.defaults.setObject(updatedLocations, forKey: "savedLocations")
                } else {
                    self.defaults.setObject([[String:String](), locationDict], forKey: "savedLocations")
                }
                NSNotificationCenter.defaultCenter().postNotificationName("currentLocationUpdated", object: nil)
                
            }
        })
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let locations = defaults.arrayForKey("savedLocations") {
            return locations.count
        }
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (tableView == self.tableView) {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

            if let locations = defaults.arrayForKey("savedLocations") as? [NSDictionary] {
                let location = locations[indexPath.row]
                
                cell.textLabel!.text = (location["locationName"] as String)
                
            }
            if (indexPath.row == 0) {
                cell.accessoryType = .Checkmark
                cell.selectionStyle = .None
            }
            return cell
            
        }
        
        let cell = self.searchResultsView.tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
//            cell.textLabel!.text = (self.placemarks!.objectAtIndex(indexPath.row) as String)
        cell.textLabel!.text = "right cell"
        println("placemarks in cell: \(self.placemarks!.count)")
        return cell
        
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
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            // Delete the row from the data source
            
            if let locations = defaults.arrayForKey("savedLocations") as? [NSDictionary] {
                var newLocations = locations
                newLocations.removeAtIndex(indexPath.row)
                self.defaults.setObject(newLocations, forKey: "savedLocations")
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                NSNotificationCenter.defaultCenter().postNotificationName("locationsUpdated", object: nil)
                
            }

        }
    }

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

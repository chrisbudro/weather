//
//  LocationsTableViewController.swift
//  Stormy
//
//  Created by Mac Pro on 3/25/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit
import CoreLocation


protocol LocationsTableViewControllerDelegate  {
    
    func didDeleteLocation(placeID: String)
    func didAddLocation(placeDetails: (description: String, placeID: String))
    func didArrangeList(weatherPlaceIDs: [String])
    func didSelectLocationFromList(placeID: String)
    
    
}

class LocationsTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    
    
    private struct Constants {
        static let cell = "Cell"
        static let segueDismissList = "dismissList"
        
    }
    
    var searchResults: String?
    let geoCoder = CLGeocoder()
    var placemarks : [(description: String, placeID: String)] = []
    let searchResultsView = UITableViewController()
    var results: NSMutableArray?
    var searchController : UISearchController?
    var delegate : LocationsTableViewControllerDelegate?
    var weatherDict : [String : WeatherData]?
    var weatherPlaceIDs : [String]?
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        // Instantiate Search Controller
        self.searchController = UISearchController(searchResultsController: searchResultsView)
        self.searchController!.searchResultsUpdater = self
        self.searchController!.searchBar.delegate = self
        self.searchController!.delegate = self
        self.searchController!.dimsBackgroundDuringPresentation = false
        self.searchController!.hidesNavigationBarDuringPresentation = true
        self.searchController!.searchBar.showsCancelButton = false
        self.navigationItem.titleView = searchController!.searchBar

        let resultsTableView = UITableView(frame: self.tableView.frame)
        self.searchResultsView.tableView = resultsTableView
        self.searchResultsView.tableView.dataSource = self
        self.searchResultsView.tableView.delegate = self
//        self.searchResultsView.navigationController?.navigationBarHidden = true
        self.definesPresentationContext = true
        
        // Instantiate Table View Cell
        self.searchResultsView.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Constants.cell)
        
        // Table Header
        
        let headerView = UIView(frame: CGRectMake(0, 20, tableView.frame.width, 60.0))

        
        
        
        tableView.frame.size.width = self.view.frame.size.width - 50
        searchController!.searchBar.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 44)
        searchController!.searchBar.backgroundColor = UIColor.lightGrayColor()
        
        
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        
        headerView.addSubview(searchController!.searchBar)
        
        tableView.tableHeaderView = searchController!.searchBar
        
    }


    // MARK: - Search Bar Data source
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        
        // adjust position of search bar when it becomes first responder - bug needs to be figure out
        searchController!.searchBar.frame = CGRectMake(-50, 0, self.tableView.frame.size.width, 44)
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {

        searchForGooglePlaces(searchController.searchBar.text)
        self.searchResultsView.tableView.reloadData()
        
    }

    func searchForGooglePlaces(locationString: String) {
        if (locationString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
            println(locationString)
            
            let apiKey = "AIzaSyAyeGkrgfIa2Ov7Kb8Hzr2pHOYNMPytlWc"
            let placeType = "(cities)"
            let strippedLocationString = locationString.stringByReplacingOccurrencesOfString(" ", withString: "", options: nil, range: nil)
            
            let placesRequestURL = NSURL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(strippedLocationString)&types=\(placeType)&key=\(apiKey)")
            let sharedSession = NSURLSession.sharedSession()
            let downloadTask : NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(placesRequestURL!, completionHandler: { (places : NSURL!, response: NSURLResponse!, error: NSError!) -> Void in
                if (error == nil) {
                    let data = NSData(contentsOfURL: places, options: nil, error: nil)
                    let placesJSON = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary
                    let predictions = placesJSON["predictions"] as! NSArray
                    var placeList : [(description: String, placeID: String)] = []
                    for prediction in predictions {
                        let predictionDescription = prediction["description"] as! String
                        let predictionPlaceID = prediction["place_id"] as! String
                        let predictionDetails : (description: String, placeID: String) = (predictionDescription, predictionPlaceID)
                            placeList.append(predictionDetails)
                    }
                    self.placemarks = placeList
                    
                } else {
                    self.placemarks = []
                    println("error: \(error)")
                }
            })
            downloadTask.resume()
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchResults = searchBar.text
        searchForGooglePlaces(searchBar.text)
        searchBar.resignFirstResponder()
    
    }
    
    
     func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.tableView) {
            return weatherPlaceIDs!.count
        }
        else if (tableView == self.searchResultsView.tableView) {
            return placemarks.count
        }
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.cell, forIndexPath: indexPath) as! UITableViewCell
        
        if (tableView == self.tableView ) {
            
            let placeID = weatherPlaceIDs![indexPath.row]
            
            if let location = weatherDict![placeID] as WeatherData! {
                cell.textLabel!.text = location.locationName
                cell.backgroundColor = UIColor.clearColor()
                cell.textLabel!.textColor = UIColor.blackColor()
            }
            
            if (indexPath.row == 0) {
                cell.accessoryType = .Checkmark
                cell.selectionStyle = .None
            }
        }
        else if (tableView == self.searchResultsView.tableView) {
    
            if (self.placemarks.count > indexPath.row) {
                let placeDetails = placemarks[indexPath.row]
                cell.textLabel!.text = placeDetails.description
                }
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var placeID : String?
        
        if (tableView == self.searchResultsView.tableView) {
            if (self.placemarks.count > indexPath.row) {
                let placeDetails = self.placemarks[indexPath.row]
                placeID = placeDetails.placeID
                self.delegate?.didAddLocation(placeDetails)
                weatherPlaceIDs!.append(placeID!)
                searchController?.searchBar.text = ""
                
            } else {
                println("Placemarker for UIAlert View:  An error has occured please try adding the location again")
            }
            
            self.placemarks = []
            
        } else if (tableView == self.tableView) {
            placeID = weatherPlaceIDs![indexPath.row]
        }
        
        self.delegate?.didSelectLocationFromList(placeID!)
        performSegueWithIdentifier(Constants.segueDismissList, sender: self)
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
            
        return UITableViewCellEditingStyle.Delete
    }
    

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.beginUpdates()
            let placeID = weatherPlaceIDs![indexPath.row]
            self.delegate?.didDeleteLocation(placeID)
            weatherPlaceIDs?.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.endUpdates()
                
            }
    }


    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        tableView.beginUpdates()
        let movedItem = weatherPlaceIDs![fromIndexPath.row]
        weatherPlaceIDs?.removeAtIndex(fromIndexPath.row)
        weatherPlaceIDs?.insert(movedItem, atIndex: toIndexPath.row)
        tableView.endUpdates()
        
        tableView.reloadData()
        
        self.delegate?.didArrangeList(weatherPlaceIDs!)
        
    }


    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        if (indexPath.row == 0) {
            return false
        }
        
        return true
    }


    @IBAction func editWasPressed(sender: UIBarButtonItem) {
        tableView.editing = true
        tableView.reloadData()
    }

    func doneWasPressed(sender: AnyObject) {

    }
}

//
//  LocationsTableViewController.swift
//  Stormy
//
//  Created by Mac Pro on 3/25/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit
import CoreLocation


class LocationsTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    
    
    private struct Constants {
        static let cell = "Cell"
        static let segueDismissList = "dismissList"
        
    }
    
    let weatherAPI = WeatherAPI.sharedInstance
    
    var searchResults: String?
    let geoCoder = CLGeocoder()
    var autoCompleteResults : [(description: String, placeID: String)] = []
    let searchResultsView = UITableViewController()
//    var results: NSMutableArray?
    var searchController : UISearchController?
    var currentIndex : Int?
    var weatherLocations : [WeatherData] {
        return weatherAPI.getLocations()
    }

    
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

        
        
        
        tableView.frame.size.width = UIApplication.sharedApplication().keyWindow!.frame.size.width - 50
        tableView.frame.size.height = UIApplication.sharedApplication().keyWindow!.frame.size.height
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

        getAutoCompleteResults(searchController.searchBar.text)
        self.searchResultsView.tableView.reloadData()
    }

    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchResults = searchBar.text
        getAutoCompleteResults(searchBar.text)
        searchBar.resignFirstResponder()
    
    }
    
    
     func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
    }
    
    
    //MARK: Helper Methods 
    
    func getAutoCompleteResults(searchTerm: String) {
        weatherAPI.getAutoCompleteResults(searchTerm, completion: { (placeList, error) -> Void in
            if error == nil {
                self.autoCompleteResults = placeList
                println("placeList: \(placeList)")
            } else {
                println("autocomplete error: \(error)")
            }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.segueDismissList {
            let vc = segue.destinationViewController as! WeatherViewController
            if let index = currentIndex {
                vc.currentIndex = index
                currentIndex = nil
            }
        }
    }
    
    @IBAction func editWasPressed(sender: UIBarButtonItem) {
        tableView.editing = true
        tableView.reloadData()
    }
    
    func doneWasPressed(sender: AnyObject) {
        
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.tableView) {
            return weatherLocations.count
        }
        else if (tableView == self.searchResultsView.tableView) {
            return autoCompleteResults.count
        }
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.cell, forIndexPath: indexPath) as! UITableViewCell
        
        if (tableView == self.tableView ) {
            
            let location = weatherLocations[indexPath.row]
            
                cell.textLabel!.text = location.locationName
                cell.backgroundColor = UIColor.clearColor()
                cell.textLabel!.textColor = UIColor.blackColor()
            
            
            if (indexPath.row == 0 && weatherAPI.locationServicesEnabled) {
                cell.accessoryType = .Checkmark
                cell.selectionStyle = .None
            }
        }
        else if (tableView == self.searchResultsView.tableView) {
    
            if (self.autoCompleteResults.count > indexPath.row) {
                let placeDetails = autoCompleteResults[indexPath.row]
                cell.textLabel!.text = placeDetails.description
                }
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if (tableView == self.tableView) {
            // set updated index for collection view to scroll to
            currentIndex = indexPath.row
            
        } else if (tableView == self.searchResultsView.tableView) {
            if (self.autoCompleteResults.count > indexPath.row) {
                let placeDetails = self.autoCompleteResults[indexPath.row]
                weatherAPI.createLocation(placeDetails)
                searchController?.searchBar.text = ""
                currentIndex = weatherLocations.count - 1
                
            } else {
                println("Placemarker for UIAlert View:  An error has occured please try adding the location again")
            }
            autoCompleteResults = []
        }
        
        performSegueWithIdentifier(Constants.segueDismissList, sender: self)
        self.tableView.reloadData()
    }

    
    //MARK: Table View Editing
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        if (indexPath.row == 0 && weatherAPI.locationServicesEnabled) {
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCellEditingStyle {
            
        return UITableViewCellEditingStyle.Delete
    }
    

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.beginUpdates()
            
            weatherAPI.deleteLocation(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.endUpdates()
                
            }
    }


    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
        weatherAPI.moveLocation(fromIndexPath.row, toIndex: toIndexPath.row)
        tableView.reloadData()
    
    }

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        if (indexPath.row == 0 && weatherAPI.locationServicesEnabled) {
            return false
        }
        return true
    }

}


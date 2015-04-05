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
    
    func didDeleteLocation(tag: Int)
    func didAddLocation(placemark: CLPlacemark)
    func didArrangeList(weatherTags: [Int])
    func didSelectLocationFromList(tag: Int)
    
    
}

class LocationsTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    var searchResults: String?
    let geoCoder = CLGeocoder()
    var placemarks = []
    let searchResultsView = UITableViewController()
    var results: NSMutableArray?
    var searchController : UISearchController?
    var delegate : LocationsTableViewControllerDelegate?
    var weatherDict : [Int : WeatherData]?
    var weatherTags : [Int]?
    

    
    
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
        self.searchResultsView.navigationController?.navigationBarHidden = true
        self.definesPresentationContext = true
        
        // Instantiate Table View Cell
        self.searchResultsView.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Table Header
        
        let headerView = UIView(frame: CGRectMake(0, 20, tableView.frame.width, 60.0))

        
        
        
        tableView.frame.size.width = self.view.frame.size.width - 40
        searchController!.searchBar.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 44)
        searchController!.searchBar.backgroundColor = UIColor.lightGrayColor()
        
        
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        
        headerView.addSubview(searchController!.searchBar)
        
        tableView.tableHeaderView = searchController!.searchBar
        
        
        
        
        
        
        
//        id barButtonAppearanceInSearchBar = [UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil];
//        
//        [barButtonAppearanceInSearchBar setBackgroundImage:grayBackgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//        [barButtonAppearanceInSearchBar setTitleTextAttributes:@{
//            UITextAttributeFont : [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:20],
//            UITextAttributeTextColor : [UIColor blackColor]
//        } forState:UIControlStateNormal];
//        [barButtonAppearanceInSearchBar setTitle:@"X"];
        
    }


    // MARK: - Search Bar Data source
    
    
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        println("begin editing")
        searchController!.searchBar.frame = CGRectMake(-40, 0, self.tableView.frame.size.width, 44)
    }
    
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
                    self.placemarks = []
                    println(error)
                }
            })
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchResults = searchBar.text
        if (self.placemarks.count != 0) {
            self.delegate?.didAddLocation(self.placemarks[0] as! CLPlacemark)
        }
        searchBar.resignFirstResponder()
        searchBar.text = ""
        self.searchController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
     func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.searchController?.dismissViewControllerAnimated(true, completion: nil)
        
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.tableView) {
            return weatherTags!.count
        }
        if (tableView == self.searchResultsView.tableView) {
            return placemarks.count
        }
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        if (tableView == self.tableView ) {
            
            let tag = weatherTags![indexPath.row]
            
            if let location = weatherDict![tag] as WeatherData! {
                cell.textLabel!.text = location.locationName
                cell.backgroundColor = UIColor.clearColor()
                cell.textLabel!.textColor = UIColor.blackColor()
            }
            
            if (indexPath.row == 0) {
                cell.accessoryType = .Checkmark
                cell.selectionStyle = .None
            }
        }
        
        if (tableView == self.searchResultsView.tableView) {
    
            if (self.placemarks.count > indexPath.row) {
                if let placemark = self.placemarks[indexPath.row] as? CLPlacemark {
                    println("placemark: \(placemark)")
                    cell.textLabel!.text = "\(placemark.locality), \(placemark.administrativeArea)"
                }
            }
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var tag : Int?
        
        if (tableView == self.searchResultsView.tableView) {
            if (self.placemarks.count > indexPath.row) {
                let placemark = self.placemarks[indexPath.row] as! CLPlacemark
                self.delegate?.didAddLocation(placemark)
                weatherTags!.append(placemark.location.hash)
                searchController?.searchBar.text = ""
                tag = placemark.location.hash
                
            } else {
                println("Placemarker for UIAlert View:  An error has occured please try adding the location again")
            }
            
            self.placemarks = []
            
        } else if (tableView == self.tableView) {
            tag = weatherTags![indexPath.row]
        }
        
        self.delegate?.didSelectLocationFromList(tag!)
        performSegueWithIdentifier("dismissList", sender: self)
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
            let tag = weatherTags![indexPath.row]
            self.delegate?.didDeleteLocation(tag)
            weatherTags!.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.endUpdates()
                
            }
    }


    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        tableView.beginUpdates()
        let movedItem = weatherTags![fromIndexPath.row]
        weatherTags?.removeAtIndex(fromIndexPath.row)
        weatherTags?.insert(movedItem, atIndex: toIndexPath.row)
        tableView.endUpdates()
        
        tableView.reloadData()
        
        self.delegate?.didArrangeList(weatherTags!)
        
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

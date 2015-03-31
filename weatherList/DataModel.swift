//
//  DataModel.swift
//  Stormy
//
//  Created by Chris Budro on 3/28/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class DataModel : NSObject, CLLocationManagerDelegate {
    
    private let apiKey = ""
    var locationsArray : [NSDictionary]?
    let locationManager = CLLocationManager()
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override init() {
        let pathToFile = NSBundle.mainBundle().pathForResource("APIKey", ofType: "")
        let file = NSString(contentsOfFile: pathToFile!, encoding: NSUTF8StringEncoding, error: nil)
        self.apiKey = file!.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }
    
    func getLocationsList() {
        // while this method is loading display activity indicator
        
        // if savedLocations in NSUserDefaults is not nil then assign it to locationsArray
        

        if let savedLocations = defaults.arrayForKey("savedLocations") as? [NSDictionary]
        {
            locationsArray = savedLocations
            NSNotificationCenter.defaultCenter().postNotificationName("locationsUpdated", object: nil)
        }
        else {
            // get current location
            self.getLocation()
            
            // upon completion, save current location to user defaults
            // pull from user defaults and assign to locations array
            // upon completion run refreshWeather()
        }
        
        // hide activity indicator
        
    }
    
    func getLocation() {
        println(self.apiKey)
        println("getting location")
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = 1000
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.locationManager.stopUpdatingLocation()
        let locationData = locations[0] as CLLocation
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(locationData, completionHandler: {(placemarks, error) -> Void in
            if error == nil {
                let placeMarks = placemarks as [CLPlacemark]
                let placemark = placeMarks[0] as CLPlacemark
                let locationName = "\(placemark.locality), \(placemark.administrativeArea)"
                let coordinates = "\(locationData.coordinate.latitude),\(locationData.coordinate.longitude)"
                let savedLocation = ["locationName": locationName, "coordinates": coordinates]

                
                // save userDefaults
                let defaults = NSUserDefaults.standardUserDefaults()
                if let savedLocations = defaults.arrayForKey("savedLocations") as? [NSDictionary]
                {
                    var updatedLocations = savedLocations
                    updatedLocations[0] = savedLocation
                    defaults.setObject(updatedLocations, forKey: "savedLocations")
                    NSNotificationCenter.defaultCenter().postNotificationName("locationsUpdated", object: nil)
                } else {
                    defaults.setObject([savedLocation], forKey: "savedLocations")
                }
                println("refreshing index 0: current location")
                self.refresh(0)
            } else {
                println("location fetch failed")
            }
        })
    }
    
    func refreshAllWeather() {
        
        if let locationsArray = self.defaults.arrayForKey("savedLocations") {
        
            for (index, location) in enumerate(locationsArray) {
                self.refresh(index)
            }
        }
    }
        
        
    func makeWeather(weatherDict: NSDictionary, locationName: String, coordinates: String) -> NSDictionary {
        let currentWeather = weatherDict["currently"] as NSDictionary
        var newWeatherDict = [String: String]()
        
        let temperature = currentWeather["apparentTemperature"] as Int
        newWeatherDict["temperature"] = "\(temperature)"
        newWeatherDict["humidity"] = currentWeather["humidity"] as? String
        newWeatherDict["precip"] = currentWeather["precipProbability"] as? String
        newWeatherDict["summary"] = currentWeather["summary"] as? String
        let currentIcon = currentWeather["icon"] as String
        newWeatherDict["icon"] =  "\(currentIcon)"
        
        let currentTimeIntValue = currentWeather["time"] as Int
        let currentTime = self.dateStringFromUnixTime(currentTimeIntValue) as String
        newWeatherDict["time"] = currentTime
        
        newWeatherDict["locationName"] = locationName
        newWeatherDict["coordinates"] = coordinates
        
        return newWeatherDict
    }
    
    func weatherIconFromString(stringIcon: String) -> UIImage! {
        var imageName: String
        
        switch stringIcon {
        case "clear-day":
            imageName = "defaultWeatherImage"
//        case "clear-night":
//            imageName = "clear-night"
        case "rain":
            imageName = "rain"
        case "snow":
            imageName = "snow"
        case "sleet":
            imageName = "rain"
//        case "wind":
//            imageName = "wind"
//        case "fog":
//            imageName = "fog"
        case "cloudy":
            imageName = "cloudy"
        case "partly-cloudy-day":
            imageName = "partly-cloudy"
        case "partly-cloudy-night":
            imageName = "partly-cloudy"
        default:
            imageName = "defaultWeatherImage"
        }
        var iconImage = UIImage(named: imageName)
        return iconImage!
        
    }
    
    func dateStringFromUnixTime(unixTime: Int) -> String {
        let timeInSeconds = NSTimeInterval(unixTime)
        let weatherDate = NSDate(timeIntervalSince1970: timeInSeconds)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .ShortStyle
        let dateString = dateFormatter.stringFromDate(weatherDate) as String
        return dateString
    }
        
        
    func refresh(index: Int) {
        println("starting refresh")
        if let locations = defaults.arrayForKey("savedLocations") as? [NSDictionary] {
            let location = locations[index]
            let currentName = location["locationName"] as String
            let coordinates = location["coordinates"] as String
            
            let baseURL: NSURL = NSURL(string: "https://api.forecast.io/forecast/\(self.apiKey)/")!
            let forecastURL = NSURL(string: coordinates, relativeToURL:baseURL)
            let sharedSession = NSURLSession.sharedSession()
            let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastURL!, completionHandler: { (location: NSURL!, response:NSURLResponse!, error: NSError!) -> Void in
                
                if error == nil {
                    let weatherData = NSData(contentsOfURL: location, options: nil, error: nil)
                    let weatherDict : NSDictionary = NSJSONSerialization.JSONObjectWithData(weatherData!, options: nil, error: nil) as NSDictionary
                    
                    let currentWeather = self.makeWeather(weatherDict, locationName: currentName, coordinates: coordinates)
                    var newLocations = self.defaults.arrayForKey("savedLocations") as [NSDictionary]
                    newLocations[index] = currentWeather
                    self.defaults.setObject(newLocations, forKey: "savedLocations")
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName("weatherRefreshed", object: nil)
                    })

                    
                    
                } else {
                    println(error)
                }
            })
            downloadTask.resume()
        }
    }
        
        
        
    
//    func refreshWeather(index: Int, viewController: DataViewController) {
//        if (self.locationsArray.count != 0) {
//            let currentLocation = locationsArray[index] as [String]
//            currentName = currentLocation[0] as String
//            let coordinates = currentLocation[1] as String
//        }
//        
//        let baseURL: NSURL = NSURL(string: "https://api.forecast.io/forecast/\(self.apiKey)/")!
//        let forecastURL = NSURL(string: coordinates, relativeToURL:baseURL)
//        let sharedSession = NSURLSession.sharedSession()
//        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastURL!, completionHandler: { (location: NSURL!, response:NSURLResponse!, error: NSError!) -> Void in
//            
//            if error == nil {
//                let weatherData = NSData(contentsOfURL: location, options: nil, error: nil)
//                let weatherDict : NSDictionary = NSJSONSerialization.JSONObjectWithData(weatherData!, options: nil, error: nil) as NSDictionary
//                
//                
//                var currentWeather = Current(weatherDict: weatherDict)
//                currentWeather.locationName = currentName
//                
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    viewController.tempLabel.text = "\(currentWeather.temperature)"
//                    viewController.currentTimeLabel.text = "\(currentWeather.currentTime!)"
//                    viewController.humidityLabel.text = "\(currentWeather.humidity * 100)%"
//                    viewController.precipLabel.text = "\(currentWeather.precipProbability * 100)%"
//                    viewController.summaryLabel.text = currentWeather.summary
//                    viewController.iconView.image = currentWeather.icon
//                    viewController.locationName.text = currentWeather.locationName
//                    println("in url call: \(self.locationsArray)")
//                })
//                
//            }
//        })
//        
//        downloadTask.resume()
//        
//    }
    
}
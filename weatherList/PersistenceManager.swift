//
//  PersistenceManager.swift
//  weatherList
//
//  Created by Mac Pro on 4/6/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit

class PersistenceManager: NSObject {
    
    private struct Constants {
        static let weatherLocations = "weatherLocations"
    }
    
    private var weatherLocations : [WeatherData] = [] {
        didSet{
            NSNotificationCenter.defaultCenter().postNotificationName("locationsListUpdated", object: nil)
            println("persistence updated")
        }
    }
    let defaults = NSUserDefaults.standardUserDefaults()
    

    
    override init() {
        super.init()
        if let data = defaults.objectForKey(Constants.weatherLocations) as? NSData {
            let decodedWeatherLocations = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [WeatherData]?
            if let decodedLocations = decodedWeatherLocations {
                weatherLocations = decodedLocations
            }
        } else {
            weatherLocations = getPlaceholderLocation()
        }
        println("weather locations: \(weatherLocations)")
        
    }
    
    func getPlaceholderLocation() -> [WeatherData] {
        let data = WeatherData()
        data.locationName = "Asheville, NC"
        data.displayName = "Asheville"
        data.coordinates = "35.590878,-82.538970"
        data.temperature = 70
        data.precip = 10
        data.wind = 5
        data.summary = "Partly Cloudy"
        data.unixTime = 1428463969
        data.placeID = "placeholder"
        data.currentDayHighTemp = 75
        data.currentDayLowTemp = 56
        data.imageString = "partly-cloudy"
        
        return [data]
    }
    
    
    func getLocations() -> [WeatherData] {
        return weatherLocations
    }
    
    func createLocation(placeDetails: (description: String, placeID: String)) -> Int {
        
        // Create new Location
        let newLocation = WeatherData()
        newLocation.locationName = placeDetails.description
        newLocation.placeID = placeDetails.placeID
        
        // Create a display name by extracting the locality from the full description
        let splitName = split(placeDetails.description) {$0 == ","}
        let locality = splitName[0]
        newLocation.displayName = locality
        
        if (placeDetails.placeID == "local" && !weatherLocations.isEmpty) {
            weatherLocations[0] = newLocation
        } else {
            weatherLocations.append(newLocation)
        }
        
        saveLocations()
        // return the index the new location was inserted into
        return find(weatherLocations, newLocation)!
        
    }
    
    func updateLocation(index: Int, updatedLocation: WeatherData) {
        weatherLocations[index] = updatedLocation
        NSNotificationCenter.defaultCenter().postNotificationName("locationsListUpdated", object: nil)
        saveLocations()
    }
    
    
    
    func deleteLocation(index: Int) {
        weatherLocations.removeAtIndex(index)
        saveLocations()
    }
    
    func moveLocation(fromIndex: Int, toIndex: Int) {
        let movingLocation = weatherLocations.removeAtIndex(fromIndex)
        weatherLocations.insert(movingLocation, atIndex: toIndex)
    }
    
    func saveLocations() {
        let data = NSKeyedArchiver.archivedDataWithRootObject(weatherLocations)
        defaults.setObject(data, forKey: Constants.weatherLocations)
    }
}

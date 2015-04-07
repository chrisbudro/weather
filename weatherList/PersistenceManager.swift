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
    
    private var weatherLocations : [WeatherData] = []
    let defaults = NSUserDefaults.standardUserDefaults()
    

    
    override init() {
        super.init()
        if let data = defaults.objectForKey(Constants.weatherLocations) as? NSData {
            let decodedWeatherLocations = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [WeatherData]?
            if let decodedLocations = decodedWeatherLocations {
                weatherLocations = decodedLocations
            }
        } else {
            // if location services is enabled, get current location and create it
            // if disabled create a placeholder location Asheville, NC and get weather data for it
        }
    }
    
    
    func getLocations() -> [WeatherData] {
        return weatherLocations
    }
    
    func addLocation(placeDetails: (description: String, placeID: String)) {
        
        // geocode location coordinates using google API and placeID
        // send coordinates to weather Requester to populate WeatherData instance
        // create instance of WeatherData using description, short name, placeID and the weatherconditions from the Weather Requester
        // save the location to the weatherMoments array
    }
    
    func deleteLocation(index: Int) {
        weatherLocations.removeAtIndex(index)
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

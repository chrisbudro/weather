//
//  WeatherAPI.swift
//  weatherList
//
//  Created by Mac Pro on 4/6/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit

class WeatherAPI: NSObject {
    
    private let persistenceManager = PersistenceManager()
    private let weatherRequester = WeatherRequester()
   
    static let sharedInstance = WeatherAPI()
    
    
    func getLocations() -> [WeatherData] {
        return persistenceManager.getLocations()
    }
    
    func addLocation(placeDetails: (description: String, placeID: String)) {
        persistenceManager.addLocation(placeDetails)
        // request Weather Forecast from here
    }
    
    func deleteLocation(index: Int) {
        persistenceManager.deleteLocation(index)
    }
    
    func moveLocation(fromIndex: Int, toIndex: Int) {
        persistenceManager.moveLocation(fromIndex, toIndex: toIndex)
    }
    
    func saveLocations() {
        persistenceManager.saveLocations()
    }
    
    func getAutoCompleteResults() {
        // send search keywords to google place API
        // return info to populate search results
    }
    
    
}

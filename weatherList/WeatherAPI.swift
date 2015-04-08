//
//  WeatherAPI.swift
//  weatherList
//
//  Created by Mac Pro on 4/6/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import CoreLocation

class WeatherAPI: NSObject {
    
    private struct Constants {
        static let minimumTimeSinceLastUpdate = 7200
        static let localID = "local"
        static let desiredAccuracy : CLLocationAccuracy = 1000
        static let minimumDistanceMoved : Double = 3000
    }
    
    let locationManager = CLLocationManager()
    var locationServicesEnabled = true
    private let persistenceManager = PersistenceManager()
    private let weatherRequest = WeatherRequester()
    private let placesRequest = PlacesRequester()
    private var weatherLocations : [WeatherData] {
        return persistenceManager.getLocations()
    }
   
    static let sharedInstance = WeatherAPI()
    
    
    func getLocations() -> [WeatherData] {
        return weatherLocations
    }
    
    func refreshWeather(index: Int, forceUpdate: Bool) {
        
        let location = self.weatherLocations[index]
        
        if let elapsedTime = getElapsedTimeInSeconds(location.unixTime) {
            if (elapsedTime > Constants.minimumTimeSinceLastUpdate || (elapsedTime > 600 && forceUpdate == true) ) {
                var local = (index == 0) ? true : false
                updateWeatherAtLocation(index, coordinates: location.coordinates!)
                println("updated weather")
            } else {
               // send message to stop activity indicator
                println("not updated")
            }
        } else {
            if location.placeID == Constants.localID {
                getCurrentLocation()
                
            } else {
                getPlaceCoordinates(location.placeID!, index: index)
            }
        }
    }
    
    
    func getLocalWeather(coreLocation: CLLocation) {
        
        // start activity indicator
        
        placesRequest.geoCodeCurrentLocation(coreLocation, completion: { (description, coordinates, error) -> Void in
            self.persistenceManager.createLocation((description: description, placeID: Constants.localID))
            self.updateWeatherAtLocation(0, coordinates: coordinates)
            println("coordinates at get local weather: \(coordinates)")
        })
    }
    
    func createLocation(placeDetails: (description: String, placeID: String)) {
        let locationIndex = persistenceManager.createLocation(placeDetails)
        
        //request coordinates from google geocode API
        getPlaceCoordinates(placeDetails.placeID, index: locationIndex)
    }
    
    private func getPlaceCoordinates(placeID: String, index: Int) {
        placesRequest.getPlaceCoordinates(placeID, completion: { (coordinates, error) -> Void in
            if error == nil{
                self.updateWeatherAtLocation(index, coordinates: coordinates)
            } else {
                println("get coordinates error: \(error)")
            }
        })

    }
    
    private func updateWeatherAtLocation(index: Int, coordinates: String) {

        self.weatherRequest.populateWeatherForLocation(coordinates, completion: { (weatherJSON, error) -> Void in
            if error == nil {
                // Update weather locations list with populated weather location
                let updatedLocation = self.weatherRequest.dataFromRequest(weatherJSON!, coordinates: coordinates, location: self.weatherLocations[index])
                self.persistenceManager.updateLocation(index, updatedLocation: updatedLocation)
                println("updated Location: \(updatedLocation) , \(updatedLocation.coordinates)")
            }
        })
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
        
    func getAutoCompleteResults(searchTerm: String, completion: (placeList: [(description: String, placeID: String)], error: NSError!) -> Void) {
        placesRequest.getAutoCompleteResults(searchTerm, completion: { (placeList, error) -> Void in
                completion(placeList: placeList, error: error)
        })
        
    }
    
    //MARK: Helper Methods
    
    private func getElapsedTimeInSeconds(unixTime: Int?) -> Int? {
        if let time = unixTime {
            let lastUpdateTimestamp = NSTimeInterval(time)
            let elapsedTime = NSDate().timeIntervalSince1970 - lastUpdateTimestamp
            return Int(elapsedTime)
        }
        return nil
    }
    
}

extension WeatherAPI: CLLocationManagerDelegate {
    
    func getCurrentLocation() {

        locationManager.delegate = self
        locationManager.desiredAccuracy = Constants.desiredAccuracy

        if CLLocationManager.locationServicesEnabled() {
            if (locationManager.respondsToSelector("requestWhenInUseAuthorization")) {
                    locationManager.requestWhenInUseAuthorization()
            } else {
                locationManager.startUpdatingLocation()
            }
        } else {
            locationServicesEnabled = false
        }
    
    }
    
 
    //MARK: Core Location Manager Delegate


    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {

        if (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
            manager.startUpdatingLocation()
            println("getting location")
            locationServicesEnabled = true
        } else {
            locationServicesEnabled = false
        }
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        manager.stopUpdatingLocation()
        let newLocation = locations.last as! CLLocation
        var distanceFromLast : Double?
        if let lastLocation = NSUserDefaults.standardUserDefaults().objectForKey("lastKnownLocation") as? NSData {

            let lastKnownLocation = NSKeyedUnarchiver.unarchiveObjectWithData(lastLocation) as! CLLocation
            println("last known: \(lastKnownLocation)")
            distanceFromLast = newLocation.distanceFromLocation(lastKnownLocation)  //Fix issue of showing as 0

            println("distance traveled: \(distanceFromLast)")
        }

        let locationData = NSKeyedArchiver.archivedDataWithRootObject(newLocation)
        NSUserDefaults.standardUserDefaults().setObject(locationData, forKey: "lastKnownLocation")

        println("distance from last: \(distanceFromLast)")

        if (distanceFromLast == nil || distanceFromLast > Constants.minimumDistanceMoved) {
            getLocalWeather(newLocation)

        }
    }
}

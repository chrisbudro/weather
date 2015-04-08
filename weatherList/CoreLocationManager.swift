//
//  CoreLocationManager.swift
//  weatherList
//
//  Created by Mac Pro on 4/7/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import CoreLocation

//class CoreLocationManager: NSObject, CLLocationManagerDelegate {
//    
//    private struct Constants {
//        static let desiredAccuracy : CLLocationAccuracy = 1000
//        static let minimumDistanceMoved : Double = 3000
//        
//    }
//    
//    let locationManager = CLLocationManager()
//    let weatherAPI = WeatherAPI.sharedInstance
//    
//    func getCurrentLocation() {
//    
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = Constants.desiredAccuracy
//        
//        if CLLocationManager.locationServicesEnabled() {
//            if (locationManager.respondsToSelector("requestWhenInUseAuthorization")) {
//                if (CLLocationManager.authorizationStatus() == .NotDetermined) {
//                    locationManager.requestWhenInUseAuthorization()
//                }
//            } else {
//                locationManager.startUpdatingLocation()
//            }
//        } else {
//            WeatherAPI.sharedInstance.locationServicesEnabled = false
//        }
//    
//    }
//
//    //MARK: Core Location Manager Delegate
//    
//    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
//        
//        if (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
////            getLocation()
//            weatherAPI.locationServicesEnabled = true
//        } else {
//            weatherAPI.locationServicesEnabled = false
//        }
//    }
//    
//    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
//        manager.stopUpdatingLocation()
//        let newLocation = locations[0] as! CLLocation
//        var distanceFromLast : Double?
//        if let lastLocation = NSUserDefaults.standardUserDefaults().objectForKey("lastKnownLocation") as? NSData {
//            
//            let lastKnownLocation = NSKeyedUnarchiver.unarchiveObjectWithData(lastLocation) as! CLLocation
//            println("last known: \(lastKnownLocation)")
//            distanceFromLast = newLocation.distanceFromLocation(lastKnownLocation)  //Fix issue of showing as 0
//            
//            println("distance traveled: \(distanceFromLast)")
//        }
//        
//        let locationData = NSKeyedArchiver.archivedDataWithRootObject(newLocation)
//        NSUserDefaults.standardUserDefaults().setObject(locationData, forKey: "lastKnownLocation")
//        
//        println("distance from last: \(distanceFromLast)")
//        
//        if (distanceFromLast == nil || distanceFromLast > Constants.minimumDistanceMoved) {
//            weatherAPI.getLocalWeather(newLocation)
//            
//        } 
//    }
//}

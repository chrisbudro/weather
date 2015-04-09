//
//  GooglePlacesRequester.swift
//  weatherList
//
//  Created by Chris Budro on 4/6/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import CoreLocation


class PlacesRequester: NSObject {
   
    private var apiKey : String?
    private let baseURL = "https://maps.googleapis.com/maps/api/place/"
    
    override init() {
        let pathToFile = NSBundle.mainBundle().pathForResource("APIKeys", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: pathToFile!)
        if let key = keys!["places"] as? String {
            self.apiKey = key
        }
        super.init()
    }
    
    
    func getAutoCompleteResults(locationString: String, completion: (placeList: [(description: String, placeID: String)], error: NSError!) -> Void ) {
        if (locationString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 && apiKey != nil) {
            
            let placeType = "(cities)"
            let strippedLocationString = locationString.stringByReplacingOccurrencesOfString(" ", withString: "", options: nil, range: nil)
            
            let placesRequestURL = NSURL(string: baseURL + "autocomplete/json?input=\(strippedLocationString)&types=\(placeType)&key=\(apiKey!)")
            let sharedSession = NSURLSession.sharedSession()
            let downloadTask : NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(placesRequestURL!, completionHandler: { (places : NSURL!, response: NSURLResponse!, error: NSError!) -> Void in
                if (error == nil) {
                    var placeList : [(description: String, placeID: String)] = []
                    
                    if let
                        data = NSData(contentsOfURL: places, options: nil, error: nil),
                        placesJSON = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary,
                        predictions = placesJSON["predictions"] as? NSArray
                    {
                        
                        for prediction in predictions {
                            if let
                                predictionDescription = prediction["description"] as? String,
                                predictionPlaceID = prediction["place_id"] as? String
                            {
                            let predictionDetails : (description: String, placeID: String) = (predictionDescription, predictionPlaceID)
                            placeList.append(predictionDetails)
                            }
                        }
                    }
                    completion(placeList: placeList, error: nil)
                    
                } else {
                    completion(placeList: [], error: error)
                }
            })
            downloadTask.resume()
        }
    }
    
    
    func getPlaceCoordinates(placeID: String, completion: (coordinates: String, error: NSError!) -> Void) {

        let placeRequestURL = NSURL(string: baseURL + "details/json?placeid=\(placeID)&key=\(apiKey!)")
        let downloadTask : NSURLSessionDownloadTask = NSURLSession.sharedSession().downloadTaskWithURL(placeRequestURL!, completionHandler: { (placeData : NSURL!, response: NSURLResponse!, error: NSError!) -> Void in
            if (error == nil) {
                
                if let
                    data = NSData(contentsOfURL: placeData, options: nil, error: nil),
                    placeJSON = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary,
                    placeResult = placeJSON["result"] as? NSDictionary,
                    placeGeometry = placeResult["geometry"] as? NSDictionary,
                    placeCoordinate = placeGeometry["location"] as? NSDictionary,
                    latitude = placeCoordinate["lat"] as? Double,
                    longitude = placeCoordinate["lng"] as? Double
                {
                let coordinates = "\(latitude),\(longitude)"
                completion(coordinates: coordinates, error: nil)
                }
                
            } else {
                completion(coordinates: "", error: error)
            }
        })
        downloadTask.resume()
    }
    
    func geoCodeCurrentLocation(coreLocation: CLLocation, completion: (description: String, coordinates: String, error: NSError!) -> Void) {
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(coreLocation, completionHandler: {(placemarks, error) -> Void in
            if error == nil {
                let placemark = placemarks[0] as! CLPlacemark
                let placeDescription = "\(placemark.locality), \(placemark.administrativeArea)"
                let coordinates = "\(placemark.location.coordinate.latitude),\(placemark.location.coordinate.longitude)"
                
                completion(description: placeDescription, coordinates: coordinates, error: nil)
            } else {
                completion(description: "", coordinates: "", error: error)
            }
        })
        
        
        
    }
}

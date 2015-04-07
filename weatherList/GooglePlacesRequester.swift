//
//  GooglePlacesRequester.swift
//  weatherList
//
//  Created by Mac Pro on 4/6/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit

class GooglePlacesRequester: NSObject {
   
    
    
    
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
    
    func geocodePlaceID(placeID: Int) {
        
        
    }
    
    
    func requestPlaceCoordinates(placeID: String, completion: (coordinates: String) -> Void) {
        let apiKey = "AIzaSyAyeGkrgfIa2Ov7Kb8Hzr2pHOYNMPytlWc"
        let placeRequestURL = NSURL(string: "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(placeID)&key=\(apiKey)")
        
        
        
        let downloadTask : NSURLSessionDownloadTask = NSURLSession.sharedSession().downloadTaskWithURL(placeRequestURL!, completionHandler: { (placeData : NSURL!, response: NSURLResponse!, error: NSError!) -> Void in
            if (error == nil) {
                let data = NSData(contentsOfURL: placeData, options: nil, error: nil)
                let placeJSON = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary
                println("JSON: \(placeJSON)")
                
                let placeResult = placeJSON["result"] as! NSDictionary
                let placeGeometry = placeResult["geometry"] as! NSDictionary
                let placeCoordinate = placeGeometry["location"] as! NSDictionary
                let latitude = placeCoordinate["lat"] as? Double
                let longitude = placeCoordinate["lng"] as? Double
                let coordinates = "\(latitude!),\(longitude!)"
                
                completion(coordinates: coordinates)
            } else {
                println("error: \(error)")
            }
        })
        downloadTask.resume()
        
        
    }
    
}

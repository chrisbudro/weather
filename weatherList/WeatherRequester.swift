//
//  WeatherRequester.swift
//  weatherList
//
//  Created by Mac Pro on 4/2/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit
import CoreLocation

class WeatherRequester: NSObject {
    
    private let apiKey : String
    private let baseURL: NSURL


    
    override init() {
        let pathToFile = NSBundle.mainBundle().pathForResource("APIKeys", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: pathToFile!)
        self.apiKey = keys!["forecast"] as! String
        self.baseURL = NSURL(string: "https://api.forecast.io/forecast/\(self.apiKey)/")!
        super.init()
    }
    
    
    func populateWeatherForLocation(coordinates: String, completion: (weatherJSON: NSDictionary?, error: NSError! ) -> Void ) {
        
        println("request sent")
        
        let forecastURL = NSURL(string: coordinates, relativeToURL:baseURL)
        let sharedSession = NSURLSession.sharedSession()
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastURL!, completionHandler: { (location: NSURL!, response:NSURLResponse!, error: NSError!) -> Void in
        
            if error == nil {
                let data = NSData(contentsOfURL: location, options: nil, error: nil)
                let weatherJSON : NSDictionary = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary
                println("JSON:")
                completion(weatherJSON: weatherJSON, error: nil)
                

            } else {
                completion(weatherJSON: nil, error: error)
                println("weather request error: \(error)")
            }
        })
        downloadTask.resume()
    }
        
    func dataFromRequest(weatherJSON: NSDictionary, coordinates: String, location: WeatherData) -> WeatherData {
        
        let currentWeather = weatherJSON["currently"] as! NSDictionary
        let data = WeatherData()
        
//        let fTemp = currentWeather["apparentTemperature"] as Double
//        let cTemp = Int((fTemp - 32) / 1.8)  // Conversion to Celcius
//        location.temperature = (Int(fTemp), cTemp) as (Int, Int)
//        location.wind = (windSpeed, windSpeedKPH)  as (Double, Double)
//        let windSpeed = currentWeather["windSpeed"] as Double
//        let windSpeedKPH = windSpeed * 1.609344
        
        let iconString = currentWeather["icon"] as! String
        
        
        location.coordinates = coordinates
        location.temperature = currentWeather["apparentTemperature"] as? Int
        location.humidity = currentWeather["humidity"] as? Double
        if let precip = currentWeather["precipProbability"] as? Double {
            let precipPercent = precip * 100
            location.precip = Int(precipPercent)
        }
        
        location.summary = currentWeather["summary"] as? String

        if let wind = currentWeather["windSpeed"] as? Double {
            let windAsInteger = Int(round(wind))
            location.wind = windAsInteger
        }
        
        location.unixTime = currentWeather["time"] as? Int
        location.imageString = currentWeather["icon"] as? String

        
        // Daily Weather
        
        let dailyWeather = weatherJSON["daily"] as! NSDictionary
        
        let weatherDetails = dailyWeather["data"] as! NSArray
        let todayDetails = weatherDetails[1] as! NSDictionary
        
        let minTemp = todayDetails["apparentTemperatureMin"] as? Double
        location.currentDayLowTemp = Int(minTemp!)
        
        let maxTemp = todayDetails["apparentTemperatureMax"] as? Double
        location.currentDayHighTemp = Int(maxTemp!)
        
        return location
    }
    

    
    func dateStringFromUnixTime(unixTime: Int) -> String {
        let timeInSeconds = NSTimeInterval(unixTime)
        let weatherDate = NSDate(timeIntervalSince1970: timeInSeconds)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .ShortStyle
        let dateString = dateFormatter.stringFromDate(weatherDate) as String
        return dateString
        
    }
    
    
    
}

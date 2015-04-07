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
    
    static let sharedRequester = WeatherRequester()
    
    private let apiKey : String
    private let baseURL: NSURL


    
    override init() {
        let pathToFile = NSBundle.mainBundle().pathForResource("APIKey", ofType: "")
        let file = NSString(contentsOfFile: pathToFile!, encoding: NSUTF8StringEncoding, error: nil)
        self.apiKey = file!.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
        self.baseURL = NSURL(string: "https://api.forecast.io/forecast/\(self.apiKey)/")!
    }
   
    func getWeatherData(placeDetails: (description: String, placeID: String), coordinates: String, isLocal: Bool, completion: (weatherData : WeatherData?, placeID: String, error: NSError!) -> Void) {

    
        let forecastURL = NSURL(string: coordinates, relativeToURL:baseURL)
        let sharedSession = NSURLSession.sharedSession()
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastURL!, completionHandler: { (location: NSURL!, response:NSURLResponse!, error: NSError!) -> Void in
            
            if error == nil {
                let data = NSData(contentsOfURL: location, options: nil, error: nil)
                let weatherJSON : NSDictionary = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary
                
                let weatherData = self.dataFromRequest(placeDetails.description, weatherJSON: weatherJSON) as WeatherData
                completion(weatherData: weatherData, placeID: placeDetails.placeID, error: nil)
                

            } else {
                completion(weatherData: nil, placeID: "", error: error)
                println(error)
            }
        })
        downloadTask.resume()
    }
    
    
    func dataFromRequest(placeDescription: String, weatherJSON: NSDictionary) -> WeatherData {
        
        let currentWeather = weatherJSON["currently"] as! NSDictionary
        let data = WeatherData()
        
//        let fTemp = currentWeather["apparentTemperature"] as Double
//        let cTemp = Int((fTemp - 32) / 1.8)  // Conversion to Celcius
//        data.temperature = (Int(fTemp), cTemp) as (Int, Int)
//        data.wind = (windSpeed, windSpeedKPH)  as (Double, Double)
//        let windSpeed = currentWeather["windSpeed"] as Double
//        let windSpeedKPH = windSpeed * 1.609344
        
        let iconString = currentWeather["icon"] as! String
        
        
        
        data.locationName = placeDescription
        data.temperature = currentWeather["apparentTemperature"] as? Int
        data.humidity = currentWeather["humidity"] as? Double
        if let precip = currentWeather["precipProbability"] as? Double {
            let precipPercent = precip * 100
            data.precip = Int(precipPercent)
        }
        
        data.summary = currentWeather["summary"] as? String

        if let wind = currentWeather["windSpeed"] as? Double {
            let windAsInteger = Int(round(wind))
            data.wind = windAsInteger
        }
        
        data.unixTime = currentWeather["time"] as? Int
        data.imageString = currentWeather["icon"] as? String
        data.image = weatherImageFromString(iconString)
        println("icon: \(data.image)")
        
    
        // Daily Weather
        
        let dailyWeather = weatherJSON["daily"] as! NSDictionary
        
        let weatherDetails = dailyWeather["data"] as! NSArray
        let todayDetails = weatherDetails[1] as! NSDictionary
        
        let minTemp = todayDetails["apparentTemperatureMin"] as? Double
        data.currentDayLowTemp = Int(minTemp!)
        
        let maxTemp = todayDetails["apparentTemperatureMax"] as? Double
        data.currentDayHighTemp = Int(maxTemp!)
        
        return data
    }
    
    
    
    
    
    
    
    
    
    
    func weatherImageFromString(stringIcon: String) -> UIImage {
        var imageName: String
        
        switch stringIcon {
        case "clear-day":
            imageName = "clear-day"
        case "clear-night":
            imageName = "clear-night"
        case "rain":
            imageName = "raindrop"
        case "snow":
            imageName = "snowflake"
        case "sleet":
            imageName = "sleet"
        case "wind":
            imageName = "wind"
        case "fog":
            imageName = "cloudIcon"
        case "cloudy":
            imageName = "cloudIcon"
        case "partly-cloudy-day":
            imageName = "cloudIcon"
        case "partly-cloudy-night":
            imageName = "cloudIcon"
        default:
            imageName = "defaultIcon"
            
        }
        println("image: \(imageName)")
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
    
    
    
}

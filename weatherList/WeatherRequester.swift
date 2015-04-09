//
//  WeatherRequester.swift
//  weatherList
//
//  Created by Chris Budro on 4/2/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//


import CoreLocation

class WeatherRequester: NSObject {
    
    private var apiKey : String?
    private var baseURL: NSURL?


    override init() {
        if let
            pathToFile = NSBundle.mainBundle().pathForResource("APIKeys", ofType: "plist"),
            keys = NSDictionary(contentsOfFile: pathToFile),
            key = keys["forecast"] as? String
        {
            self.apiKey = key
            self.baseURL = NSURL(string: "https://api.forecast.io/forecast/\(self.apiKey!)/")!
        } else {
            println("There was a problem accessing the forecast.io api key from APIKeys.plist.  You will not be able to get weather data without it.  Make sure to implement this file per the README")
        }
        super.init()
    }
    
    
    func populateWeatherForLocation(coordinates: String, completion: (weatherJSON: NSDictionary?, error: NSError! ) -> Void ) {
        
        if let forecastURL = NSURL(string: coordinates, relativeToURL:baseURL) {
            let sharedSession = NSURLSession.sharedSession()
            let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastURL, completionHandler: { (location: NSURL!, response:NSURLResponse!, error: NSError!) -> Void in
            
                if error == nil {
                    if let
                        data = NSData(contentsOfURL: location, options: nil, error: nil),
                        weatherJSON : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary
                    {
                    completion(weatherJSON: weatherJSON, error: nil)
                    }

                } else {
                    completion(weatherJSON: nil, error: error)
                    println("weather request error: \(error)")
                }
            })
            downloadTask.resume()
        }
    }
        
    func dataFromRequest(weatherJSON: NSDictionary, coordinates: String, location: WeatherData) -> WeatherData {
        
        if let currentWeather = weatherJSON["currently"] as? NSDictionary {

            location.coordinates = coordinates
            location.temperature = currentWeather["apparentTemperature"] as? Int
            location.humidity = currentWeather["humidity"] as? Double
            location.summary = currentWeather["summary"] as? String
            location.unixTime = currentWeather["time"] as? Int
            location.imageString = currentWeather["icon"] as? String
            
            if let wind = currentWeather["windSpeed"] as? Double {
                let windAsInteger = Int(round(wind))
                location.wind = windAsInteger
            }

            if let precip = currentWeather["precipProbability"] as? Double {
                let precipPercent = precip * 100
                location.precip = Int(precipPercent)
            }
            
            // Daily Weather
            
            if let
                dailyWeather = weatherJSON["daily"] as? NSDictionary,
                weatherDetails = dailyWeather["data"] as? NSArray,
                todayDetails = weatherDetails[1] as? NSDictionary,
                minTemp = todayDetails["apparentTemperatureMin"] as? Double,
                maxTemp = todayDetails["apparentTemperatureMax"] as? Double
            {
                location.currentDayHighTemp = Int(maxTemp)
                location.currentDayLowTemp = Int(minTemp)
            }
        }
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

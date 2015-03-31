//
//  Current.swift
//  Stormy
//
//  Created by Mac Pro on 3/24/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import Foundation
import UIKit

struct Weather {
    var locationName = ""
    var currentTime: String?
    var temperature: Int
    var humidity: Double
    var precipProbability: Double
    var summary: String
    var icon: UIImage?
    
    
    init(weatherDict: NSDictionary) {
        let currentWeather = weatherDict["currently"] as NSDictionary
        
        temperature = currentWeather["apparentTemperature"] as Int
        humidity = currentWeather["humidity"] as Double
        precipProbability = currentWeather["precipProbability"] as Double
        summary = currentWeather["summary"] as String
        
        let currentTimeIntValue = currentWeather["time"] as Int
        currentTime = self.dateStringFromUnixTime(currentTimeIntValue) as String
        
        let iconString = currentWeather["icon"] as String
        icon = weatherIconFromString(iconString)
        
        
    }
    
    
    func dateStringFromUnixTime(unixTime: Int) -> String {
        let timeInSeconds = NSTimeInterval(unixTime)
        let weatherDate = NSDate(timeIntervalSince1970: timeInSeconds)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .ShortStyle
        let dateString = dateFormatter.stringFromDate(weatherDate) as String
        return dateString
        
    }
    
    func weatherIconFromString(stringIcon: String) -> UIImage {
        var imageName: String
        
        switch stringIcon {
            case "clear-day":
                imageName = "clear-day"
            case "clear-night":
                imageName = "clear-night"
            case "rain":
                imageName = "rain"
            case "snow":
                imageName = "snow"
            case "sleet":
                imageName = "sleet"
            case "wind":
                imageName = "wind"
            case "fog":
                imageName = "fog"
            case "cloudy":
                imageName = "cloudy"
            case "partly-cloudy-day":
                imageName = "partly-cloudy"
            case "partly-cloudy-night":
                imageName = "cloudy-night"
            default:
                imageName = "default"
            
            }
        var iconImage = UIImage(named: imageName)
        return iconImage!
        
        
    }
    
}
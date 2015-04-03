//
//  Current.swift
//  Stormy
//
//  Created by Mac Pro on 3/24/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation


struct Weather {
    let placemark : CLPlacemark
    var locationName = ""
    var unixTime: Int?
    var temperature: (f:Int, c:Int)
    var humidity: Double
    var precipProbability: Double
    var wind: (mph:Double, kph:Double)
    var summary: String
    var image: UIImage?
    
    
    init(placemark: CLPlacemark, weatherJSON: NSDictionary) {
        self.placemark = placemark
        let locationName = "\(placemark.locality), \(placemark.administrativeArea)"
        let currentWeather = weatherJSON["currently"] as NSDictionary
        let fTemp = currentWeather["apparentTemperature"] as Double
        let cTemp = Int((fTemp - 32) / 1.8)  // Conversion to Celcius
        temperature = (Int(fTemp), cTemp) as (Int, Int)
        humidity = currentWeather["humidity"] as Double
        precipProbability = currentWeather["precipProbability"] as Double
        summary = currentWeather["summary"] as String
        let windSpeed = currentWeather["windSpeed"] as Double
        let windSpeedKPH = windSpeed * 1.609344
        wind = (windSpeed, windSpeedKPH)  as (Double, Double)
        let unixTime = currentWeather["time"] as Int
        let iconString = currentWeather["icon"] as String
        image = weatherImageFromString(iconString)
        
    }
   
    
    func dateStringFromUnixTime(unixTime: Int) -> String {
        let timeInSeconds = NSTimeInterval(unixTime)
        let weatherDate = NSDate(timeIntervalSince1970: timeInSeconds)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .ShortStyle
        let dateString = dateFormatter.stringFromDate(weatherDate) as String
        return dateString
        
    }
    
    func weatherImageFromString(stringIcon: String) -> UIImage {
        var imageName: String
        
        switch stringIcon {
            case "clear-day":
                imageName = "clear"
            case "clear-night":
                imageName = "clear"
            case "rain":
                imageName = "rain"
            case "snow":
                imageName = "snow"
            case "sleet":
                imageName = "snow"
            case "wind":
                imageName = "cloudy"
            case "fog":
                imageName = "cloudy"
            case "cloudy":
                imageName = "cloudy"
            case "partly-cloudy-day":
                imageName = "partly-cloudy"
            case "partly-cloudy-night":
                imageName = "cloudy"
            default:
                imageName = "default"
            
            }
        var iconImage = UIImage(named: imageName)
        return iconImage!
        
        
    }
    
}
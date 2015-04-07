//
//  WeatherData.swift
//  weatherList
//
//  Created by Mac Pro on 4/2/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit
import CoreLocation


class WeatherData: NSObject, NSCoding {
    
    
        var coordinates : String?
        var locationName : String?
        var displayName : String?
        var unixTime: Int?
        var temperature: Int?
        var humidity: Double?
        var precip: Int?
        var wind: Int?
        var summary: String?
        var image: UIImage?
        var imageString : String?
        var currentDayHighTemp : Int?
        var currentDayLowTemp : Int?
    
    override init(){
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        self.coordinates = aDecoder.decodeObjectForKey("coordinates") as? String
        self.locationName = aDecoder.decodeObjectForKey("locationName") as? String
        self.unixTime = aDecoder.decodeIntegerForKey("unixTime")
        self.temperature = aDecoder.decodeObjectForKey("temperature") as? Int
        self.humidity = aDecoder.decodeDoubleForKey("humidity")
        self.precip = aDecoder.decodeObjectForKey("precip") as? Int
        self.wind = aDecoder.decodeObjectForKey("wind") as? Int
        self.summary = aDecoder.decodeObjectForKey("summary") as? String
        self.image = aDecoder.decodeObjectForKey("image") as? UIImage
        self.imageString = aDecoder.decodeObjectForKey("imageString") as? String
        self.currentDayLowTemp = aDecoder.decodeObjectForKey("currentDayLowTemp") as? Int
        self.currentDayHighTemp = aDecoder.decodeObjectForKey("currentDayHighTemp") as? Int
    }
    
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(coordinates, forKey: "coordinates")
        aCoder.encodeObject(locationName, forKey: "locationName")
        aCoder.encodeInteger(unixTime!, forKey: "unixTime")
        aCoder.encodeObject(temperature, forKey: "temperature")
        aCoder.encodeDouble(humidity!, forKey: "humidity")
        aCoder.encodeObject(precip!, forKey: "precip")
        aCoder.encodeObject(wind, forKey: "wind")
        aCoder.encodeObject(summary, forKey: "summary")
        aCoder.encodeObject(image, forKey: "image")
        aCoder.encodeObject(imageString, forKey: "imageString")
        aCoder.encodeObject(currentDayLowTemp, forKey: "currentDayLowTemp")
        aCoder.encodeObject(currentDayHighTemp, forKey: "currentDayHighTemp")
    }
}

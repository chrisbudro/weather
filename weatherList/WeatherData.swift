//
//  WeatherData.swift
//  weatherList
//
//  Created by Mac Pro on 4/2/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import CoreLocation


class WeatherData: NSObject, NSCoding {
    
        var placemark : CLPlacemark?
        var locationName : String?
        var unixTime: Int?
        var temperature: Int?
        var humidity: Double?
        var precip: Double?
        var wind: Double?
        var summary: String?
        var image: UIImage?
        var imageString : String?
    
    override init(){
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        self.placemark = aDecoder.decodeObjectForKey("placemark") as? CLPlacemark
        self.locationName = aDecoder.decodeObjectForKey("locationName") as? String
        self.unixTime = aDecoder.decodeIntegerForKey("unixTime")
        self.temperature = aDecoder.decodeObjectForKey("temperature") as? Int
        self.humidity = aDecoder.decodeDoubleForKey("humidity")
        self.precip = aDecoder.decodeDoubleForKey("precip")
        self.wind = aDecoder.decodeObjectForKey("wind") as? Double
        self.summary = aDecoder.decodeObjectForKey("summary") as? String
        self.image = aDecoder.decodeObjectForKey("image") as? UIImage
        self.imageString = aDecoder.decodeObjectForKey("imageString") as? String
    }
    
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(placemark, forKey: "placemark")
        aCoder.encodeObject(locationName, forKey: "locationName")
        aCoder.encodeInteger(unixTime!, forKey: "unixTime")
        aCoder.encodeObject(temperature, forKey: "temperature")
        aCoder.encodeDouble(humidity!, forKey: "humidity")
        aCoder.encodeDouble(precip!, forKey: "precip")
        aCoder.encodeObject(wind, forKey: "wind")
        aCoder.encodeObject(summary, forKey: "summary")
        aCoder.encodeObject(image, forKey: "image")
        aCoder.encodeObject(imageString, forKey: "imageString")
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

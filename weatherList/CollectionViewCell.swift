//
//  CollectionViewCell.swift
//  weatherCollection
//
//  Created by Mac Pro on 3/29/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit



@IBDesignable class CollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    
    
    var label : UILabel! {
        let labelMake = UILabel(frame: CGRectMake(10, 10, 300, 24))
        labelMake.textColor = UIColor.whiteColor()
        labelMake.backgroundColor = UIColor.clearColor()
        
        return labelMake
    }
    
    override init() {
        super.init()
        self.addSubview(label)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
}


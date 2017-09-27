//
//  iconView.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 9/19/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit

class iconView: UIView {

    
//     Only override draw() if you perform custom drawing.
//     An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
         self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
    }
 

}

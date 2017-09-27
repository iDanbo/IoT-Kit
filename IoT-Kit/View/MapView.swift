//
//  MapView.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 9/20/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit
import MapKit

class MapView: MKMapView {
    private var compassTopValue: CGFloat = 15
    private var compassLeftValue: CGFloat = 15

    override func layoutSubviews() {
        super.layoutSubviews()
        // set compass position by setting its frame
        if let compassView = self.subviews.filter({ $0.isKind(of: NSClassFromString("MKCompassView")!) }).first {
            compassView.frame = CGRect(x: compassLeftValue, y: compassTopValue, width: 36, height: 36)
        }
    }

}

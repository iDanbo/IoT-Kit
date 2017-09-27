//
//  Utilities.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 8/22/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit
import MapKit

// Method to displat allert
extension UIViewController {
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            alert.dismiss(animated: true, completion: nil)
            
        })
        self.present(alert, animated: true, completion: nil)
    }
}

extension MKMapView {
    func zoomToUserLocation() {
        guard let coordinate = userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 100, 100)
        setRegion(region, animated: true)
    }
}

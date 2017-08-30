//
//  DevicesLocations.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 7/24/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import Foundation
import MapKit
import IoTTicketSwiftAPI

class DeviceWithLocation: Device, MKAnnotation {
    
    private var idleCounter: Int = 0
    private let activeLocation = UIImage(named: "deviceLocation")!
    private let notActiveLocation = UIImage(named: "deviceLocationNotActive")!
    
    var observation: NSKeyValueObservation?
    
    // Every device has a timer as to when to update their coordinates
    weak var timer: Timer?
    
    var pinImage: UIImage {
        if (isActive) {
            return activeLocation
        } else {
            return notActiveLocation
        }
    }
    
    dynamic var coordinate = CLLocationCoordinate2D() {
        didSet {
            if coordinates.last != coordinate {
            coordinates.append(coordinate)
                if (!isActive) {
                    isActive = true
                }
                idleCounter = 0
            } else {
                idleCounter += 1
                if (idleCounter > 5 && isActive) {
                    isActive = false
                }
            }
        }
    }
    
    dynamic var title: String? {
        return name
    }
    
    dynamic var subtitle: String? {
        return manufacturer
    }

    var coordinates = [CLLocationCoordinate2D]()
    
    dynamic var isActive: Bool = false
    
    init(device: Device) {
        super.init(name: device.name, manufacturer: device.manufacturer, type: device.type, deviceDescription: device.deviceDescription, attributes: device.attributes)
        super.deviceId = device.deviceId
        super.createdAt = device.createdAt
        super.href = device.href
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @available(iOS 10.0, *)
    func mapItem() -> MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        
        return mapItem
    }
}



//class DevicesLocations {
//    
//    var locations = [Device:[CLLocationCoordinate2D]]()
//    var devices: [Device]?
//    var annotations = [Device:MyAnnotation]()
//    
//}

//extension DeviceWithLocation: MKAnnotation {
//    dynamic var coordinate: CLLocationCoordinate2D
//    dynamic var title: String? {
//        return name
//    }
// dynamic var subtitle: String? {
//        return manufacturer
//    }
//
    // annotation callout info button opens this mapItem in Maps app
//    @available(iOS 10.0, *)
//    func mapItem() -> MKMapItem {
//        let placemark = MKPlacemark(coordinate: coordinate)
//
//        let mapItem = MKMapItem(placemark: placemark)
//        mapItem.name = title
//
//        return mapItem
//    }
//
//}

class MyAnnotation: NSObject, MKAnnotation {
    
    dynamic var title: String?
    dynamic var subtitle: String?
    dynamic var coordinate: CLLocationCoordinate2D
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        super.init()
    }
    // annotation callout info button opens this mapItem in Maps app
    @available(iOS 10.0, *)
    func mapItem() -> MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        
        return mapItem
    }
}

enum Coordindate: String {
    case latitude = "latitude"
    case longitude = "longitude"
}

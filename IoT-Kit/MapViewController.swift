//
//  SecondViewController.swift
//  iOS Example
//
//  Created by Daniel Egerev on 5/26/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit
import IoTTicketSwiftAPI
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var iconView: UIView!
    
    var devicesWithLocation = [DeviceWithLocation]()
    let annotation = MKPointAnnotation()
    var myIoT: MyIoT!
    
    var updateCoordinatesTimerValueActive: TimeInterval = 1
    var updateCoordinatesTimerValueNotActive: TimeInterval = 5
    
    deinit {
        print("Deinitialized")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
//        iconView.layer.cornerRadius = 5
//        iconView.layer.masksToBounds = true
        checkForDatanodes()
    }
    
    func getAllDevices(completion: @escaping (([Device]) -> ())) {
        myIoT.client.getDevices(limit: 300) { (deviceList, error) in
            if let error = error {
                print(error)
            }
            if let deviceList = deviceList {
                var allDevices = [Device]()
                for device in deviceList.devices! {
                    allDevices.append(device)
                }
                completion(allDevices)
            }
        }
        
    }
    
    func checkForDatanodes(completed: (() -> ())? = nil) {
        getAllDevices { [weak self] devices in
            guard let strongSelf = self else { return }
            let time = Date().timeIntervalSinceReferenceDate
            let group = DispatchGroup()
            for device in devices {
                let deviceId = device.deviceId!
                group.enter()
                strongSelf.myIoT.client.getDatanodes(deviceId: deviceId, limit: 1000) { datanodeList, error in
                    if let error = error {
                        group.leave()
                        print(error)
                        return
                    }
                    if let datanodeList = datanodeList {
                        guard let datanodes = datanodeList.datanodes else {
                            print("No datanodes")
                            group.leave()
                            return
                        }
                        for datanode in datanodes where datanode.name.caseInsensitiveCompare("latitude") == .orderedSame || datanode.name.caseInsensitiveCompare("longitude") == .orderedSame {
                            // if first datanode name is longitude then.. it adds, but maybe there is no latitude datanode
                            if (datanode.name.caseInsensitiveCompare("latitude") == .orderedSame) {
                                continue
                            }
                            if (datanode.name.caseInsensitiveCompare("longitude") == .orderedSame) {
                                let deviceWithLocation = DeviceWithLocation(device: device)
                                // Append device that has location datanodes
                                strongSelf.devicesWithLocation.append(deviceWithLocation)
                                strongSelf.initializeAnnotaions(device: deviceWithLocation) {
                                    strongSelf.updateCoordinatesTimer(for: deviceWithLocation, timeInterval: strongSelf.updateCoordinatesTimerValueActive)
                                    deviceWithLocation.observation = deviceWithLocation.observe(\.isActive, changeHandler: { [weak self] (object, change) in
                                        //invalidate timer before setting a new one
                                        guard let strongSelf2 = self else { return }
                                        deviceWithLocation.timer?.invalidate()
                                        deviceWithLocation.timer = nil
                                        let annotationView = strongSelf2.mapView.view(for: deviceWithLocation)
                                        if (object.isActive) {
                                            print("active")
                                            annotationView?.image = deviceWithLocation.pinImage
                                            strongSelf2.updateCoordinatesTimer(for: deviceWithLocation, timeInterval: strongSelf2.updateCoordinatesTimerValueActive)
                                        } else {
                                            print("inactive")
                                            annotationView?.image = deviceWithLocation.pinImage
                                            strongSelf2.updateCoordinatesTimer(for: deviceWithLocation, timeInterval: strongSelf2.updateCoordinatesTimerValueNotActive)
                                        }
                                    })
                                }
                                break
                            }
                        }
                        print("DeivceId with location datanodes: ", deviceId)
                        group.leave()
                        
                    }
                }
            }
            group.notify(queue: .main) {
                let currentTime = Date().timeIntervalSinceReferenceDate
                print("completed")
                print("Elapsed \(currentTime-time)s")
                strongSelf.refreshButton.isEnabled = true
                completed?()
            }
            
            
        }
    }
    
    func initializeAnnotaions(device: DeviceWithLocation, completion: (()->())? = nil) {
        getDeviceCoordinates(device: device) { (coordinate) in
            DispatchQueue.main.async {
                device.coordinate = coordinate
                if device.deviceId != self.myIoT.deviceDetails.deviceId {
                    self.mapView.addAnnotation(device)
                    completion?()
                }
            }
        }
    }
    
//    func addPolyline(for device: DeviceWithLocation) {
//        let polyline = MKPolyline(coordinates: device.coordinates, count: device.coordinates.count)
//        DispatchQueue.main.async {
//            self.mapView.add(polyline, level: .aboveLabels)
//        }
//    }
    
    func updateCoordinates(for device: DeviceWithLocation) {
        getDeviceCoordinates(device: device) { (coordinate) in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseInOut], animations: {
                    device.coordinate = coordinate
                })
//                device.coordinate = coordinate
//                self.addPolyline(for: device)
            }
        }
    }
    
    
    func getDeviceCoordinates(device: DeviceWithLocation, completion: @escaping (CLLocationCoordinate2D) -> ()) {
        let deviceId = device.deviceId!
        var latitude = Double()
        var longitude = Double()
         self.myIoT.client.readDatanodes(deviceId: deviceId, criteria: ["latitude", "longitude"]) { [weak self] (datanodeRead, error) in
            guard let strongSelf = self else { return }
            if error != nil {
                print(error!)
                return
            }
            if let datanodeRead = datanodeRead {
                latitude = strongSelf.extractDatanodeValue(for: datanodeRead, name: Coordindate.latitude.rawValue)!
                longitude = strongSelf.extractDatanodeValue(for: datanodeRead, name: Coordindate.longitude.rawValue)!
                let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                completion(coordinate)
            }
        }
    }
    
    func extractDatanodeValue(for datanodes: [DatanodeRead], name datanodeName: String) -> Double? {
        for datanode in datanodes where (datanode.name.caseInsensitiveCompare(datanodeName) == .orderedSame) {
            guard let value = datanode.values?.first?.value else { return nil }
            return Double(value)
        }
        return nil
    }
    
    
    func updateCoordinatesTimer(for device: DeviceWithLocation, timeInterval: TimeInterval) {
        
        device.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: {[weak self] (timer) in
            self?.updateCoordinates(for: device)
        })
    }
    
    @IBAction func refreshButtonPressed(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        devicesWithLocation.forEach {$0.timer?.invalidate(); $0.timer = nil; $0.observation?.invalidate(); $0.observation = nil}
        mapView.removeAnnotations(mapView.annotations)
//        mapView.removeOverlays(mapView.overlays)
        devicesWithLocation.removeAll()
        checkForDatanodes { _ in
            sender.isEnabled = true
        }
        
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let location = view.annotation as! DeviceWithLocation
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        if #available(iOS 10.0, *) {
            location.mapItem().openInMaps(launchOptions: launchOptions)
        } else {
            return
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't want to show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = true
            if let deviceAnnotation = annotation as? DeviceWithLocation {
                annotationView.image = deviceAnnotation.pinImage
            }
        }
        
        return annotationView
    }
}


extension CLLocationCoordinate2D: Equatable {}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return (lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude)
}


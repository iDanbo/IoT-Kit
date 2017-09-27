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
    
    var observer: NSKeyValueObservation?
    
    @objc dynamic var devicesWithLocation = [DeviceWithLocation]()
    let annotation = MKPointAnnotation()
    var myIoT: MyIoT!
    var geotifications: [GeoPin] = []
    
    
    var updateCoordinatesTimerValueActive: TimeInterval = 1
    var updateCoordinatesTimerValueNotActive: TimeInterval = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        checkForDatanodes()
    }
    
    deinit {
        print("MapViewController deinit")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGeofence" {
            let navigationController = segue.destination as! UINavigationController
            let vc = navigationController.viewControllers.first as! AddGeofenceTableViewController
            vc.delegate = self
            vc.myIoT = myIoT
        }
        if segue.identifier == "toMapSettings" {
            let navigationController = segue.destination as! UINavigationController
            let vc = navigationController.viewControllers.first as! MapSettingsViewController
            vc.mvc = self
            vc.devicesWithLocation = devicesWithLocation
            vc.selectedSegment = Int(mapView.mapType.rawValue)
        }
    }
    
    func getAllDevices(completion: @escaping (([Device]) -> ())) {
        myIoT.client.getDevices(limit: 300) { (deviceList, error) in
            if let error = error {
                switch error {
                case IoTServerError.QuotaViolation: self.createAlert(title: "Can't send a request", message: "Exceeded max. quota limit")
                case IoTServerError.UncaughtException: self.createAlert(title: "Error", message: "Uncaught error")
                case IoTServerError.NoDataInResponse: self.createAlert(title: "No internet connection", message: "There is no data in response, please check your connection")
                default: self.createAlert(title: "Error", message: "Uknown error")
                }
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
                self?.devicesWithLocation.forEach{ print("Device Location Array:", $0.name)}
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
                // Check if the last coordinate is different
                if device.coordinates.last != coordinate {
                    UIView.animate(withDuration: 2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseInOut], animations: {
                        device.coordinate = coordinate
                    })
                } else {
                    device.idleCounter += 1
                    if (device.idleCounter > 5 && device.isActive) {
                        device.isActive = false
                    }
                }
            }
        }
    }
    
    
    func getDeviceCoordinates(device: DeviceWithLocation, completion: @escaping (CLLocationCoordinate2D) -> ()) {
        let deviceId = device.deviceId!
//        var latitude = Double()
//        var longitude = Double()
         self.myIoT.client.readDatanodes(deviceId: deviceId, criteria: ["latitude", "longitude"]) { [weak self] (datanodeRead, error) in
            guard let strongSelf = self else { return }
            if error != nil {
                print(error!)
                return
            }
            if let datanodes = datanodeRead?.datanodes {
                guard let latitude = strongSelf.extractDatanodeValue(for: datanodes, name: Coordindate.latitude.rawValue) else { print("No Latitude coordinate"); return}
                guard let longitude = strongSelf.extractDatanodeValue(for: datanodes, name: Coordindate.longitude.rawValue) else { print("No Longitude coordinate"); return}
                let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                completion(coordinate)
            }
        }
    }
    
    func extractDatanodeValue(for datanodes: [Datanodes], name datanodeName: String) -> Double? {
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
    
    func add(geotification: GeoPin) {
        geotifications.append(geotification)
        mapView.addAnnotation(geotification)
        addRadiusOverlay(forGeotification: geotification)
        updateGeotificationsCount()
    }
    func updateGeotificationsCount() {
        title = "Track Devices (\(geotifications.count))"
        navigationItem.rightBarButtonItem?.isEnabled = (geotifications.count < 20)
    }
    func addRadiusOverlay(forGeotification geotification: GeoPin) {
        mapView?.add(MKCircle(center: geotification.coordinate, radius: geotification.radius))
    }
    @IBAction func currentLocation(_ sender: UIButton) {
        guard let coordinate = mapView.userLocation.location?.coordinate else {
            createAlert(title: "Enable Location", message: "Open \"Your Device\" tab and enable location")
            return
        }
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 100, 100)
        mapView.setRegion(region, animated: true)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .purple
            circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
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
            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30)))
            let image = UIImage(named: "carIcon")
            button.setImage(image, for: .normal)
            annotationView?.rightCalloutAccessoryView = button
        }
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = true
            if let deviceAnnotation = annotationView.annotation as? DeviceWithLocation {
                annotationView.image = deviceAnnotation.pinImage
            }
            if let geoPinAnnotation = annotation as? GeoPin {
                annotationView.image = UIImage(named: "addPin")
            }
        }
        
        return annotationView
    }
    
    // Get directions to the device
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let location = view.annotation as? DeviceWithLocation else { return }
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        if #available(iOS 10.0, *) {
            location.mapItem().openInMaps(launchOptions: launchOptions)
        } else {
            return
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let deviceAnnotation = view.annotation as? DeviceWithLocation {
            mapView.setCenter(deviceAnnotation.coordinate, animated: true)
//            deviceAnnotation.coordinateObserver = deviceAnnotation.observe(\.coordinate) { object, change in
//            }
        }
    }
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let deviceAnnotation = view.annotation as? DeviceWithLocation {
            deviceAnnotation.coordinateObserver?.invalidate()
            deviceAnnotation.coordinateObserver = nil
        }
    }
}

extension MapViewController: AddGeotificationsViewControllerDelegate {
    func addGeotificationViewController(controller: AddGeofenceTableViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        controller.dismiss(animated: true, completion: nil)
        // 1
        let geotification = GeoPin(coordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: eventType)
        add(geotification: geotification)
        // 2
//        startMonitoring(geotification: geotification)
//        saveAllGeotifications()
    }
}

extension CLLocationCoordinate2D: Equatable {}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return (lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude)
}


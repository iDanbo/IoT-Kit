//
//  MapSettingsViewController.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 9/18/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit

class MapSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let devicesWithLocation = devicesWithLocation else { return 0 }
        return devicesWithLocation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let devicesWithLocation = devicesWithLocation else { return cell }
        let device = devicesWithLocation[indexPath.row]
        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = "\(device.coordinate.latitude), \(device.coordinate.longitude)"
        return cell
    }
    

    var mvc: MapViewController!
    var devicesWithLocation: [DeviceWithLocation]?
    var selectedSegment: Int!
    
    @IBOutlet weak var deviceTableView: UITableView!
    @IBOutlet weak var devicesWithLocationTextField: UITextView!
    @IBOutlet weak var mapTypeSegmentController: UISegmentedControl!
    
    deinit {
        print("MapSettings deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapTypeSegmentController.selectedSegmentIndex = selectedSegment
        mvc.observer = mvc.observe(\.devicesWithLocation, changeHandler: { [unowned self] (object, change) in
            self.devicesWithLocation = object.devicesWithLocation
            self.deviceTableView.reloadData()
            self.devicesWithLocation?.forEach { $0.coordinateObserver?.invalidate(); $0.coordinateObserver = nil }
            if let devicesWithLocation = self.devicesWithLocation {
                self.observeCoordinateChanges(devicesWithLocation: devicesWithLocation)
            }
        })
        if let devicesWithLocation = devicesWithLocation {
        observeCoordinateChanges(devicesWithLocation: devicesWithLocation)
        }
    }
    
    func observeCoordinateChanges(devicesWithLocation: [DeviceWithLocation]) {
        for device in devicesWithLocation {
            device.coordinateObserver = device.observe(\.coordinate, changeHandler: { [unowned self] (device, change) in
                self.deviceTableView.reloadData()
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        mvc.observer?.invalidate()
        mvc.observer = nil
        devicesWithLocation?.forEach { $0.coordinateObserver?.invalidate(); $0.coordinateObserver = nil }
    }

    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func mapTypeSegmentControllerAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mvc.mapView.mapType = .standard
        case 1:
            mvc.mapView.mapType = .satellite
        case 2:
            mvc.mapView.mapType = .hybrid
        case 3:
            mvc.mapView.mapType = .hybridFlyover
        default:
            break
        }
    }
}

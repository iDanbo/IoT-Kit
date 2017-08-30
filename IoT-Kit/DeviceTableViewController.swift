//
//  DeviceTableViewController.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 6/12/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit
import IoTTicketSwiftAPI
import CoreLocation
import CoreMotion

class DeviceTableViewController: UITableViewController {
    
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var deviceIdLabel: UILabel!
    @IBOutlet weak var devicesProgressBar: UIProgressView!
    @IBOutlet weak var dataProgressBar: UIProgressView!
    @IBOutlet weak var deviceQuotaLabel: UILabel!
    @IBOutlet weak var dataQuotaLabel: UILabel!
    
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var myIoT: MyIoT!
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = CLActivityType.other
        return manager
    }()
    
    deinit {
        print("DeviceTableViewController deinitialized")
    }
    
    private lazy var motionManager: CMMotionManager = {
        let manger = CMMotionManager()
        manger.deviceMotionUpdateInterval = 1.0
        return manger
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceName.text = myIoT.deviceDetails.name
        deviceIdLabel.text = myIoT.deviceDetails.deviceId
        updateQuotaInfomration()
        refreshControl?.addTarget(self, action: #selector(DeviceTableViewController.handleRefresh(_:)), for: .valueChanged)
        let nvc = tabBarController?.viewControllers![1] as! UINavigationController
        let svc = nvc.viewControllers.first as! MapViewController
        svc.myIoT = myIoT
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshControl?.superview?.sendSubview(toBack: refreshControl!)
    }
    
    @IBAction func gpsSwitch(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
            locationManager.allowsBackgroundLocationUpdates = false
        }
    }
    
    func sendBatteryInfo(_ notification: Notification? = nil) {
        var batteryLife: Float {
            return UIDevice.current.batteryLevel * 100
        }
        let batteryLevelDatanode = Datanode(name: "BatteryLevel", path: "Battery", v: batteryLife, unit: "%")
        myIoT.client.writeDatanode(deviceId: myIoT.deviceDetails.deviceId!, datanodes: [batteryLevelDatanode])
    }
    
    @IBAction func accelerometerSwitch(_ sender: UISwitch) {
        if sender.isOn {
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: OperationQueue.current!) { (deviceMotion, error) in
                let rotationY = Datanode(name: "rotation Y", path: "Rotation", v: deviceMotion?.attitude.roll)
                let rotationX = Datanode(name: "rotation X", path: "Rotation", v: deviceMotion?.attitude.pitch)
                let rotationZ = Datanode(name: "rotation Z", path: "Rotation", v: deviceMotion?.attitude.yaw)
                self.myIoT.client.writeDatanode(deviceId: self.myIoT.deviceDetails.deviceId!, datanodes: [rotationX, rotationY, rotationZ])
            }
        } else {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    @IBAction func logOutAction(_ sender: UIBarButtonItem) {
        if let bundle = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundle)
        }
        if let nvc = tabBarController?.viewControllers![1] as? UINavigationController {
            let svc = nvc.viewControllers.first as! MapViewController
            svc.devicesWithLocation.forEach{$0.timer?.invalidate(); $0.timer = nil; $0.observation?.invalidate(); $0.observation = nil}
        }
        if UIApplication.shared.keyWindow?.rootViewController == self.tabBarController {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let login = mainStoryboard.instantiateViewController(withIdentifier: "LoginController") as! LoginViewController
            login.myIoT = MyIoT()
            print("here")
            UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
            present(login, animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func batteryLevelSwitch(_ sender: UISwitch) {
        if sender.isOn {
            UIDevice.current.isBatteryMonitoringEnabled = true
            sendBatteryInfo()
            NotificationCenter.default.addObserver(self, selector: #selector(sendBatteryInfo(_:)), name: .UIDeviceBatteryLevelDidChange, object: nil)
        } else {
            UIDevice.current.isBatteryMonitoringEnabled = false
        }
    }
    
    private func updateQuotaInfomration( completed: (() -> ())? = nil) {
        myIoT.client.getAllQuota { [weak self] (quota, error) in
            if let quota = quota {
                let deviceRatio: Float
                let dataRatio: Float
                let deviceQuotaText: String
                let dataQuotaText: String
                if (quota.maxNumberOfDevices == -1 && quota.maxStorageSize == -1) {
                    deviceRatio = 0
                    dataRatio = 0
                    deviceQuotaText = "∞ Devices"
                    dataQuotaText = "∞ MB"
                } else {
                    deviceRatio = Float(quota.totalDevices)/Float(quota.maxNumberOfDevices)
                    dataRatio = Float(quota.usedStorageSize) / Float(quota.maxStorageSize)
                    deviceQuotaText = "\(quota.totalDevices!)/\(quota.maxNumberOfDevices!) Devices"
                    dataQuotaText = "\(quota.usedStorageSize/(1024*1024))/\(quota.maxStorageSize/(1024*1024)) MB"
                }
                DispatchQueue.main.async {
                    self?.devicesProgressBar.setProgress(deviceRatio, animated: true)
                    self?.deviceQuotaLabel.text = deviceQuotaText
                    self?.dataProgressBar.setProgress(dataRatio, animated: true)
                    self?.dataQuotaLabel.text = dataQuotaText
                }
            }
        }
        completed?()
    }
    
    @objc private func handleRefresh( _ refreshControl: UIRefreshControl) {
        updateQuotaInfomration {
            self.tableView.reloadData()
            refreshControl.endRefreshing()
        }
    }
    
}

extension DeviceTableViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        let latitude = Datanode(name: "Latitude", path: "Location", v: location.coordinate.latitude)
        let longitude = Datanode(name: "Longitude", path: "Location", v: location.coordinate.longitude)
        var speedInKmPerHour: Double {
            return location.speed < Double(0) ? 0 : location.speed*3.6
        }
        let speed = Datanode(name: "Speed", path: "Location", v: speedInKmPerHour, unit: "km/h")
        switch UIApplication.shared.applicationState {
        case .background:
            print("in background")
            print(manager.desiredAccuracy)
            manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        default:
            manager.desiredAccuracy = kCLLocationAccuracyBest
        }
        myIoT.client.writeDatanode(deviceId: myIoT.deviceDetails.deviceId!, datanodes: [latitude, longitude, speed])
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            createAlert(title: "Location unavailable", message: "GPS access is restricted. In order to send location data, please enable GPS in the Settigs app under Privacy, Location Services.")
        default:
            break
        }
    }
}


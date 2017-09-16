//
//  ViewController.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 6/12/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit
import IoTTicketSwiftAPI

class LoginViewController: UIViewController {
    
    @IBOutlet weak var IoTCenterY: NSLayoutConstraint!
    
    @IBOutlet weak var totalDevices: UILabel!
    @IBOutlet weak var IoTLogo: UIImageView!
    @IBOutlet weak var usrpswd: UIStackView!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    var myIoT: MyIoT!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let iotColor = UIColor.init(red: 32/255, green: 140/255, blue: 202/255, alpha: 1)
        
        username.layer.cornerRadius = username.frame.height / 2
        username.layer.borderWidth = 1
        username.layer.borderColor = iotColor.cgColor
        username.textColor = iotColor
        
        password.textColor = iotColor
        password.layer.cornerRadius = password.frame.height / 2
        password.layer.borderWidth = 1
        password.layer.borderColor = iotColor.cgColor
        
        loginButton.layer.cornerRadius = loginButton.frame.height / 2
        self.IoTCenterY.constant = 0
        
        self.loginButton.alpha = 0
        self.username.alpha = 0
        self.password.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 15.0, options: .curveEaseIn, animations: {
            self.IoTCenterY.constant = -160
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        UIView.animate(withDuration: 0.3, delay: 0.5, usingSpringWithDamping: 2.0, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
            self.username.alpha = 1
            self.loginButton.alpha = 1
            self.password.alpha = 1
            
        }, completion: nil)
    }

    func toggleButton(notification: Notification? = nil) {
        loginButton.isEnabled = !loginButton.isEnabled
    }
    
    @IBAction func loginPressed(_ sender: UIButton) {
        loginButton.isEnabled = false
        loginSuccess { deviceDetails in
            self.myIoT.deviceDetails = deviceDetails
            UserDefaults.standard.set(self.username.text, forKey: "username")
            UserDefaults.standard.set(self.password.text, forKey: "password")
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: deviceDetails), forKey: "deviceDetails")
            DispatchQueue.main.async {
               
                self.performSegue(withIdentifier: "toMain", sender: self)
                self.toggleButton()
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tableViewController = segue.destination as? UITabBarController {
            if let navigationController = tableViewController.viewControllers?.first as? UINavigationController {
                if let deviceTableViewController = navigationController.topViewController as? DeviceTableViewController {
                    deviceTableViewController.myIoT = myIoT
                }
            }
        }
    }
    func loginSuccess(completed: @escaping (Device) -> ()) {
        // Check if username is empty
        guard let username = self.username.text, username != "" else {
            toggleButton()
            self.createAlert(title: "Username empty", message: "Enter a username!")
            return
        }
        // Check if password is empty
        guard let password = self.password.text, password != "" else {
            toggleButton()
            self.createAlert(title: "Password empty", message: "Enter your password!")
            return
        }
        // Instantiate IoT-Ticket client
        myIoT.client = IoTTicketClient(baseURL: MyIoT.baseURL, username: username, password: password)
        // Create a device
        let deviceName = UIDevice.current.name.replacingOccurrences(of: "\u{2019}", with: "'")
        let device = Device(name: deviceName, manufacturer: "Apple", type: UIDevice.current.model, deviceDescription: "Device registered with iOS application")
        // Check if device with same specification exists
        myIoT.client.getDevices(limit: 100) { deviceDetailsArray, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.toggleButton()
                    switch error {
                    case IoTServerError.PermissionNotSufficient: self.createAlert(title: "Can't login", message: "Wrong username/password")
                    case IoTServerError.QuotaViolation: self.createAlert(title: "Quota limit", message: "Exceeded max. quota limit")
                    default: self.createAlert(title: "Error", message: "Uknown error")
                    }
                }
            }
            
            if let deviceDetailsArray = deviceDetailsArray {
                if let deviceArray = deviceDetailsArray.devices {
                    for IoTDevice in deviceArray {
                        if (IoTDevice.name == device.name && IoTDevice.manufacturer == device.manufacturer && IoTDevice.type == device.type && IoTDevice.deviceDescription == device.deviceDescription) {
                            completed(IoTDevice)
                            return
                        }
                    }
                    // If a device with same specification doesn't exist, register the device
                    registerDevice()
                } else {
                    // If there are no devices, register the device
                    registerDevice()
                }
            }
            
        }
        
        // Register and return device details.
        func registerDevice() {
            myIoT.client.registerDevice(device: device) { deviceDetails, loginError in
                if let error = loginError {
                    switch error {
                    case IoTServerError.QuotaViolation: self.createAlert(title: "Can't register device", message: "Exceeded max. quota limit")
                    case IoTServerError.UncaughtException: self.createAlert(title: "Error", message: "Uncaught error")
                    default: self.createAlert(title: "Error", message: "Uknown error")
                    }
                }
                if let deviceDetails = deviceDetails {
                    completed(deviceDetails)
                }
            }
        }
    }
    func keyboardWillShow(sender: NSNotification) {
        let viewY = self.view.frame.origin.y
        print(self.view.frame.origin.y)
        if viewY >= 0 {
            if let keyboardFrame: NSValue = sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
                print("here")
                let keyboardRectangle = keyboardFrame.cgRectValue
                self.view.frame.origin.y -= keyboardRectangle.height / 3
            }
        }
    }
    func keyboardWillHide(sender: NSNotification) {
        if let keyboardFrame: NSValue = sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.view.frame.origin.y += keyboardRectangle.height / 3
        }
    }
    
}


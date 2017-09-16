//
//  AppDelegate.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 6/12/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit
import IoTTicketSwiftAPI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if !UserDefaults.standard.bool(forKey: "showedIntro") {
            UserDefaults.standard.set(false, forKey: "showedIntro")
        }
        //SET INITIAL CONTROLLER
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var initialViewController: UIViewController
        let userDefaults = UserDefaults.standard
        var deviceData: Data?
        
        if let data = userDefaults.object(forKey: "deviceDetails") as? Data {
            // if already logged in then redirect to MainViewController
            deviceData = data
            initialViewController = mainStoryboard.instantiateViewController(withIdentifier: "Main") as! UITabBarController
            
        } else {
            //If not logged in then show LoginViewController
            initialViewController = mainStoryboard.instantiateViewController(withIdentifier: "LoginController") as! LoginViewController // 'LoginController' is the storyboard id of LoginViewController
        }
        
        
        if let tabBarController = initialViewController as? UITabBarController {
            let navigationController = tabBarController.viewControllers?.first as! UINavigationController
            let deviceTableViewController = navigationController.viewControllers.first as! DeviceTableViewController
            let username = userDefaults.object(forKey: "username") as! String
            let password = userDefaults.object(forKey: "password") as! String
            let deviceDetails = NSKeyedUnarchiver.unarchiveObject(with: deviceData!) as! Device
            let myIoTClient = IoTTicketClient(baseURL: MyIoT.baseURL, username: username, password: password)
            
            deviceTableViewController.myIoT = MyIoT(client: myIoTClient, deviceDetails: deviceDetails)
        }
        if let loginViewController = initialViewController as? LoginViewController {
            
            loginViewController.myIoT = MyIoT()
        }
        
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


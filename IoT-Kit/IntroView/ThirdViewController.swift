//
//  ThirdViewController.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 9/12/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit

class ThirdViewController: UIViewController {

    @IBOutlet weak var privacyPolicyButton: UIButton!
    @IBOutlet weak var gotItButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        gotItButton.layer.cornerRadius = gotItButton.frame.height / 2
    }
    

    @IBAction func privacyButtonPressed(_ sender: UIButton) {
        let privacyURL = URL(string: "https://www.iot-ticket.com/privacy-policy")!
        UIApplication.shared.open(privacyURL, options: [:], completionHandler: nil)
        UserDefaults.standard.set(true, forKey: "showedIntro")
    }
    @IBAction func gotItButtonPressed(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: "showedIntro")
        dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

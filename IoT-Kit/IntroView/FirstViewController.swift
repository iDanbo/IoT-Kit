//
//  FirstViewController.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 9/12/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    @IBOutlet weak var welcomLabel: UILabel!
    @IBOutlet weak var iotTicketLogo: UIImageView!
    @IBOutlet weak var introImageView: UIImageView!
    @IBOutlet weak var officeSuitLabel: UILabel!
    
     var images: [UIImage] = []
    
    private lazy var animateOnce: () = {
        self.animate()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareForAnimation()
        
    }
    
    deinit {
        print("FirstViewController Deinit")
        images.removeAll()
        introImageView = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(animate), name: NSNotification.Name(rawValue: "animate"), object: nil)
    }
    
    func prepareForAnimation() {
        welcomLabel.alpha = 0
        welcomLabel.frame.origin.y -= 50
        iotTicketLogo.alpha = 0
        iotTicketLogo.frame.origin.y += 100
        officeSuitLabel.alpha = 0
        officeSuitLabel.frame.origin.y += 20
    }
    
    func getUncachedImage (named name : String) -> UIImage?
    {
        if let imgPath = Bundle.main.path(forResource: name, ofType: "png")
        {
            return UIImage(contentsOfFile: imgPath)
        }
        return nil
    }
    /*
     Using the built-in startAnimating() method on UIImageView does not remove images from the array after displaying.
     Adding a timer and manually going through array of images, removing them after they have been displayed decreased
     memory usage from ~700mb to ~30mb
     */
    @objc func animate() {
        for i in 1...121 {
//            images.append(UIImage(named: "intro\(i).png")!)
            images.append(getUncachedImage(named: "intro\(i)")!)
        }
        Timer.scheduledTimer(withTimeInterval: 121/30/121, repeats: true) { (timer) in
            if self.images.count == 1 {
                self.introImageView.image = self.images.first
                timer.invalidate()
            } else {
            self.introImageView.image = self.images[0]
            self.images.remove(at: 0)
            }
            
        }
//        introImageView.animationImages = images
//        introImageView.animationDuration = 121/30
//        introImageView.animationRepeatCount = 1
//        introImageView.image = images.last
//        introImageView.startAnimating()
        
        
        UIView.animate(withDuration: 1.3, delay: 0.3, options: .curveEaseOut, animations: {
            self.welcomLabel.alpha = 1
            self.welcomLabel.frame.origin.y += 50
        }, completion: nil)
        UIView.animate(withDuration: 1.3, delay: 0.5, options: .curveEaseOut, animations: {
            self.iotTicketLogo.alpha = 1
            self.iotTicketLogo.frame.origin.y -= 100
        }, completion: nil)
        UIView.animate(withDuration: 1, delay: 4.0, options: .curveEaseOut, animations: {
            self.officeSuitLabel.alpha = 1
            self.officeSuitLabel.frame.origin.y -= 20
        }, completion: nil)
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

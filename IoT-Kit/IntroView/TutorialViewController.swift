//
//  TutorialViewController.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 9/11/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tutorialPageViewController = segue.destination as? IntroPageViewController {
            tutorialPageViewController.tutorialDelegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isBeingPresented {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "animate"), object: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
}

extension TutorialViewController: TutorialPageViewControllerDelegate {
    func tutorialPageViewController(tutorialPageViewController: IntroPageViewController, didUpdatePageCount count: Int) {
        pageControl.numberOfPages = count
    }
    func tutorialPageViewController(tutorialPageViewController: IntroPageViewController, didUpdatePageIndex index: Int) {
        pageControl.currentPage = index
    }
}
